import AppKit
import SwiftUI

public final class MenuBarController: NSObject {
    public static let shared = MenuBarController()
    
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    
    override private init() {
        super.init()
    }
    
    public func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItem()
        rebuildMenu()
        
        // Observe mode change
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStateChanged),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    @objc private func handleStateChanged() {
        updateStatusItem()
        rebuildMenu()
    }
    
    public func updateStatusItem() {
        guard let button = statusItem?.button else { return }
        let isVietnamese = AppState.shared.isVietnamese
        
        // Stylish text badge: [V] in blue / bold, or [E] in gray
        let title = isVietnamese ? "🇻🇳 V" : "🇺🇸 E"
        button.title = title
    }
    
    public func rebuildMenu() {
        let menu = NSMenu()
        
        let isVietnamese = AppState.shared.isVietnamese
        let toggleTitle = isVietnamese ? "Chuyển sang Tiếng Anh (E)" : "Chuyển sang Tiếng Việt (V)"
        let toggleItem = NSMenuItem(title: "\(toggleTitle) [Ctrl+Shift]", action: #selector(toggleMode), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Kiểu gõ submenu
        let inputMethodMenu = NSMenu()
        for method in InputMethod.allCases {
            let item = NSMenuItem(title: method.rawValue, action: #selector(changeInputMethod(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = method
            item.state = (AppState.shared.inputMethod == method) ? .on : .off
            inputMethodMenu.addItem(item)
        }
        let inputMethodItem = NSMenuItem(title: "Kiểu gõ: \(AppState.shared.inputMethod.rawValue)", action: nil, keyEquivalent: "")
        inputMethodItem.submenu = inputMethodMenu
        menu.addItem(inputMethodItem)
        
        // Chuẩn đặt dấu submenu
        let toneStyleMenu = NSMenu()
        for style in TonePlacementStyle.allCases {
            let item = NSMenuItem(title: style.rawValue, action: #selector(changeToneStyle(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style
            item.state = (AppState.shared.tonePlacementStyle == style) ? .on : .off
            toneStyleMenu.addItem(item)
        }
        let toneStyleItem = NSMenuItem(title: "Đặt dấu thanh", action: nil, keyEquivalent: "")
        toneStyleItem.submenu = toneStyleMenu
        menu.addItem(toneStyleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Cài đặt...
        let settingsItem = NSMenuItem(title: "Cài đặt...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Thoát
        let quitItem = NSMenuItem(title: "Thoát ChillKey", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func toggleMode() {
        AppState.shared.isVietnamese.toggle()
        updateStatusItem()
        rebuildMenu()
    }
    
    @objc private func changeInputMethod(_ sender: NSMenuItem) {
        if let method = sender.representedObject as? InputMethod {
            AppState.shared.inputMethod = method
            rebuildMenu()
        }
    }
    
    @objc private func changeToneStyle(_ sender: NSMenuItem) {
        if let style = sender.representedObject as? TonePlacementStyle {
            AppState.shared.tonePlacementStyle = style
            rebuildMenu()
        }
    }
    
    @objc public func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let hostingController = NSHostingController(rootView: SettingsView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Cài đặt ChillKey"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()
        window.isReleasedWhenClosed = false
        self.settingsWindow = window
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        EventTapManager.shared.stop()
        NSApp.terminate(nil)
    }
}
