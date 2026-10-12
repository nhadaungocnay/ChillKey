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
    
    // Numeric Keypad (NumPad) keycodes
    public static let keypadKeyCodes: Set<UInt16> = [
        0x52, // Keypad 0
        0x53, // Keypad 1
        0x54, // Keypad 2
        0x55, // Keypad 3
        0x56, // Keypad 4
        0x57, // Keypad 5
        0x58, // Keypad 6
        0x59, // Keypad 7
        0x5B, // Keypad 8
        0x5C, // Keypad 9
        0x41, // Keypad Decimal .
        0x43, // Keypad Multiply *
        0x45, // Keypad Plus +
        0x47, // Keypad Clear
        0x4B, // Keypad Divide /
        0x4C, // Keypad Enter
        0x4E, // Keypad Minus -
        0x51  // Keypad Equals =
    ]
    
    public static func isNavigationKey(_ keyCode: UInt16) -> Bool {
        return keyCode == kVK_LeftArrow || keyCode == kVK_RightArrow ||
               keyCode == kVK_UpArrow || keyCode == kVK_DownArrow ||
               keyCode == kVK_PageUp || keyCode == kVK_PageDown ||
               keyCode == kVK_Home || keyCode == kVK_End
    }
    
    public static func isKeypadKey(_ keyCode: UInt16) -> Bool {
        return keypadKeyCodes.contains(keyCode)
    }
    
    // Fallback key code to character mapping for synthetic events (e.g. Chrome Remote Desktop, VNC)
    private static let ansiMap: [UInt16: (lower: Character, upper: Character)] = [
        0x00: ("a", "A"), 0x01: ("s", "S"), 0x02: ("d", "D"), 0x03: ("f", "F"),
        0x04: ("h", "H"), 0x05: ("g", "G"), 0x06: ("z", "Z"), 0x07: ("x", "X"),
        0x08: ("c", "C"), 0x09: ("v", "V"), 0x0B: ("b", "B"), 0x0C: ("q", "Q"),
        0x0D: ("w", "W"), 0x0E: ("e", "E"), 0x0F: ("r", "R"), 0x10: ("y", "Y"),
        0x11: ("t", "T"), 0x1F: ("o", "O"), 0x20: ("u", "U"), 0x22: ("i", "I"),
        0x23: ("p", "P"), 0x25: ("l", "L"), 0x26: ("j", "J"), 0x28: ("k", "K"),
        0x2D: ("n", "N"), 0x2E: ("m", "M"),
        // Number row
        0x12: ("1", "!"), 0x13: ("2", "@"), 0x14: ("3", "#"), 0x15: ("4", "$"),
        0x17: ("5", "%"), 0x16: ("6", "^"), 0x1A: ("7", "&"), 0x1C: ("8", "*"),
        0x19: ("9", "("), 0x1D: ("0", ")")
    ]
    
    public static func character(for keyCode: UInt16, isUppercase: Bool) -> Character? {
        guard let pair = ansiMap[keyCode] else { return nil }
        return isUppercase ? pair.upper : pair.lower
    }
}
