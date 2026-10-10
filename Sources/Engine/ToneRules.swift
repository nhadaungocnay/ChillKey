import Foundation

public struct ToneRules {
    /// Determines the index of the vowel that should receive the tone mark.
    /// - Parameters:
    ///   - vowelIndices: Array of indices in the original word representing vowels.
    ///   - word: The full word string.
    ///   - hasFinalConsonant: Whether there is a final consonant after the vowel cluster.
    ///   - style: Modern or Traditional tone placement style.
    /// - Returns: The index in `word` that should receive the tone mark, or nil if no vowels.
    public static func findToneTargetIndex(
        vowelIndices: [String.Index],
        in word: String,
        hasFinalConsonant: Bool,
        style: TonePlacementStyle
    ) -> String.Index? {
        guard !vowelIndices.isEmpty else { return nil }
        
        // 1 vowel: tone always on it
        if vowelIndices.count == 1 {
            return vowelIndices[0]
        }
        
        // 3 or more vowels:
        if vowelIndices.count >= 3 {
            // Check for "uyê" diphthong: in "khuyên", "chuyện", "duyệt", tone is on 'ê' (the 3rd vowel)
            let v1 = Character(String(word[vowelIndices[0]]).lowercased())
            let v2 = Character(String(word[vowelIndices[1]]).lowercased())
            let v3 = Character(String(word[vowelIndices[2]]).lowercased())
            if v1 == "u" && v2 == "y" && (v3 == "ê" || v3 == "e") {
                return vowelIndices[2]
            }
            // For other triphthongs (iêu, oai, uôi, ươi, ươu, etc.), tone on the middle (second) vowel
            return vowelIndices[1]
        }
        
        // 2 vowels:
        let firstVowelChar = Character(String(word[vowelIndices[0]]).lowercased())
        let secondVowelChar = Character(String(word[vowelIndices[1]]).lowercased())
        let pair = "\(firstVowelChar)\(secondVowelChar)"
        
        // If there's a final consonant, tone almost always goes to the 2nd vowel
        // e.g. "toán", "tiến", "hoàn", "thuyết", "quần", "buồn", "mường"
        if hasFinalConsonant {
            return vowelIndices[1]
        }
        
        // No final consonant:
        switch pair {
        case "ia", "ya", "ua", "ưa":
            // "mía", "múa", "cửa" -> first vowel
            return vowelIndices[0]
            
        case "oa", "oe", "uy":
            // Modern: "hòa", "hòe", "thúy" -> first vowel (on 'o'/'u')
            // Traditional: "hoà", "hoè", "thuý" -> second vowel (on 'a'/'e'/'y')
            return style == .modern ? vowelIndices[0] : vowelIndices[1]
            
        case "ai", "ao", "au", "ay", "âu", "ây", "eo", "êu", "oi", "ôi", "ơi", "ui", "ưi", "ưu":
            // Semi-vowel ending: tone on the first vowel
            // "mái", "báo", "sáu", "mấy", "mèo", "nếu", "tối", "gửi", "cứu"
            return vowelIndices[0]
            
        default:
            // Default: tone on second vowel
            return vowelIndices[1]
        }
    }
}
