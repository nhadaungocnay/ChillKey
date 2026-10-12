import Foundation
import CoreGraphics
import AppKit

public final class EventTapManager {
    public static let shared = EventTapManager()
    
    public var isEnabled: Bool = true
    public var engine: VietnameseEngine = VietnameseEngine()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    // Callback for hotkey toggle notification
    public var onModeToggled: ((Bool) -> Void)?
    
    private var isControlPressed = false
    private var isShiftPressed = false
    private var lastKeystrokeTime: Date = Date()
    private let idleTimeoutSeconds: TimeInterval = 2.0
    
    private init() {
        setupWorkspaceObservers()
    }
    
    /// Detects whether the active focused text element has selected/highlighted text (e.g. autocomplete suggestions)
    private func hasActiveSelection() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return false }
        let axApp = AXUIElementCreateApplication(frontApp.processIdentifier)
        var focusedElem: AnyObject?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &focusedElem) == .success,
              let elem = focusedElem else { return false }
        let axElem = elem as! AXUIElement
        
        var selectedRangeValue: AnyObject?
        if AXUIElementCopyAttributeValue(axElem, kAXSelectedTextRangeAttribute as CFString, &selectedRangeValue) == .success,
           let val = selectedRangeValue {
            var range = CFRange()
            if AXValueGetValue(val as! AXValue, .cfRange, &range) {
                return range.length > 0
            }
        }
        
        var selectedTextValue: AnyObject?
        if AXUIElementCopyAttributeValue(axElem, kAXSelectedTextAttribute as CFString, &selectedTextValue) == .success,
           let text = selectedTextValue as? String {
            return !text.isEmpty
        }
        
        return false
    }
    
    /// Observe application activation to reset word buffer when switching windows/apps
    private func setupWorkspaceObservers() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.engine.reset()
        }
        
        center.addObserver(
            forName: NSWorkspace.didDeactivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.engine.reset()
        }
    }
    
    /// Starts the global event tap hook.
    public func start() -> Bool {
        guard eventTap == nil else { return true }
        
        // Listen to keyboard AND mouse events (to reset buffer on click)
        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                        (1 << CGEventType.flagsChanged.rawValue) |
                        (1 << CGEventType.leftMouseDown.rawValue) |
                        (1 << CGEventType.rightMouseDown.rawValue) |
                        (1 << CGEventType.otherMouseDown.rawValue)
        
        let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passRetained(event)
                }
                let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: observer
        ) else {
            print("❌ Failed to create CGEventTap. Please ensure Accessibility permission is granted.")
            return false
        }
        
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            print("✅ ChillKey EventTap started successfully.")
            return true
        }
        
        return false
    }
    
    /// Stops the global event tap hook.
    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
            eventTap = nil
            runLoopSource = nil
            print("🛑 ChillKey EventTap stopped.")
        }
    }
    
    public func toggleVietnameseMode() {
        isEnabled.toggle()
        engine.reset()
        onModeToggled?(isEnabled)
    }
    
    // MARK: - Event Handler
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // 1. Recover if tap is disabled by macOS timeout
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }
        
        // 2. Ignore self-generated synthetic events to prevent recursion
        if KeySender.isSelfGenerated(event: event) {
            return Unmanaged.passRetained(event)
        }
        
        // 3. Mouse click anywhere: User moved cursor -> Always reset word buffer
        if type == .leftMouseDown || type == .rightMouseDown || type == .otherMouseDown {
            engine.reset()
            return Unmanaged.passRetained(event)
        }
        
        // 4. Flags changed: Check for HotKey toggle (Control + Shift)
        if type == .flagsChanged {
            let flags = event.flags
            let ctrl = flags.contains(.maskControl)
            let shift = flags.contains(.maskShift)
            
            // Detect when both Control and Shift were pressed
            if ctrl && shift && (!isControlPressed || !isShiftPressed) {
                toggleVietnameseMode()
            }
            isControlPressed = ctrl
            isShiftPressed = shift
            
            return Unmanaged.passRetained(event)
        }
        
        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }
        
        // 5. Inactivity check: If user hasn't typed for > 2 seconds, reset buffer
        let now = Date()
        if now.timeIntervalSince(lastKeystrokeTime) > idleTimeoutSeconds {
            engine.reset()
        }
        lastKeystrokeTime = now
        
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        
        // 6. Keypad (NumPad) -> Always pure numbers, never apply Vietnamese tones, reset buffer
        if KeyCodes.isKeypadKey(keyCode) {
            engine.reset()
            return Unmanaged.passRetained(event)
        }
        
        // 7. Modifiers (Cmd, Ctrl, Option) -> Shortcut key (Cmd+C, Cmd+V, etc.) -> Flush buffer
        if flags.contains(.maskCommand) || flags.contains(.maskControl) || flags.contains(.maskAlternate) {
            engine.reset()
            return Unmanaged.passRetained(event)
        }
        
        // 7. Navigation or Control keys -> Flush buffer
        if KeyCodes.isNavigationKey(keyCode) || keyCode == KeyCodes.kVK_Return ||
           keyCode == KeyCodes.kVK_Tab || keyCode == KeyCodes.kVK_Escape {
            engine.reset()
            return Unmanaged.passRetained(event)
        }
        
        // 8. Backspace key
        if keyCode == KeyCodes.kVK_Delete {
            engine.handleBackspace()
            return Unmanaged.passRetained(event)
        }
        
        // 9. Space key
        if keyCode == KeyCodes.kVK_Space {
            engine.reset()
            return Unmanaged.passRetained(event)
        }
        
        // If Vietnamese mode is disabled, pass through immediately
        guard isEnabled else {
            return Unmanaged.passRetained(event)
        }
        
        // 10. Extract Unicode character from event (with fallback for remote desktop synthetic events)
        var firstChar: Character? = nil
        var length = 0
        event.keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)
        if length > 0 {
            var chars = [UniChar](repeating: 0, count: length)
            event.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: &length, unicodeString: &chars)
            let typedString = String(utf16CodeUnits: chars, count: length)
            if typedString.count == 1 {
                firstChar = typedString.first
            }
        }
        
        // Fallback for synthetic events without Unicode string (e.g. Chrome Remote Desktop Host, VNC)
        if firstChar == nil {
            let isUpper = flags.contains(.maskShift) != flags.contains(.maskAlphaShift)
            firstChar = KeyCodes.character(for: keyCode, isUppercase: isUpper)
        }
        
        guard let charToProcess = firstChar else {
            engine.reset()
            return Unmanaged.passRetained(event)
        }
        
        // 11. Process character in Vietnamese Engine
        let result = engine.processCharacter(charToProcess)
        
        if result.consumed {
            // Check if there is an active text selection (e.g. browser Omnibox autocomplete suggestion)
            if hasActiveSelection() {
                // First backspace clears the highlighted autocomplete suggestion
                KeySender.sendBackspaces(count: 1)
                usleep(2000) // 2ms to allow browser UI thread to collapse selection
            }
            
            // Send backspaces and new character synchronously to guarantee event order
            KeySender.sendReplacement(
                backspaceCount: result.backspaceCount,
                replacement: result.replacement
            )
            // Suppress original key stroke
            return nil
        }
        
        // Key is not transformed: pass through natively with 0ms latency
        return Unmanaged.passRetained(event)
    }
}
