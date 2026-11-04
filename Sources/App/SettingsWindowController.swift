import AppKit

public final class SettingsWindowController: NSObject, NSWindowDelegate {
    public static let shared = SettingsWindowController()
    
    private var window: NSWindow?
    private var methodSegment: NSSegmentedControl!
    private var toneSegment: NSSegmentedControl!
    private var permStatusLabel: NSTextField!
    private var permButton: NSButton!
    
    override private init() {
        super.init()
    }
    
    public func showSettingsWindow() {
        if let window = window {
            updatePermissionStatus()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "Cài đặt ChillKey"
        win.center()
        win.isReleasedWhenClosed = false
        win.delegate = self
        
        let contentView = NSView(frame: win.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]
        
        // 1. Header (Icon + Titles)
        let iconView = NSImageView(frame: NSRect(x: 20, y: 286, width: 48, height: 48))
        if let appIcon = NSImage(named: NSImage.applicationIconName) {
            iconView.image = appIcon
        } else {
            iconView.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "ChillKey")
        }
        contentView.addSubview(iconView)
        
        let titleLabel = NSTextField(labelWithString: "ChillKey")
        titleLabel.frame = NSRect(x: 78, y: 310, width: 300, height: 22)
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        contentView.addSubview(titleLabel)
        
        let subTitleLabel = NSTextField(labelWithString: "Bộ gõ tiếng Việt Native cho macOS Chip M")
        subTitleLabel.frame = NSRect(x: 78, y: 290, width: 340, height: 18)
        subTitleLabel.font = NSFont.systemFont(ofSize: 12)
        subTitleLabel.textColor = .secondaryLabelColor
        contentView.addSubview(subTitleLabel)
        
        // Divider 1
        let div1 = NSBox(frame: NSRect(x: 20, y: 272, width: 400, height: 1))
        div1.boxType = .separator
        contentView.addSubview(div1)
        
        // 2. Kiểu gõ (Input Method)
        let methodTitle = NSTextField(labelWithString: "Kiểu gõ:")
        methodTitle.frame = NSRect(x: 20, y: 236, width: 120, height: 18)
        methodTitle.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        contentView.addSubview(methodTitle)
        
        methodSegment = NSSegmentedControl(labels: ["Telex", "VNI", "Simple Telex"], trackingMode: .selectOne, target: self, action: #selector(methodChanged(_:)))
        methodSegment.frame = NSRect(x: 140, y: 232, width: 280, height: 24)
        switch AppState.shared.inputMethod {
        case .telex: methodSegment.selectedSegment = 0
        case .vni: methodSegment.selectedSegment = 1
        case .simpleTelex: methodSegment.selectedSegment = 2
        }
        contentView.addSubview(methodSegment)
        
        // 3. Đặt dấu thanh (Tone Style)
        let toneTitle = NSTextField(labelWithString: "Đặt dấu thanh:")
        toneTitle.frame = NSRect(x: 20, y: 194, width: 120, height: 18)
        toneTitle.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        contentView.addSubview(toneTitle)
        
        toneSegment = NSSegmentedControl(labels: ["Mới (hòa, thúy)", "Cũ (hoà, thuý)"], trackingMode: .selectOne, target: self, action: #selector(toneChanged(_:)))
        toneSegment.frame = NSRect(x: 140, y: 190, width: 280, height: 24)
        toneSegment.selectedSegment = (AppState.shared.tonePlacementStyle == .modern) ? 0 : 1
        contentView.addSubview(toneSegment)
        
        // 4. Phím tắt
        let hotkeyTitle = NSTextField(labelWithString: "Chuyển Anh/Việt:")
        hotkeyTitle.frame = NSRect(x: 20, y: 152, width: 120, height: 18)
        hotkeyTitle.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        contentView.addSubview(hotkeyTitle)
        
        let hotkeyBadge = NSTextField(labelWithString: "Control + Shift")
        hotkeyBadge.frame = NSRect(x: 140, y: 150, width: 130, height: 22)
        hotkeyBadge.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
        hotkeyBadge.alignment = .center
        hotkeyBadge.wantsLayer = true
        hotkeyBadge.layer?.backgroundColor = NSColor.secondaryLabelColor.withAlphaComponent(0.12).cgColor
        hotkeyBadge.layer?.cornerRadius = 5
        contentView.addSubview(hotkeyBadge)
        
        // Divider 2
        let div2 = NSBox(frame: NSRect(x: 20, y: 132, width: 400, height: 1))
        div2.boxType = .separator
        contentView.addSubview(div2)
        
        // 5. Quyền Accessibility
        let permTitle = NSTextField(labelWithString: "Quyền Accessibility:")
        permTitle.frame = NSRect(x: 20, y: 96, width: 130, height: 18)
        permTitle.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        contentView.addSubview(permTitle)
        
        permStatusLabel = NSTextField(labelWithString: "")
        permStatusLabel.frame = NSRect(x: 160, y: 96, width: 140, height: 18)
        permStatusLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        contentView.addSubview(permStatusLabel)
        
        permButton = NSButton(title: "Cấp quyền", target: self, action: #selector(grantPermClicked))
        permButton.frame = NSRect(x: 315, y: 91, width: 105, height: 26)
        permButton.bezelStyle = .rounded
        contentView.addSubview(permButton)
        
        // Divider 3
        let div3 = NSBox(frame: NSRect(x: 20, y: 68, width: 400, height: 1))
        div3.boxType = .separator
        contentView.addSubview(div3)
        
        // 6. Footer (Version & Close button)
        let footerLabel = NSTextField(labelWithString: "ChillKey v1.0 • Siêu nhẹ cho Apple Silicon")
        footerLabel.frame = NSRect(x: 20, y: 22, width: 280, height: 18)
        footerLabel.font = NSFont.systemFont(ofSize: 11)
        footerLabel.textColor = .secondaryLabelColor
        contentView.addSubview(footerLabel)
        
        let closeBtn = NSButton(title: "Đóng", target: self, action: #selector(closeClicked))
        closeBtn.frame = NSRect(x: 335, y: 16, width: 85, height: 30)
        closeBtn.bezelStyle = .rounded
        closeBtn.keyEquivalent = "\r"
        contentView.addSubview(closeBtn)
        
        win.contentView = contentView
        self.window = win
        
        updatePermissionStatus()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func updatePermissionStatus() {
        let trusted = PermissionManager.isAccessibilityTrusted()
        AppState.shared.hasAccessibilityPermission = trusted
        if trusted {
            permStatusLabel.stringValue = "✓ Đã cấp quyền"
            permStatusLabel.textColor = .systemGreen
            permButton.isHidden = true
        } else {
            permStatusLabel.stringValue = "⚠️ Chưa cấp quyền"
            permStatusLabel.textColor = .systemOrange
            permButton.isHidden = false
        }
    }
    
    @objc private func methodChanged(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0: AppState.shared.inputMethod = .telex
        case 1: AppState.shared.inputMethod = .vni
        case 2: AppState.shared.inputMethod = .simpleTelex
        default: break
        }
    }
    
    @objc private func toneChanged(_ sender: NSSegmentedControl) {
        AppState.shared.tonePlacementStyle = (sender.selectedSegment == 0) ? .modern : .traditional
    }
    
    @objc private func grantPermClicked() {
        PermissionManager.openAccessibilitySettings()
        PermissionManager.startAutoRelaunchOnPermissionGranted()
    }
    
    @objc private func closeClicked() {
        window?.close()
    }
    
    public func windowWillClose(_ notification: Notification) {
        // Destroy window to completely free graphics surfaces and caches
        window = nil
    }
}
