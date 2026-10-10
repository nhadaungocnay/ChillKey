import Foundation
import ApplicationServices
import AppKit

public struct PermissionManager {
    /// Checks whether the app currently has Accessibility permission.
    public static func isAccessibilityTrusted() -> Bool {
        return AXIsProcessTrusted()
    }
    
    /// Requests Accessibility permission and optionally prompts the user with a system dialog.
    @discardableResult
    public static func requestAccessibility(prompt: Bool = true) -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    /// Opens the Accessibility pane in System Settings directly.
    public static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
