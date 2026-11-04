import Foundation
import CoreGraphics
import AppKit

// Private C function from CoreGraphics to post events directly to target process PID
private typealias CGEventPostToPidFunction = @convention(c) (pid_t, CGEvent) -> Void

private let postToPidFunc: CGEventPostToPidFunction? = {
    let rtl = dlopen(nil, RTLD_LAZY)
    if let sym = dlsym(rtl, "CGEventPostToPid") {
        return unsafeBitCast(sym, to: CGEventPostToPidFunction.self)
    }
    return nil
}()

public struct KeySender {
    public static let chillKeyMagicUserData: Int64 = 0x4368696C6C4B6579 // "ChillKey" in ASCII
    
    private static let eventSource = CGEventSource(stateID: .combinedSessionState)
    
    /// Dispatches an event directly to the frontmost application process ID when available,
    /// or falls back to posting on the global session event tap.
    ///
    /// By delivering synthetic events (backspaces & replacement characters) directly
    /// to the frontmost app's event queue via `CGEventPostToPid`:
    /// 1. Chrome Remote Desktop's global session tap (`LocalKeyboardInputMonitor`) never sees
    ///    these events, completely eliminating the 2.0s lockout freeze even when the user
    ///    disconnects and reconnects their remote session multiple times!
    /// 2. Event delivery latency is near 0ms since it routes directly to the active application.
    private static func postEvent(_ event: CGEvent) {
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           frontApp.processIdentifier > 0,
           let postToPid = postToPidFunc {
            postToPid(frontApp.processIdentifier, event)
        } else {
            event.post(tap: .cgSessionEventTap)
        }
    }
    
    /// Sends a given number of simulated backspace keystrokes synchronously.
    public static func sendBackspaces(count: Int) {
        guard count > 0 else { return }
        let crdPid = RemoteDesktopDetector.getChromeRemoteDesktopHostPid()
        
        for _ in 0..<count {
            if let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: KeyCodes.kVK_Delete, keyDown: true),
               let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: KeyCodes.kVK_Delete, keyDown: false) {
                
                keyDown.flags = []
                keyUp.flags = []
                keyDown.setIntegerValueField(.eventSourceUserData, value: chillKeyMagicUserData)
                keyUp.setIntegerValueField(.eventSourceUserData, value: chillKeyMagicUserData)
                
                if crdPid > 0 {
                    keyDown.setIntegerValueField(.eventSourceUnixProcessID, value: Int64(crdPid))
                    keyUp.setIntegerValueField(.eventSourceUnixProcessID, value: Int64(crdPid))
                }
                
                postEvent(keyDown)
                postEvent(keyUp)
            }
        }
    }
    
    /// Sends a Unicode string into the active application synchronously.
    public static func sendString(_ text: String) {
        guard !text.isEmpty else { return }
        let crdPid = RemoteDesktopDetector.getChromeRemoteDesktopHostPid()
        
        var utf16Chars = Array(text.utf16)
        
        if let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: true),
           let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: false) {
            
            keyDown.flags = []
            keyUp.flags = []
            keyDown.setIntegerValueField(.eventSourceUserData, value: chillKeyMagicUserData)
            keyUp.setIntegerValueField(.eventSourceUserData, value: chillKeyMagicUserData)
            
            if crdPid > 0 {
                keyDown.setIntegerValueField(.eventSourceUnixProcessID, value: Int64(crdPid))
                keyUp.setIntegerValueField(.eventSourceUnixProcessID, value: Int64(crdPid))
            }
            
            keyDown.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: &utf16Chars)
            keyUp.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: &utf16Chars)
            
            postEvent(keyDown)
            postEvent(keyUp)
        }
    }
    
    /// Replaces the previous characters with new text synchronously without race condition.
    public static func sendReplacement(backspaceCount: Int, replacement: String) {
        if backspaceCount > 0 {
            sendBackspaces(count: backspaceCount)
        }
        if !replacement.isEmpty {
            sendString(replacement)
        }
    }
    
    /// Checks whether an event was emitted by ChillKey itself.
    public static func isSelfGenerated(event: CGEvent) -> Bool {
        return event.getIntegerValueField(.eventSourceUserData) == chillKeyMagicUserData
    }
}
