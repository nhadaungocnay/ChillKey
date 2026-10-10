import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as menu bar accessory (no Dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Setup MenuBar icon and menus
        MenuBarController.shared.setup()
        
        // Check and prompt Accessibility permission if needed
        let trusted = PermissionManager.isAccessibilityTrusted()
        if !trusted {
            PermissionManager.requestAccessibility(prompt: true)
            // Open settings window to let user see status
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                MenuBarController.shared.openSettings()
            }
        }
        
        // Start Event Tap
        _ = EventTapManager.shared.start()
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        EventTapManager.shared.stop()
    }
}
