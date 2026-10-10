import Foundation

public struct Alphabet {
    // Base vowels: (char -> (base, modification, tone))
    // Example: 'ấ' -> base: 'a', mod: .circumflex, tone: .acute

    // Table mapping (base: Character, mod: VowelModification, tone: ToneMark) -> Character
    private static let vowelTable: [Character: [VowelModification: [ToneMark: Character]]] = [
        "a": [
            .none: [.none: "a", .acute: "á", .grave: "à", .hook: "ả", .tilde: "ã", .dot: "ạ"],
            .circumflex: [.none: "â", .acute: "ấ", .grave: "ầ", .hook: "ẩ", .tilde: "ẫ", .dot: "ậ"],
            .breve: [.none: "ă", .acute: "ắ", .grave: "ằ", .hook: "ẳ", .tilde: "ẵ", .dot: "ặ"]
        ],
        "e": [
            .none: [.none: "e", .acute: "é", .grave: "è", .hook: "ẻ", .tilde: "ẽ", .dot: "ẹ"],
            .circumflex: [.none: "ê", .acute: "ế", .grave: "ề", .hook: "ể", .tilde: "ễ", .dot: "ệ"]
        ],
        "i": [
            .none: [.none: "i", .acute: "í", .grave: "ì", .hook: "ỉ", .tilde: "ĩ", .dot: "ị"]
        ],
        "o": [
            .none: [.none: "o", .acute: "ó", .grave: "ò", .hook: "ỏ", .tilde: "õ", .dot: "ọ"],
            .circumflex: [.none: "ô", .acute: "ố", .grave: "ồ", .hook: "ổ", .tilde: "ỗ", .dot: "ộ"],
            .horn: [.none: "ơ", .acute: "ớ", .grave: "ờ", .hook: "ở", .tilde: "ỡ", .dot: "ợ"]
        ],
        "u": [
            .none: [.none: "u", .acute: "ú", .grave: "ù", .hook: "ủ", .tilde: "ũ", .dot: "ụ"],
            .horn: [.none: "ư", .acute: "ứ", .grave: "ừ", .hook: "ử", .tilde: "ữ", .dot: "ự"]
        ],
        "y": [
            .none: [.none: "y", .acute: "ý", .grave: "ỳ", .hook: "ỷ", .tilde: "ỹ", .dot: "ỵ"]
        ]
    ]

    // Reverse lookup: Given any character (e.g., 'ấ'), find (base: 'a', mod: .circumflex, tone: .acute, isUpper: false)
    public struct VowelInfo {
        public let base: Character
        public let modification: VowelModification
        public let tone: ToneMark
        public let isUppercase: Bool
    }

    private static let reverseVowelMap: [Character: VowelInfo] = {
        var map = [Character: VowelInfo]()
        for (base, mods) in vowelTable {
            for (mod, tones) in mods {
                for (tone, char) in tones {
                    map[char] = VowelInfo(base: base, modification: mod, tone: tone, isUppercase: false)
                    // Uppercase
                    let upper = Character(String(char).uppercased())
                    let baseUpper = Character(String(base).uppercased())
                    map[upper] = VowelInfo(base: baseUpper, modification: mod, tone: tone, isUppercase: true)
                }
            }
        }
        return map
    }()

    public static func getVowelInfo(_ char: Character) -> VowelInfo? {
        return reverseVowelMap[char]
    }

    public static func makeVowel(base: Character, mod: VowelModification, tone: ToneMark, isUppercase: Bool = false) -> Character? {
        let lowerBase = Character(String(base).lowercased())
        guard let mods = vowelTable[lowerBase],
              let tones = mods[mod],
              let char = tones[tone] else {
            return nil
        }
        return isUppercase ? Character(String(char).uppercased()) : char
    }

    public static func isVowel(_ char: Character) -> Bool {
        return reverseVowelMap[char] != nil
    }

    public static func isDMark(_ char: Character) -> Bool {
        return char == "đ" || char == "Đ"
    }

    public static func isDOrDMark(_ char: Character) -> Bool {
        return char == "d" || char == "D" || char == "đ" || char == "Đ"
    }
}
