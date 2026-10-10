import Foundation

public final class VietnameseEngine {
    public var inputMethod: InputMethod = .telex
    public var tonePlacementStyle: TonePlacementStyle = .modern
    public var autoRestoreEnglishWords: Bool = true
    
    // Internal word state tracking
    private(set) public var currentRaw: String = ""
    private(set) public var currentDisplay: String = ""
    
    public init(
        inputMethod: InputMethod = .telex,
        tonePlacementStyle: TonePlacementStyle = .modern,
        autoRestoreEnglishWords: Bool = true
    ) {
        self.inputMethod = inputMethod
        self.tonePlacementStyle = tonePlacementStyle
        self.autoRestoreEnglishWords = autoRestoreEnglishWords
    }
    
    /// Reset the current word buffer (e.g., when pressing Space, Enter, Escape, clicking mouse).
    public func reset() {
        currentRaw = ""
        currentDisplay = ""
    }
    
    /// Called when user presses Backspace key.
    public func handleBackspace() {
        if !currentDisplay.isEmpty {
            currentDisplay.removeLast()
        }
        if !currentRaw.isEmpty {
            currentRaw.removeLast()
        }
    }
    
    /// Main entry point: Processes a new character typed by the user.
    public func processCharacter(_ char: Character) -> EngineResult {
        // If delimiter or non-letter (space, punctuation, number if telex), flush buffer
        if isWordDelimiter(char) {
            reset()
            return .passThrough
        }
        
        let oldDisplay = currentDisplay
        let newRaw = currentRaw + String(char)
        
        // Try parsing the new word with Vietnamese rules
        let newDisplay = transformWord(rawWord: newRaw)
        
        if newDisplay == oldDisplay + String(char) {
            // Nothing changed other than appending the character naturally
            currentRaw = newRaw
            currentDisplay = newDisplay
            return .passThrough
        }
        
        // Word was modified (transformation happened)
        currentRaw = newRaw
        currentDisplay = newDisplay
        
        // Compute common prefix to find minimal backspaces and replacement string
        let (backspaces, replacement) = calculateDiff(from: oldDisplay, to: newDisplay)
        return EngineResult(backspaceCount: backspaces, replacement: replacement, consumed: true)
    }
    
    private func isWordDelimiter(_ char: Character) -> Bool {
        if char.isWhitespace || char.isPunctuation || char.isSymbol {
            return true
        }
        // In Telex, numbers break words (except when part of specific shortcuts)
        if inputMethod == .telex && char.isNumber {
            return true
        }
        return false
    }
    
    /// Compute minimal backspaces and replacement between old and new strings.
    private func calculateDiff(from oldStr: String, to newStr: String) -> (backspaces: Int, replacement: String) {
        let oldArray = Array(oldStr)
        let newArray = Array(newStr)
        
        var commonPrefixCount = 0
        let minLen = min(oldArray.count, newArray.count)
        
        while commonPrefixCount < minLen && oldArray[commonPrefixCount] == newArray[commonPrefixCount] {
            commonPrefixCount += 1
        }
        
        let backspaces = oldArray.count - commonPrefixCount
        let replacement = String(newArray[commonPrefixCount...])
        return (backspaces, replacement)
    }
    
    // MARK: - Word Transformation
    
    private func transformWord(rawWord: String) -> String {
        switch inputMethod {
        case .telex, .simpleTelex:
            return transformTelex(rawWord: rawWord)
        case .vni:
            return transformVNI(rawWord: rawWord)
        }
    }
    
    // MARK: - Telex Logic
    
    private func transformTelex(rawWord: String) -> String {
        var letters = [Character]()
        var currentTone: ToneMark = .none
        
        for char in rawWord {
            let lower = Character(String(char).lowercased())
            
            // Check tone key in Telex: s, f, r, x, j, z
            if isTelexToneKey(lower) {
                let tone = telexTone(from: lower)
                if lower == "z" {
                    // Remove tone
                    currentTone = .none
                    continue
                } else if currentTone == tone {
                    // Undo tone: pressing 's' again when tone is already acute -> remove tone and append literal 's'
                    currentTone = .none
                    letters.append(char)
                    continue
                } else if tone != .none {
                    currentTone = tone
                    continue
                }
            }
            
            // Check 'dd' -> 'đ'
            if lower == "d" && !letters.isEmpty && (letters.last == "d" || letters.last == "D") {
                let lastWasUpper = letters.last!.isUppercase
                letters.removeLast()
                letters.append(lastWasUpper ? "Đ" : "đ")
                continue
            }
            // Undo 'đ' + d -> 'dd'
            if lower == "d" && !letters.isEmpty && (letters.last == "đ" || letters.last == "Đ") {
                let lastWasUpper = letters.last!.isUppercase
                letters.removeLast()
                letters.append(lastWasUpper ? "D" : "d")
                letters.append(char)
                continue
            }
            
            // Check double horn: uo + w -> ươ (MUST check before single vowel + w)
            if lower == "w" && letters.count >= 2 {
                let lastIdx = letters.count - 1
                let secondLastIdx = letters.count - 2
                let lastChar = letters[lastIdx]
                let secondLastChar = letters[secondLastIdx]
                let lastLower = Character(String(lastChar).lowercased())
                let secondLastLower = Character(String(secondLastChar).lowercased())
                
                if secondLastLower == "u" && lastLower == "o" {
                    letters.removeLast()
                    letters.removeLast()
                    letters.append(secondLastChar.isUppercase ? "Ư" : "ư")
                    letters.append(lastChar.isUppercase ? "Ơ" : "ơ")
                    continue
                }
            }
            
            // Check vowel transformations: aa -> â, ee -> ê, oo -> ô, aw -> ă, ow -> ơ, uw -> ư
            if let transformed = tryTransformVowel(letters: &letters, incoming: char) {
                letters.append(transformed)
                continue
            }
            
            // Normal letter
            letters.append(char)
        }
        
        var word = String(letters)
        
        // Apply tone mark if present
        if currentTone != .none {
            word = applyTone(to: word, tone: currentTone)
        }
        
        return word
    }
    
    private func isTelexToneKey(_ char: Character) -> Bool {
        return char == "s" || char == "f" || char == "r" || char == "x" || char == "j" || char == "z"
    }
    
    private func telexTone(from char: Character) -> ToneMark {
        switch char {
        case "s": return .acute
        case "f": return .grave
        case "r": return .hook
        case "x": return .tilde
        case "j": return .dot
        default: return .none
        }
    }
    
    // MARK: - Vowel modification (Telex)
    
    private func tryTransformVowel(letters: inout [Character], incoming: Character) -> Character? {
        guard let lastChar = letters.last else {
            // Typing 'w' at beginning
            if incoming == "w" { return "ư" }
            if incoming == "W" { return "Ư" }
            return nil
        }
        
        let lastLower = Character(String(lastChar).lowercased())
        let inLower = Character(String(incoming).lowercased())
        let isUpper = incoming.isUppercase || lastChar.isUppercase
        
        // 1. Circumflex: aa -> â, ee -> ê, oo -> ô
        if lastLower == "a" && inLower == "a" {
            letters.removeLast()
            return isUpper ? "Â" : "â"
        }
        if lastLower == "e" && inLower == "e" {
            letters.removeLast()
            return isUpper ? "Ê" : "ê"
        }
        if lastLower == "o" && inLower == "o" {
            letters.removeLast()
            return isUpper ? "Ô" : "ô"
        }
        
        // Undo circumflex: â + a -> aa, ê + e -> ee, ô + o -> oo
        if lastLower == "â" && inLower == "a" {
            letters.removeLast()
            letters.append(lastChar.isUppercase ? "A" : "a")
            return incoming
        }
        if lastLower == "ê" && inLower == "e" {
            letters.removeLast()
            letters.append(lastChar.isUppercase ? "E" : "e")
            return incoming
        }
        if lastLower == "ô" && inLower == "o" {
            letters.removeLast()
            letters.append(lastChar.isUppercase ? "O" : "o")
            return incoming
        }
        
        // 2. Breve & Horn with 'w': aw -> ă, ow -> ơ, uw -> ư
        if lastLower == "a" && inLower == "w" {
            letters.removeLast()
            return isUpper ? "Ă" : "ă"
        }
        if lastLower == "o" && inLower == "w" {
            letters.removeLast()
            return isUpper ? "Ơ" : "ơ"
        }
        if lastLower == "u" && inLower == "w" {
            letters.removeLast()
            return isUpper ? "Ư" : "ư"
        }
        
        // Undo with 'w': ă + w -> aw, ơ + w -> ow, ư + w -> uw
        if lastLower == "ă" && inLower == "w" {
            letters.removeLast()
            letters.append(lastChar.isUppercase ? "A" : "a")
            return incoming
        }
        if lastLower == "ơ" && inLower == "w" {
            letters.removeLast()
            letters.append(lastChar.isUppercase ? "O" : "o")
            return incoming
        }
        if lastLower == "ư" && inLower == "w" {
            letters.removeLast()
            letters.append(lastChar.isUppercase ? "U" : "u")
            return incoming
        }
        
        return nil
    }
    
    // MARK: - VNI Logic
    
    private func transformVNI(rawWord: String) -> String {
        var letters = [Character]()
        var currentTone: ToneMark = .none
        
        for char in rawWord {
            if char.isNumber {
                var handled = false
                switch char {
                case "1": currentTone = .acute; handled = true
                case "2": currentTone = .grave; handled = true
                case "3": currentTone = .hook; handled = true
                case "4": currentTone = .tilde; handled = true
                case "5": currentTone = .dot; handled = true
                case "0": currentTone = .none; handled = true
                case "6": // Â, Ê, Ô (can modify earlier vowels in word, e.g. viet6 -> viêt)
                    for i in stride(from: letters.count - 1, through: 0, by: -1) {
                        let l = Character(String(letters[i]).lowercased())
                        let u = letters[i].isUppercase
                        if l == "a" { letters[i] = u ? "Â" : "â"; handled = true; break }
                        if l == "e" { letters[i] = u ? "Ê" : "ê"; handled = true; break }
                        if l == "o" { letters[i] = u ? "Ô" : "ô"; handled = true; break }
                    }
                case "7": // Ơ, Ư
                    for i in stride(from: letters.count - 1, through: 0, by: -1) {
                        let l = Character(String(letters[i]).lowercased())
                        let u = letters[i].isUppercase
                        if l == "o" { letters[i] = u ? "Ơ" : "ơ"; handled = true; break }
                        if l == "u" { letters[i] = u ? "Ư" : "ư"; handled = true; break }
                    }
                case "8": // Ă
                    for i in stride(from: letters.count - 1, through: 0, by: -1) {
                        let l = Character(String(letters[i]).lowercased())
                        let u = letters[i].isUppercase
                        if l == "a" { letters[i] = u ? "Ă" : "ă"; handled = true; break }
                    }
                case "9": // Đ
                    for i in stride(from: letters.count - 1, through: 0, by: -1) {
                        let l = Character(String(letters[i]).lowercased())
                        let u = letters[i].isUppercase
                        if l == "d" { letters[i] = u ? "Đ" : "đ"; handled = true; break }
                    }
                default: break
                }
                
                if handled {
                    continue
                }
            }
            letters.append(char)
        }
        
        var word = String(letters)
        if currentTone != .none {
            word = applyTone(to: word, tone: currentTone)
        }
        return word
    }
    
    // MARK: - Apply Tone
    
    private func applyTone(to word: String, tone: ToneMark) -> String {
        // Find all vowel indices in word
        var vowelIndices = [String.Index]()
        var hasFinalConsonant = false
        
        var idx = word.startIndex
        while idx < word.endIndex {
            let ch = word[idx]
            if Alphabet.isVowel(ch) {
                vowelIndices.append(idx)
            } else if !vowelIndices.isEmpty {
                // Consonant after vowels
                hasFinalConsonant = true
            }
            idx = word.index(after: idx)
        }
        
        guard let targetIndex = ToneRules.findToneTargetIndex(
            vowelIndices: vowelIndices,
            in: word,
            hasFinalConsonant: hasFinalConsonant,
            style: tonePlacementStyle
        ) else {
            return word
        }
        
        // Replace target vowel with toned vowel
        let targetChar = word[targetIndex]
        guard let info = Alphabet.getVowelInfo(targetChar) else { return word }
        guard let tonedChar = Alphabet.makeVowel(base: info.base, mod: info.modification, tone: tone, isUppercase: info.isUppercase) else {
            return word
        }
        
        var result = word
        result.replaceSubrange(targetIndex...targetIndex, with: String(tonedChar))
        return result
    }
}
