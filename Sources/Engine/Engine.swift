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
        guard !currentDisplay.isEmpty else {
            reset()
            return
        }
        
        currentDisplay.removeLast()
        if currentDisplay.isEmpty {
            reset()
        } else {
            currentRaw = reconstructRaw(from: currentDisplay)
        }
    }
    
    /// Reconstructs the raw keystroke sequence from the currently displayed string.
    /// This ensures that after Backspace, the engine's internal raw state matches exactly
    /// what the user sees on screen, preventing deleted characters from resurrecting.
    public func reconstructRaw(from display: String) -> String {
        guard !display.isEmpty else { return "" }
        
        switch inputMethod {
        case .vni:
            return reconstructRawVNI(from: display)
        case .telex, .simpleTelex:
            return reconstructRawTelex(from: display)
        }
    }
    
    private func reconstructRawVNI(from display: String) -> String {
        var baseChars = [Character]()
        var vowelMods = [Character]() // 6, 7, 8
        var toneChar: Character? = nil // 1, 2, 3, 4, 5
        let hasUoHornPair = hasUoHornDiphthong(in: display)
        
        var i = display.startIndex
        while i < display.endIndex {
            let ch = display[i]
            let nextIndex = display.index(after: i)
            
            if ch == "đ" || ch == "Đ" {
                baseChars.append(ch == "Đ" ? "D" : "d")
                baseChars.append("9")
                i = nextIndex
                continue
            }
            
            if let info = Alphabet.getVowelInfo(ch) {
                let baseCh = info.isUppercase ? Character(String(info.base).uppercased()) : info.base
                baseChars.append(baseCh)
                
                if info.tone != .none && toneChar == nil {
                    switch info.tone {
                    case .acute: toneChar = "1"
                    case .grave: toneChar = "2"
                    case .hook: toneChar = "3"
                    case .tilde: toneChar = "4"
                    case .dot: toneChar = "5"
                    case .none: break
                    }
                }
                
                switch info.modification {
                case .circumflex:
                    if !vowelMods.contains("6") {
                        vowelMods.append("6")
                    }
                case .horn:
                    if hasUoHornPair {
                        if !vowelMods.contains("7") {
                            vowelMods.append("7")
                        }
                    } else {
                        vowelMods.append("7")
                    }
                case .breve:
                    if !vowelMods.contains("8") {
                        vowelMods.append("8")
                    }
                case .none:
                    break
                }
            } else {
                baseChars.append(ch)
            }
            
            i = nextIndex
        }
        
        var raw = String(baseChars)
        for mod in vowelMods {
            raw.append(mod)
        }
        if let tone = toneChar {
            raw.append(tone)
        }
        return raw
    }
    
    private func reconstructRawTelex(from display: String) -> String {
        var baseChars = [Character]()
        var vowelMods = [Character]()
        var toneChar: Character? = nil
        let hasUoHornPair = hasUoHornDiphthong(in: display)
        
        var i = display.startIndex
        while i < display.endIndex {
            let ch = display[i]
            let nextIndex = display.index(after: i)
            
            if ch == "đ" || ch == "Đ" {
                baseChars.append(ch == "Đ" ? "D" : "d")
                baseChars.append(ch == "Đ" ? "D" : "d")
                i = nextIndex
                continue
            }
            
            if let info = Alphabet.getVowelInfo(ch) {
                let baseCh = info.isUppercase ? Character(String(info.base).uppercased()) : info.base
                baseChars.append(baseCh)
                
                if info.tone != .none && toneChar == nil {
                    switch info.tone {
                    case .acute: toneChar = "s"
                    case .grave: toneChar = "f"
                    case .hook: toneChar = "r"
                    case .tilde: toneChar = "x"
                    case .dot: toneChar = "j"
                    case .none: break
                    }
                }
                
                switch info.modification {
                case .circumflex:
                    vowelMods.append(info.base)
                case .horn:
                    if hasUoHornPair {
                        if !vowelMods.contains("w") {
                            vowelMods.append("w")
                        }
                    } else {
                        vowelMods.append("w")
                    }
                case .breve:
                    vowelMods.append("w")
                case .none:
                    break
                }
            } else {
                baseChars.append(ch)
            }
            
            i = nextIndex
        }
        
        var raw = String(baseChars)
        for mod in vowelMods {
            raw.append(mod)
        }
        if let tone = toneChar {
            raw.append(tone)
        }
        return raw
    }
    
    private func hasUoHornDiphthong(in string: String) -> Bool {
        var prevChar: Character? = nil
        for ch in string {
            if let prev = prevChar,
               let infoPrev = Alphabet.getVowelInfo(prev),
               let infoCurr = Alphabet.getVowelInfo(ch) {
                let isU = (infoPrev.base == "u" || infoPrev.base == "U")
                let isO = (infoCurr.base == "o" || infoCurr.base == "O")
                let hasHorn = (infoPrev.modification == .horn || infoCurr.modification == .horn)
                if isU && isO && hasHorn {
                    return true
                }
            }
            prevChar = ch
        }
        return false
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
            
            let hasVowels = letters.contains { Alphabet.isVowel($0) }
            
            // Check tone key in Telex: s, f, r, x, j, z (only applicable if word has vowels)
            if hasVowels && isTelexToneKey(lower) {
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
            
            // Check double horn: uo / uô + w -> ươ, or uu + w -> ưu (MUST check before single vowel + w)
            if lower == "w" && letters.count >= 2 {
                var uoIndex: Int? = nil
                var uuIndex: Int? = nil
                for i in stride(from: letters.count - 2, through: 0, by: -1) {
                    let c1 = Character(String(letters[i]).lowercased())
                    let c2 = Character(String(letters[i + 1]).lowercased())
                    let isU = (c1 == "u" || c1 == "ư")
                    let isO = (c2 == "o" || c2 == "ô" || c2 == "ơ")
                    if isU && isO {
                        uoIndex = i
                        break
                    }
                    let isU2 = (c2 == "u" || c2 == "ư")
                    if isU && isU2 {
                        uuIndex = i
                        break
                    }
                }
                
                if let idx = uoIndex {
                    let c1 = Character(String(letters[idx]).lowercased())
                    let c2 = Character(String(letters[idx + 1]).lowercased())
                    let u1 = letters[idx].isUppercase
                    let u2 = letters[idx + 1].isUppercase
                    
                    if c1 == "ư" && c2 == "ơ" {
                        // Undo toggle: ươ + w -> uo + w
                        letters[idx] = u1 ? "U" : "u"
                        letters[idx + 1] = u2 ? "O" : "o"
                        letters.append(char)
                    } else {
                        // Transform pair into ươ
                        letters[idx] = u1 ? "Ư" : "ư"
                        letters[idx + 1] = u2 ? "Ơ" : "ơ"
                    }
                    continue
                } else if let idx = uuIndex {
                    let c1 = Character(String(letters[idx]).lowercased())
                    let c2 = Character(String(letters[idx + 1]).lowercased())
                    let u1 = letters[idx].isUppercase
                    let u2 = letters[idx + 1].isUppercase
                    
                    if c1 == "ư" && c2 == "u" {
                        // Undo toggle: ưu + w -> uu + w
                        letters[idx] = u1 ? "U" : "u"
                        letters[idx + 1] = u2 ? "U" : "u"
                        letters.append(char)
                    } else {
                        // Transform pair into ưu (e.g. uu -> ưu, uư -> ưu)
                        letters[idx] = u1 ? "Ư" : "ư"
                        letters[idx + 1] = u2 ? "U" : "u"
                    }
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
        
        fixInvalidDiphthongs(&letters)
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
        
        // 1. Circumflex: aa -> â, ee -> ê, oo -> ô (and ă + a -> â, ơ + o -> ô)
        if (lastLower == "a" || lastLower == "ă") && inLower == "a" {
            letters.removeLast()
            return isUpper ? "Â" : "â"
        }
        if lastLower == "e" && inLower == "e" {
            letters.removeLast()
            return isUpper ? "Ê" : "ê"
        }
        if (lastLower == "o" || lastLower == "ơ") && inLower == "o" {
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
        
        // 2. Breve & Horn with 'w': aw -> ă, ow -> ơ, uw -> ư (and â + w -> ă, ô + w -> ơ)
        if (lastLower == "a" || lastLower == "â") && inLower == "w" {
            letters.removeLast()
            return isUpper ? "Ă" : "ă"
        }
        if (lastLower == "o" || lastLower == "ô") && inLower == "w" {
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
                let hasVowel = letters.contains(where: { Alphabet.isVowel($0) })
                let hasD = letters.contains(where: { $0 == "d" || $0 == "D" || $0 == "đ" || $0 == "Đ" })
                var handled = false
                
                switch char {
                case "1":
                    if hasVowel {
                        if currentTone == .acute {
                            currentTone = .none
                            letters.append(char)
                        } else {
                            currentTone = .acute
                        }
                        handled = true
                    }
                case "2":
                    if hasVowel {
                        if currentTone == .grave {
                            currentTone = .none
                            letters.append(char)
                        } else {
                            currentTone = .grave
                        }
                        handled = true
                    }
                case "3":
                    if hasVowel {
                        if currentTone == .hook {
                            currentTone = .none
                            letters.append(char)
                        } else {
                            currentTone = .hook
                        }
                        handled = true
                    }
                case "4":
                    if hasVowel {
                        if currentTone == .tilde {
                            currentTone = .none
                            letters.append(char)
                        } else {
                            currentTone = .tilde
                        }
                        handled = true
                    }
                case "5":
                    if hasVowel {
                        if currentTone == .dot {
                            currentTone = .none
                            letters.append(char)
                        } else {
                            currentTone = .dot
                        }
                        handled = true
                    }
                case "0":
                    if currentTone != .none {
                        currentTone = .none
                        handled = true
                    }
                case "6": // Â, Ê, Ô
                    // First check for "uo" / "ươ" diphthong pair in word
                    var uoIndex: Int? = nil
                    if letters.count >= 2 {
                        for i in 0..<(letters.count - 1) {
                            let c1 = Character(String(letters[i]).lowercased())
                            let c2 = Character(String(letters[i + 1]).lowercased())
                            let isU = (c1 == "u" || c1 == "ư")
                            let isO = (c2 == "o" || c2 == "ô" || c2 == "ơ")
                            if isU && isO {
                                uoIndex = i
                                break
                            }
                        }
                    }
                    
                    if let idx = uoIndex {
                        let c1 = Character(String(letters[idx]).lowercased())
                        let c2 = Character(String(letters[idx + 1]).lowercased())
                        let u1 = letters[idx].isUppercase
                        let u2 = letters[idx + 1].isUppercase
                        
                        if c1 == "u" && c2 == "ô" {
                            // Undo toggle: "uô" -> "uo" + 6
                            letters[idx] = u1 ? "U" : "u"
                            letters[idx + 1] = u2 ? "O" : "o"
                            letters.append(char)
                        } else {
                            // Transform pair into "uô" (e.g. uo -> uô, ươ -> uô, ưo -> uô, uơ -> uô)
                            letters[idx] = u1 ? "U" : "u"
                            letters[idx + 1] = u2 ? "Ô" : "ô"
                        }
                        handled = true
                    } else {
                        // Single vowel: check backward for a, e, o, â, ê, ô, ă, ơ
                        for i in stride(from: letters.count - 1, through: 0, by: -1) {
                            let l = Character(String(letters[i]).lowercased())
                            let u = letters[i].isUppercase
                            if l == "â" || l == "ê" || l == "ô" {
                                let baseChar: Character = (l == "â") ? "a" : ((l == "ê") ? "e" : "o")
                                letters[i] = u ? Character(String(baseChar).uppercased()) : baseChar
                                letters.append(char)
                                handled = true
                                break
                            } else if l == "a" || l == "e" || l == "o" || l == "ă" || l == "ơ" {
                                if l == "a" || l == "ă" { letters[i] = u ? "Â" : "â" }
                                else if l == "e" { letters[i] = u ? "Ê" : "ê" }
                                else if l == "o" || l == "ơ" { letters[i] = u ? "Ô" : "ô" }
                                handled = true
                                break
                            }
                        }
                    }
                case "7": // Ơ, Ư
                    // First check for "uo" / "ươ" pair or "uu" / "ưu" pair in word
                    var uoIndex: Int? = nil
                    var uuIndex: Int? = nil
                    if letters.count >= 2 {
                        for i in 0..<(letters.count - 1) {
                            let c1 = Character(String(letters[i]).lowercased())
                            let c2 = Character(String(letters[i + 1]).lowercased())
                            let isU = (c1 == "u" || c1 == "ư")
                            let isO = (c2 == "o" || c2 == "ô" || c2 == "ơ")
                            if isU && isO {
                                uoIndex = i
                                break
                            }
                            let isU2 = (c2 == "u" || c2 == "ư")
                            if isU && isU2 {
                                uuIndex = i
                                break
                            }
                        }
                    }
                    
                    if let idx = uoIndex {
                        let c1 = Character(String(letters[idx]).lowercased())
                        let c2 = Character(String(letters[idx + 1]).lowercased())
                        let u1 = letters[idx].isUppercase
                        let u2 = letters[idx + 1].isUppercase
                        if c1 == "ư" && c2 == "ơ" {
                            // Undo "ươ" -> "uo" + 7
                            letters[idx] = u1 ? "U" : "u"
                            letters[idx + 1] = u2 ? "O" : "o"
                            letters.append(char)
                        } else {
                            // Transform pair into "ươ" (e.g. uo -> ươ, uô -> ươ, ưo -> ươ, uơ -> ươ)
                            letters[idx] = u1 ? "Ư" : "ư"
                            letters[idx + 1] = u2 ? "Ơ" : "ơ"
                        }
                        handled = true
                    } else if let idx = uuIndex {
                        let c1 = Character(String(letters[idx]).lowercased())
                        let c2 = Character(String(letters[idx + 1]).lowercased())
                        let u1 = letters[idx].isUppercase
                        let u2 = letters[idx + 1].isUppercase
                        if c1 == "ư" && c2 == "u" {
                            // Undo "ưu" -> "uu" + 7
                            letters[idx] = u1 ? "U" : "u"
                            letters[idx + 1] = u2 ? "U" : "u"
                            letters.append(char)
                        } else {
                            // Transform pair into "ưu" (e.g. uu -> ưu, uư -> ưu, ưư -> ưu)
                            letters[idx] = u1 ? "Ư" : "ư"
                            letters[idx + 1] = u2 ? "U" : "u"
                        }
                        handled = true
                    } else {
                        // Single vowel: check backward for u, o, or ô
                        for i in stride(from: letters.count - 1, through: 0, by: -1) {
                            let l = Character(String(letters[i]).lowercased())
                            let u = letters[i].isUppercase
                            if l == "ơ" || l == "ư" {
                                let baseChar: Character = (l == "ơ") ? "o" : "u"
                                letters[i] = u ? Character(String(baseChar).uppercased()) : baseChar
                                letters.append(char)
                                handled = true
                                break
                            } else if l == "o" || l == "u" || l == "ô" {
                                letters[i] = (l == "u") ? (u ? "Ư" : "ư") : (u ? "Ơ" : "ơ")
                                handled = true
                                break
                            }
                        }
                    }
                case "8": // Ă
                    for i in stride(from: letters.count - 1, through: 0, by: -1) {
                        let l = Character(String(letters[i]).lowercased())
                        let u = letters[i].isUppercase
                        if l == "ă" {
                            letters[i] = u ? "A" : "a"
                            letters.append(char)
                            handled = true
                            break
                        } else if l == "a" || l == "â" {
                            letters[i] = u ? "Ă" : "ă"
                            handled = true
                            break
                        }
                    }
                case "9": // Đ
                    if hasD {
                        for i in stride(from: letters.count - 1, through: 0, by: -1) {
                            let l = Character(String(letters[i]).lowercased())
                            let u = letters[i].isUppercase
                            if l == "đ" {
                                letters[i] = u ? "D" : "d"
                                letters.append(char)
                                handled = true
                                break
                            } else if l == "d" {
                                letters[i] = u ? "Đ" : "đ"
                                handled = true
                                break
                            }
                        }
                    }
                default: break
                }
                
                if handled {
                    continue
                }
            }
            letters.append(char)
        }
        
        fixInvalidDiphthongs(&letters)
        var word = String(letters)
        if currentTone != .none {
            word = applyTone(to: word, tone: currentTone)
        }
        return word
    }
    
    private func fixInvalidDiphthongs(_ letters: inout [Character]) {
        guard letters.count >= 2 else { return }
        for i in 0..<(letters.count - 1) {
            let c1 = Character(String(letters[i]).lowercased())
            let c2 = Character(String(letters[i + 1]).lowercased())
            if c1 == "u" && c2 == "ư" {
                // "uư" is never valid in Vietnamese, auto-correct to "ưu"
                let u1 = letters[i].isUppercase
                let u2 = letters[i + 1].isUppercase
                letters[i] = u1 ? "Ư" : "ư"
                letters[i + 1] = u2 ? "U" : "u"
            }
        }
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
