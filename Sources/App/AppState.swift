import Foundation
import Combine

public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var isVietnamese: Bool {
        didSet {
            UserDefaults.standard.set(isVietnamese, forKey: "isVietnamese")
            EventTapManager.shared.isEnabled = isVietnamese
        }
    }
    
    @Published public var inputMethod: InputMethod {
        didSet {
            UserDefaults.standard.set(inputMethod.rawValue, forKey: "inputMethod")
            EventTapManager.shared.engine.inputMethod = inputMethod
        }
    }
    
    @Published public var tonePlacementStyle: TonePlacementStyle {
        didSet {
            UserDefaults.standard.set(tonePlacementStyle.rawValue, forKey: "tonePlacementStyle")
            EventTapManager.shared.engine.tonePlacementStyle = tonePlacementStyle
        }
    }
    
    @Published public var hasAccessibilityPermission: Bool = false
    
    private init() {
        self.isVietnamese = UserDefaults.standard.object(forKey: "isVietnamese") as? Bool ?? true
        
        if let savedMethod = UserDefaults.standard.string(forKey: "inputMethod"),
           let method = InputMethod(rawValue: savedMethod) {
            self.inputMethod = method
        } else {
            self.inputMethod = .telex
        }
        
        if let savedStyle = UserDefaults.standard.string(forKey: "tonePlacementStyle"),
           let style = TonePlacementStyle(rawValue: savedStyle) {
            self.tonePlacementStyle = style
        } else {
            self.tonePlacementStyle = .modern
        }
        
        self.hasAccessibilityPermission = PermissionManager.isAccessibilityTrusted()
        
        // Sync with EventTapManager
        EventTapManager.shared.isEnabled = self.isVietnamese
        EventTapManager.shared.engine.inputMethod = self.inputMethod
        EventTapManager.shared.engine.tonePlacementStyle = self.tonePlacementStyle
        
        EventTapManager.shared.onModeToggled = { [weak self] enabled in
            DispatchQueue.main.async {
                self?.isVietnamese = enabled
            }
        }
    }
    
    public func checkPermission() {
        hasAccessibilityPermission = PermissionManager.isAccessibilityTrusted()
    }
}
