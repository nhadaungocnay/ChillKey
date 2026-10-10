import Foundation

public struct KeyCodes {
    public static let kVK_Return: UInt16 = 0x24
    public static let kVK_Tab: UInt16 = 0x30
    public static let kVK_Space: UInt16 = 0x31
    public static let kVK_Delete: UInt16 = 0x33 // Backspace
    public static let kVK_Escape: UInt16 = 0x35
    public static let kVK_Command: UInt16 = 0x37
    public static let kVK_Shift: UInt16 = 0x38
    public static let kVK_Option: UInt16 = 0x3A
    public static let kVK_Control: UInt16 = 0x3B
    public static let kVK_RightShift: UInt16 = 0x3C
    public static let kVK_RightOption: UInt16 = 0x3D
    public static let kVK_RightControl: UInt16 = 0x3E
    
    // Navigation
    public static let kVK_LeftArrow: UInt16 = 0x7B
    public static let kVK_RightArrow: UInt16 = 0x7C
    public static let kVK_DownArrow: UInt16 = 0x7D
    public static let kVK_UpArrow: UInt16 = 0x7E
    public static let kVK_PageUp: UInt16 = 0x74
    public static let kVK_PageDown: UInt16 = 0x79
    public static let kVK_Home: UInt16 = 0x73
    public static let kVK_End: UInt16 = 0x77
    
    public static func isNavigationKey(_ keyCode: UInt16) -> Bool {
        return keyCode == kVK_LeftArrow || keyCode == kVK_RightArrow ||
               keyCode == kVK_UpArrow || keyCode == kVK_DownArrow ||
               keyCode == kVK_PageUp || keyCode == kVK_PageDown ||
               keyCode == kVK_Home || keyCode == kVK_End
    }
}
