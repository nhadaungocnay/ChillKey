import Foundation

public struct EngineTestRunner {
    public static func runAllTests() {
        print("🚀 Running ChillKey Vietnamese Engine Tests...")
        var passed = 0
        var failed = 0
        
        func assertTransform(
            _ raw: String,
            expected: String,
            method: InputMethod = .telex,
            style: TonePlacementStyle = .modern,
            line: Int = #line
        ) {
            let engine = VietnameseEngine(inputMethod: method, tonePlacementStyle: style)
            var resultString = ""
            for ch in raw {
                let res = engine.processCharacter(ch)
                if !res.consumed {
                    resultString.append(ch)
                } else {
                    // simulate backspace and insert
                    if res.backspaceCount > 0 {
                        let dropCount = min(res.backspaceCount, resultString.count)
                        resultString = String(resultString.dropLast(dropCount))
                    }
                    resultString.append(res.replacement)
                }
            }
            
            if resultString == expected {
                passed += 1
                print("  ✅ [PASS] '\(raw)' -> '\(resultString)'")
            } else {
                failed += 1
                print("  ❌ [FAIL - Line \(line)] '\(raw)' -> Expected: '\(expected)', Got: '\(resultString)'")
            }
        }
        
        // --- 1. Basic Telex Vowels & Consonants ---
        assertTransform("aa", expected: "â")
        assertTransform("aw", expected: "ă")
        assertTransform("ee", expected: "ê")
        assertTransform("oo", expected: "ô")
        assertTransform("ow", expected: "ơ")
        assertTransform("uw", expected: "ư")
        assertTransform("dd", expected: "đ")
        assertTransform("DD", expected: "Đ")
        assertTransform("Dd", expected: "Đ")
        
        // --- 2. Tone Marks ---
        assertTransform("as", expected: "á")
        assertTransform("af", expected: "à")
        assertTransform("ar", expected: "ả")
        assertTransform("ax", expected: "ã")
        assertTransform("aj", expected: "ạ")
        assertTransform("az", expected: "a") // Clear tone
        
        // --- 3. Full Words in Telex ---
        assertTransform("viet", expected: "viet")
        assertTransform("vieetj", expected: "việt")
        assertTransform("tieengs", expected: "tiếng")
        assertTransform("dduowngf", expected: "đường")
        assertTransform("nguwowif", expected: "người")
        assertTransform("chuowng", expected: "chương")
        assertTransform("khuyeens", expected: "khuyến")
        assertTransform("hoaasp", expected: "hoấp")
        
        // --- 4. Modern Tone Placement (hoa`, thuy') ---
        assertTransform("hoaf", expected: "hòa", style: .modern)
        assertTransform("thooir", expected: "thổi", style: .modern)
        assertTransform("thuyxs", expected: "thúy", style: .modern)
        assertTransform("hoanf", expected: "hoàn", style: .modern)
        
        // --- 5. Traditional Tone Placement (hoa`, thuy') ---
        assertTransform("hoaf", expected: "hoà", style: .traditional)
        assertTransform("thuyxs", expected: "thuý", style: .traditional)
        
        // --- 6. Undo / Repeat Key Toggle ---
        assertTransform("aaa", expected: "aa") // aa -> â + a -> aa
        assertTransform("eee", expected: "ee")
        assertTransform("ass", expected: "as") // as -> á + s -> as (undo tone)
        assertTransform("ddd", expected: "dd") // dd -> đ + d -> dd
        
        // --- 7. VNI Tests ---
        // Pure numbers without base letters must remain numbers
        assertTransform("1", expected: "1", method: .vni)
        assertTransform("2", expected: "2", method: .vni)
        assertTransform("12345", expected: "12345", method: .vni)
        assertTransform("67890", expected: "67890", method: .vni)
        
        // VNI transformations
        assertTransform("a6", expected: "â", method: .vni)
        assertTransform("e6", expected: "ê", method: .vni)
        assertTransform("o6", expected: "ô", method: .vni)
        assertTransform("a8", expected: "ă", method: .vni)
        assertTransform("o7", expected: "ơ", method: .vni)
        assertTransform("u7", expected: "ư", method: .vni)
        assertTransform("d9", expected: "đ", method: .vni)
        assertTransform("viet65", expected: "việt", method: .vni)
        assertTransform("hoa2", expected: "hòa", method: .vni, style: .modern)
        
        // VNI uo + 7 -> ươ
        assertTransform("tuong7", expected: "tương", method: .vni)
        assertTransform("tuong72", expected: "tường", method: .vni)
        assertTransform("duong97", expected: "đương", method: .vni)
        assertTransform("d9uong72", expected: "đường", method: .vni)
        assertTransform("muon7", expected: "mươn", method: .vni)
        assertTransform("muon75", expected: "mượn", method: .vni)
        assertTransform("buoc71", expected: "bước", method: .vni)
        
        // VNI undo / toggle
        assertTransform("tuong77", expected: "tuong7", method: .vni)
        assertTransform("d99", expected: "d9", method: .vni)
        assertTransform("toan11", expected: "toan1", method: .vni)
        
        print("\n===============================")
        print("🎯 Test Summary: \(passed) Passed, \(failed) Failed")
        print("===============================\n")
        
        if failed > 0 {
            exit(1)
        }
    }
}
