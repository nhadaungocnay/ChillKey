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
        
        // gi and qu tone placement in Telex
        assertTransform("giaf", expected: "già")
        assertTransform("gias", expected: "giá")
        assertTransform("giar", expected: "giả")
        assertTransform("giax", expected: "giã")
        assertTransform("giaj", expected: "giạ")
        assertTransform("gif", expected: "gì")
        assertTransform("gis", expected: "gí")
        assertTransform("ginf", expected: "gìn")
        assertTransform("quas", expected: "quá")
        assertTransform("quaf", expected: "quà")
        assertTransform("quar", expected: "quả")
        assertTransform("quys", expected: "quý")
        assertTransform("quyeenf", expected: "quyền")
        assertTransform("quyeets", expected: "quyết")
        
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
        
        // --- 8. VNI Diphthong & Vowel Switching (uô <-> ươ, etc.) ---
        assertTransform("cuop67", expected: "cươp", method: .vni)
        assertTransform("cuop657", expected: "cượp", method: .vni)
        assertTransform("cuop617", expected: "cướp", method: .vni)
        assertTransform("cuoc67", expected: "cươc", method: .vni)
        assertTransform("tuong67", expected: "tương", method: .vni)
        assertTransform("tuong76", expected: "tuông", method: .vni)
        assertTransform("tu7o7ng", expected: "tương", method: .vni)
        assertTransform("co67", expected: "cơ", method: .vni)
        assertTransform("co76", expected: "cô", method: .vni)
        assertTransform("ca86", expected: "câ", method: .vni)
        assertTransform("ca68", expected: "că", method: .vni)
        assertTransform("van6", expected: "vân", method: .vni)
        assertTransform("chu7a", expected: "chưa", method: .vni)
        assertTransform("duoc97", expected: "đươc", method: .vni)
        
        // gi and qu tone placement in VNI
        assertTransform("gia2", expected: "già", method: .vni)
        assertTransform("gia1", expected: "giá", method: .vni)
        assertTransform("gia3", expected: "giả", method: .vni)
        assertTransform("gia4", expected: "giã", method: .vni)
        assertTransform("gia5", expected: "giạ", method: .vni)
        assertTransform("gi2", expected: "gì", method: .vni)
        assertTransform("gi1", expected: "gí", method: .vni)
        assertTransform("gin2", expected: "gìn", method: .vni)
        assertTransform("qua1", expected: "quá", method: .vni)
        assertTransform("qua2", expected: "quà", method: .vni)
        assertTransform("qua3", expected: "quả", method: .vni)
        assertTransform("quy1", expected: "quý", method: .vni)
        assertTransform("quyen62", expected: "quyền", method: .vni)
        assertTransform("quyet61", expected: "quyết", method: .vni)
        
        // Telex uô + w -> ươ
        assertTransform("cuoopw", expected: "cươp", method: .telex)
        assertTransform("coow", expected: "cơ", method: .telex)
        assertTransform("caaw", expected: "că", method: .telex)
        
        // ưu tests (never uư) in Telex
        assertTransform("uuw", expected: "ưu", method: .telex)
        assertTransform("muuw", expected: "mưu", method: .telex)
        assertTransform("cuuws", expected: "cứu", method: .telex)
        assertTransform("luuw", expected: "lưu", method: .telex)
        assertTransform("buuw", expected: "bưu", method: .telex)
        assertTransform("uuww", expected: "uuw", method: .telex) // undo
        
        // ưu tests (never uư) in VNI
        assertTransform("uu7", expected: "ưu", method: .vni)
        assertTransform("muu7", expected: "mưu", method: .vni)
        assertTransform("cuu7", expected: "cưu", method: .vni)
        assertTransform("cuu71", expected: "cứu", method: .vni)
        assertTransform("luu7", expected: "lưu", method: .vni)
        assertTransform("buu7", expected: "bưu", method: .vni)
        assertTransform("uu77", expected: "uu7", method: .vni) // undo
        
        // --- 9. Backspace Synchronization Tests ---
        // VNI: cuộp -> backspace -> cuộ -> type c -> cuộc
        let vniEngine = VietnameseEngine(inputMethod: .vni)
        for ch in "cuop65" { _ = vniEngine.processCharacter(ch) }
        assert(vniEngine.currentDisplay == "cuộp", "Expected 'cuộp', got '\(vniEngine.currentDisplay)'")
        vniEngine.handleBackspace()
        assert(vniEngine.currentDisplay == "cuộ", "Expected 'cuộ', got '\(vniEngine.currentDisplay)'")
        _ = vniEngine.processCharacter("c")
        if vniEngine.currentDisplay == "cuộc" {
            passed += 1
            print("  ✅ [PASS] Backspace sync (VNI): 'cuộp' - BS + 'c' -> '\(vniEngine.currentDisplay)'")
        } else {
            failed += 1
            print("  ❌ [FAIL] Backspace sync (VNI): Expected 'cuộc', got '\(vniEngine.currentDisplay)'")
        }
        
        // Telex: cuộp -> backspace -> cuộ -> type c -> cuộc
        let telexEngine = VietnameseEngine(inputMethod: .telex)
        for ch in "cuoojp" { _ = telexEngine.processCharacter(ch) }
        assert(telexEngine.currentDisplay == "cuộp", "Expected 'cuộp', got '\(telexEngine.currentDisplay)'")
        telexEngine.handleBackspace()
        assert(telexEngine.currentDisplay == "cuộ", "Expected 'cuộ', got '\(telexEngine.currentDisplay)'")
        _ = telexEngine.processCharacter("c")
        if telexEngine.currentDisplay == "cuộc" {
            passed += 1
            print("  ✅ [PASS] Backspace sync (Telex): 'cuộp' - BS + 'c' -> '\(telexEngine.currentDisplay)'")
        } else {
            failed += 1
            print("  ❌ [FAIL] Backspace sync (Telex): Expected 'cuộc', got '\(telexEngine.currentDisplay)'")
        }
        
        // VNI: buoc71 (bước) -> backspace 'c' (bướ) -> type 'm' -> bướm
        let vniEngine2 = VietnameseEngine(inputMethod: .vni)
        for ch in "buoc71" { _ = vniEngine2.processCharacter(ch) }
        assert(vniEngine2.currentDisplay == "bước", "Expected 'bước', got '\(vniEngine2.currentDisplay)'")
        vniEngine2.handleBackspace() // deletes 'c' -> 'bướ'
        assert(vniEngine2.currentDisplay == "bướ", "Expected 'bướ', got '\(vniEngine2.currentDisplay)'")
        _ = vniEngine2.processCharacter("m")
        if vniEngine2.currentDisplay == "bướm" {
            passed += 1
            print("  ✅ [PASS] Backspace sync (VNI): 'bước' - BS + 'm' -> '\(vniEngine2.currentDisplay)'")
        } else {
            failed += 1
            print("  ❌ [FAIL] Backspace sync (VNI): Expected 'bướm', got '\(vniEngine2.currentDisplay)'")
        }
        
        // VNI: cuu71 (cứu) -> backspace 'u' (cứ) -> type 'u' -> cứu
        let vniEngine3 = VietnameseEngine(inputMethod: .vni)
        for ch in "cuu71" { _ = vniEngine3.processCharacter(ch) }
        assert(vniEngine3.currentDisplay == "cứu", "Expected 'cứu', got '\(vniEngine3.currentDisplay)'")
        vniEngine3.handleBackspace()
        assert(vniEngine3.currentDisplay == "cứ", "Expected 'cứ', got '\(vniEngine3.currentDisplay)'")
        _ = vniEngine3.processCharacter("u")
        if vniEngine3.currentDisplay == "cứu" {
            passed += 1
            print("  ✅ [PASS] Backspace sync (VNI): 'cứu' - BS + 'u' -> '\(vniEngine3.currentDisplay)'")
        } else {
            failed += 1
            print("  ❌ [FAIL] Backspace sync (VNI): Expected 'cứu', got '\(vniEngine3.currentDisplay)'")
        }
        
        // Telex: cuuws (cứu) -> backspace 'u' (cứ) -> type 'u' -> cứu
        let telexEngine3 = VietnameseEngine(inputMethod: .telex)
        for ch in "cuuws" { _ = telexEngine3.processCharacter(ch) }
        assert(telexEngine3.currentDisplay == "cứu", "Expected 'cứu', got '\(telexEngine3.currentDisplay)'")
        telexEngine3.handleBackspace()
        assert(telexEngine3.currentDisplay == "cứ", "Expected 'cứ', got '\(telexEngine3.currentDisplay)'")
        _ = telexEngine3.processCharacter("u")
        if telexEngine3.currentDisplay == "cứu" {
            passed += 1
            print("  ✅ [PASS] Backspace sync (Telex): 'cứu' - BS + 'u' -> '\(telexEngine3.currentDisplay)'")
        } else {
            failed += 1
            print("  ❌ [FAIL] Backspace sync (Telex): Expected 'cứu', got '\(telexEngine3.currentDisplay)'")
        }
        
        print("\n===============================")
        print("🎯 Test Summary: \(passed) Passed, \(failed) Failed")
        print("===============================\n")
        
        if failed > 0 {
            exit(1)
        }
    }
}
