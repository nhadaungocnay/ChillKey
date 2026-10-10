import Foundation

public enum InputMethod: String, CaseIterable, Codable {
    case telex = "Telex"
    case vni = "VNI"
    case simpleTelex = "Simple Telex"
}

public enum TonePlacementStyle: String, CaseIterable, Codable {
    case modern = "Chuẩn mới (hòa, thúy)"
    case traditional = "Chuẩn cũ (hoà, thuý)"
}

public enum ToneMark: Int, CaseIterable, Codable {
    case none = 0
    case acute = 1   // Sắc
    case grave = 2   // Huyền
    case hook = 3    // Hỏi
    case tilde = 4   // Ngã
    case dot = 5     // Nặng
}

public enum VowelModification: Int, CaseIterable, Codable {
    case none = 0
    case circumflex = 1 // Mũ: â, ê, ô
    case horn = 2       // Móc: ơ, ư
    case breve = 3      // Trăng: ă
}

public struct EngineResult {
    /// Number of backspaces to delete previous characters
    public let backspaceCount: Int
    /// Replacement string to insert
    public let replacement: String
    /// Whether the key stroke was consumed by the Vietnamese engine
    public let consumed: Bool

    public static let passThrough = EngineResult(backspaceCount: 0, replacement: "", consumed: false)

    public init(backspaceCount: Int, replacement: String, consumed: Bool) {
        self.backspaceCount = backspaceCount
        self.replacement = replacement
        self.consumed = consumed
    }
}
