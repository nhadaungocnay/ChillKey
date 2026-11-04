import Foundation
import ApplicationServices
import AppKit

public final class PermissionManager {
    private static var permissionTimer: Timer?
    
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
    
    /// Starts polling for Accessibility permission. As soon as user grants permission,
    /// automatically restarts the application so the new CGEventTap permissions take effect seamlessly.
    public static func startAutoRelaunchOnPermissionGranted() {
        guard !isAccessibilityTrusted() else { return }
        
        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            if isAccessibilityTrusted() {
                timer.invalidate()
                permissionTimer = nil
                NSLog("[ChillKey] Accessibility permission granted! Relaunching app...")
                relaunch()
            }
        }
    }
    
    /// Gracefully terminates and relaunches the current app bundle.
    public static func relaunch() {
        let bundleURL = Bundle.main.bundleURL
        let pid = ProcessInfo.processInfo.processIdentifier
        
        // Spawn a background shell task that waits for the current process to exit, then re-opens the app
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [
            "-c",
            "while kill -0 \(pid) 2>/dev/null; do sleep 0.1; done; open \"\(bundleURL.path)\""
        ]
        
        try? process.run()
        
        // Clean up EventTap before terminating
        EventTapManager.shared.stop()
        NSApp.terminate(nil)
    }
}
