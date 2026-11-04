import Foundation
import CoreGraphics

public struct KeySender {
    public static let chillKeyMagicUserData: Int64 = 0x4368696C6C4B6579 // "ChillKey" in ASCII
    
    private static let eventSource = CGEventSource(stateID: .combinedSessionState)
    
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
                
                keyDown.post(tap: .cgSessionEventTap)
                keyUp.post(tap: .cgSessionEventTap)
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
            
            keyDown.post(tap: .cgSessionEventTap)
            keyUp.post(tap: .cgSessionEventTap)
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
