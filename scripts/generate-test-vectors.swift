#!/usr/bin/env swift
//
// Generates test-vectors/v1/*.json (Git submodule) from the reference Swift crypto primitives.
// Run from repo root: swift scripts/generate-test-vectors.swift
// Then commit and push in the test-vectors submodule repo; bump the submodule pointer in this repo.
// See docs/test-vectors.md
//

import CryptoKit
import Foundation

#if canImport(CommonCrypto)
import CommonCrypto
#endif

let alphabet = Array("23456789ABCDEFGHJKMNPQRSTVWXYZ")
let saltUTF8 = "Bip39Chiper.v1.positional-hasher"
let versionPrefix = "v1"
let tokenLength = 8
let truncateBytes = 5

struct Params: Codable {
    let version: String
    let salt_utf8: String
    let iterations: Int
    let key_bytes: Int
}

struct KDFVector: Codable {
    let id: String
    let password_utf8: String
    let params: Params
    let key_hex: String
}

struct TokenVector: Codable {
    let id: String
    let password_utf8: String
    let params: Params
    let position: Int
    let word_index: Int
    let word: String?
    let payload_utf8: String
    let key_hex: String
    let hmac_sha256_hex: String
    let hmac_truncated_hex: String
    let truncated_big_endian_int: String
    let value_mod_radix_pow_len: String
    let radix: Int
    let modulus: String
    let token: String
}

struct ObfuscateVector: Codable {
    let id: String
    let password_utf8: String
    let params: Params
    let word_count: Int
    let mnemonic: [String]
    let tokens: [String]
    let key_hex: String
}

struct RecoveryVector: Codable {
    let id: String
    let obfuscate_id: String
    let password_utf8: String
    let params: Params
    let word_count: Int
    let tokens_shuffled: [String]
    let expected_mnemonic: [String]
}

struct NormalizeVector: Codable {
    let id: String
    let input: String
    let normalized: String
    let valid: Bool
}

struct ExportVector: Codable {
    let id: String
    let obfuscate_id: String
    let file: String
    let expected_version: String?
    let expected_word_count: Int?
    let expected_iterations: Int?
    let expected_key_bytes: Int?
    let notes: String?
}

struct Manifest: Codable {
    let format_version: String
    let generated_at: String
    let radix: Int
    let alphabet: String
    let spec: String?
    let verification: String?
    let files: [String: String]
}

func deriveKey(password: String, iterations: Int, keyBytes: Int) -> Data {
    let salt = Data(saltUTF8.utf8)
    var derived = Data(count: keyBytes)
    let status = derived.withUnsafeMutableBytes { derivedBytes in
        password.withCString { passwordPtr in
            salt.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passwordPtr,
                    password.lengthOfBytes(using: .utf8),
                    saltBytes.bindMemory(to: UInt8.self).baseAddress,
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    UInt32(iterations),
                    derivedBytes.bindMemory(to: UInt8.self).baseAddress,
                    keyBytes
                )
            }
        }
    }
    precondition(status == kCCSuccess)
    return derived
}

func encodeFixed(bytes: [UInt8], length: Int) -> (token: String, valueMod: UInt64) {
    var value: UInt64 = 0
    for byte in bytes { value = (value << 8) | UInt64(byte) }
    let radix = alphabet.count
    var modulus: UInt64 = 1
    for _ in 0..<length { modulus *= UInt64(radix) }
    value %= modulus
    if value == 0 {
        return (String(repeating: String(alphabet[0]), count: length), 0)
    }
    var chars: [Character] = []
    var n = value
    while n > 0 {
        chars.append(alphabet[Int(n % UInt64(radix))])
        n /= UInt64(radix)
    }
    while chars.count < length { chars.append(alphabet[0]) }
    return (String(chars.reversed()), value)
}

func token(position: Int, wordIndex: Int, key: SymmetricKey) -> (token: String, payload: String, mac: [UInt8], valueMod: UInt64) {
    let payload = "\(versionPrefix):\(position):\(wordIndex)"
    let mac = Array(HMAC<SHA256>.authenticationCode(for: Data(payload.utf8), using: key))
    let truncated = Array(mac.prefix(truncateBytes))
    let encoded = encodeFixed(bytes: truncated, length: tokenLength)
    return (encoded.token, payload, mac, encoded.valueMod)
}

func hex(_ data: Data) -> String { data.map { String(format: "%02x", $0) }.joined() }
func hex(_ bytes: [UInt8]) -> String { bytes.map { String(format: "%02x", $0) }.joined() }

func params(iterations: Int, keyBytes: Int) -> Params {
    Params(version: versionPrefix, salt_utf8: saltUTF8, iterations: iterations, key_bytes: keyBytes)
}

func mnemonicFromEntropy(_ entropy: Data, wordlist: [String]) -> [String] {
    let entBits = entropy.count * 8
    let checksumBitCount = entBits / 32
    let hash = Array(SHA256.hash(data: entropy))
    var bits: [Bool] = []
    for byte in entropy {
        for shift in stride(from: 7, through: 0, by: -1) {
            bits.append(((byte >> shift) & 1) == 1)
        }
    }
    let firstHashByte = hash[0]
    for shift in stride(from: 7, through: 7 - checksumBitCount + 1, by: -1) {
        bits.append(((firstHashByte >> shift) & 1) == 1)
    }
    let wordCount = (entBits + checksumBitCount) / 11
    var result: [String] = []
    for wordIndex in 0..<wordCount {
        let start = wordIndex * 11
        var index = 0
        for bitOffset in 0..<11 {
            index <<= 1
            if bits[start + bitOffset] { index |= 1 }
        }
        result.append(wordlist[index])
    }
    return result
}

func fixedEntropy(count: Int, seed: UInt8) -> Data {
    Data(repeating: seed, count: count * 4 / 3) // 12->16, 15->20, 18->24, 21->28, 24->32
}

func loadWordlist(repoRoot: URL) -> [String] {
    let path = repoRoot
        .appendingPathComponent("Bip39Chiper/Core/BIP39/BIP39Wordlist.swift")
    let text = try! String(contentsOf: path, encoding: .utf8)
    var words: [String] = []
    for line in text.split(separator: "\n") {
        let s = line.trimmingCharacters(in: .whitespaces)
        guard s.hasPrefix("\"") else { continue }
        if s.hasSuffix("\","), s.count > 3 {
            words.append(String(s.dropFirst().dropLast(2)))
        } else if s.hasSuffix("\""), s.count > 2 {
            words.append(String(s.dropFirst().dropLast()))
        }
    }
    precondition(words.count == 2048, "expected 2048 words, got \(words.count)")
    return words
}

func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(value)
    try data.write(to: url)
}

let repoRoot = URL(fileURLWithPath: CommandLine.arguments[0])
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let outDir = repoRoot.appendingPathComponent("test-vectors/v1")
let exportDir = outDir.appendingPathComponent("export-files")
try FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)

let words = loadWordlist(repoRoot: repoRoot)
let radix = alphabet.count
var modulus: UInt64 = 1
for _ in 0..<tokenLength { modulus *= UInt64(radix) }

// MARK: - KDF vectors (~70 cases)

let kdfPasswords = [
    "testpassword",
    "securepassphrase",
    "päss🔑word",
    "correct horse battery staple",
    "12345678",
    "testpassword!",
    "αβγδε6789",
]

let kdfIterations = [
    100_000, 210_000, 600_000, 1_000_000, 2_000_000,
    3_000_000, 5_000_000, 10_000_000, 15_000_000, 20_000_000,
]

var kdfVectors: [KDFVector] = []
for (pi, password) in kdfPasswords.enumerated() {
    for (ii, iterations) in kdfIterations.enumerated() {
        let id = String(format: "kdf-p%02d-i%02d", pi + 1, ii + 1)
        let key = deriveKey(password: password, iterations: iterations, keyBytes: 32)
        kdfVectors.append(KDFVector(
            id: id,
            password_utf8: password,
            params: params(iterations: iterations, keyBytes: 32),
            key_hex: hex(key)
        ))
    }
}

// Key-length variants (16 / 64 bytes) with the canonical password
for (_, keyBytes) in [16, 64].enumerated() {
    for (ii, iterations) in [100_000, 600_000, 1_000_000, 5_000_000, 10_000_000].enumerated() {
        let id = String(format: "kdf-key%d-i%02d", keyBytes, ii + 1)
        let key = deriveKey(password: "testpassword", iterations: iterations, keyBytes: keyBytes)
        kdfVectors.append(KDFVector(
            id: id,
            password_utf8: "testpassword",
            params: params(iterations: iterations, keyBytes: keyBytes),
            key_hex: hex(key)
        ))
    }
}

// MARK: - Token vectors (~100 cases)

struct TokenCaseConfig {
    let password: String
    let iterations: Int
    let keyBytes: Int
    let suffix: String
}

let tokenConfigs = [
    TokenCaseConfig(password: "testpassword", iterations: 100_000, keyBytes: 32, suffix: "100k"),
    TokenCaseConfig(password: "testpassword", iterations: 600_000, keyBytes: 32, suffix: "600k"),
    TokenCaseConfig(password: "securepassphrase", iterations: 100_000, keyBytes: 32, suffix: "secure"),
    TokenCaseConfig(password: "testpassword", iterations: 100_000, keyBytes: 16, suffix: "key16"),
    TokenCaseConfig(password: "testpassword", iterations: 100_000, keyBytes: 64, suffix: "key64"),
]

let tokenPositions = Array(1...24)
let tokenWordIndices = [0, 1, 2, 7, 42, 100, 256, 512, 777, 1024, 1500, 1999, 2047]

var tokenVectors: [TokenVector] = []
var tokenSerial = 0
for config in tokenConfigs {
    for position in tokenPositions {
        for wordIndex in tokenWordIndices {
            tokenSerial += 1
            if tokenSerial > 100 { break }
            let id = String(format: "token-%03d-%@", tokenSerial, config.suffix)
            let keyData = deriveKey(password: config.password, iterations: config.iterations, keyBytes: config.keyBytes)
            let key = SymmetricKey(data: keyData)
            let result = token(position: position, wordIndex: wordIndex, key: key)
            let truncated = Array(result.mac.prefix(truncateBytes))
            let truncatedInt = truncated.reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
            tokenVectors.append(TokenVector(
                id: id,
                password_utf8: config.password,
                params: params(iterations: config.iterations, keyBytes: config.keyBytes),
                position: position,
                word_index: wordIndex,
                word: words[wordIndex],
                payload_utf8: result.payload,
                key_hex: hex(keyData),
                hmac_sha256_hex: hex(result.mac),
                hmac_truncated_hex: hex(truncated),
                truncated_big_endian_int: String(truncatedInt),
                value_mod_radix_pow_len: String(result.valueMod),
                radix: radix,
                modulus: String(modulus),
                token: result.token
            ))
        }
        if tokenSerial >= 100 { break }
    }
    if tokenSerial >= 100 { break }
}

// MARK: - Obfuscate vectors (~80 cases)

let obfuscateWordCounts = [12, 15, 18, 21, 24]
let obfuscateSeeds: [UInt8] = Array(0..<16)

var obfuscateVectors: [ObfuscateVector] = []
for count in obfuscateWordCounts {
    for seed in obfuscateSeeds {
        let id: String
        if count == 12 && seed == 0x00 {
            id = "obf-12-first-100k"
        } else if count == 24 && seed == 0x04 {
            id = "obf-24-first-100k"
        } else {
            id = String(format: "obf-n%02d-s%02x-100k", count, seed)
        }
        let mnemonic = mnemonicFromEntropy(fixedEntropy(count: count, seed: seed), wordlist: words)
        let keyData = deriveKey(password: "testpassword", iterations: 100_000, keyBytes: 32)
        let key = SymmetricKey(data: keyData)
        var tokens: [String] = []
        for offset in 0..<count {
            let p = offset + 1
            let wi = words.firstIndex(of: mnemonic[offset])!
            tokens.append(token(position: p, wordIndex: wi, key: key).token)
        }
        obfuscateVectors.append(ObfuscateVector(
            id: id,
            password_utf8: "testpassword",
            params: params(iterations: 100_000, keyBytes: 32),
            word_count: count,
            mnemonic: mnemonic,
            tokens: tokens,
            key_hex: hex(keyData)
        ))
    }
}

// Additional obfuscate variants: alternate passwords / iterations (+16 cases → ~96 total)
for (id, password, iterations, count, seed) in [
    ("obf-12-600k", "testpassword", 600_000, 12, UInt8(0x00)),
    ("obf-12-secure", "securepassphrase", 100_000, 12, UInt8(0x00)),
    ("obf-24-600k", "testpassword", 600_000, 24, UInt8(0x04)),
    ("obf-24-secure", "securepassphrase", 100_000, 24, UInt8(0x04)),
] + (0..<12).map({ v in
    ("obf-12-var-\(v)", "testpassword", 100_000, 12, UInt8(v + 0xA0))
}) {
    let mnemonic = mnemonicFromEntropy(fixedEntropy(count: count, seed: seed), wordlist: words)
    let keyData = deriveKey(password: password, iterations: iterations, keyBytes: 32)
    let key = SymmetricKey(data: keyData)
    var tokens: [String] = []
    for offset in 0..<count {
        let p = offset + 1
        let wi = words.firstIndex(of: mnemonic[offset])!
        tokens.append(token(position: p, wordIndex: wi, key: key).token)
    }
    obfuscateVectors.append(ObfuscateVector(
        id: id,
        password_utf8: password,
        params: params(iterations: iterations, keyBytes: 32),
        word_count: count,
        mnemonic: mnemonic,
        tokens: tokens,
        key_hex: hex(keyData)
    ))
}

// MARK: - Recovery vectors (shuffled)

func normalizeToken(_ raw: String) -> String {
    let upper = raw.uppercased()
    let set = Set(alphabet)
    return String(upper.filter { set.contains($0) })
}

func isValidNormalized(_ normalized: String) -> Bool {
    normalized.count == tokenLength && normalized.allSatisfy { alphabet.contains($0) }
}

func chunkJoin(_ base: String, sep: String) -> String {
    var parts: [String] = []
    var i = base.startIndex
    while i < base.endIndex {
        let next = base.index(i, offsetBy: 2, limitedBy: base.endIndex) ?? base.endIndex
        parts.append(String(base[i..<next]))
        i = next
    }
    return parts.joined(separator: sep)
}

var recoveryVectors: [RecoveryVector] = []
let shufflePatterns: [String: ([String]) -> [String]] = [
    "reverse": { Array($0.reversed()) },
    "rotate-half": { let m = $0.count / 2; return Array($0[m...] + $0[..<m]) },
    "odd-even": { var o: [String] = []; var e: [String] = []; for (i, t) in $0.enumerated() { if i % 2 == 0 { o.append(t) } else { e.append(t) } }; return o + e },
]

for obf in obfuscateVectors {
    for (suffix, shuffle) in shufflePatterns {
        let id = "recovery-\(obf.id)-\(suffix)"
        recoveryVectors.append(RecoveryVector(
            id: id,
            obfuscate_id: obf.id,
            password_utf8: obf.password_utf8,
            params: obf.params,
            word_count: obf.word_count,
            tokens_shuffled: shuffle(obf.tokens),
            expected_mnemonic: obf.mnemonic
        ))
    }
}

// MARK: - Normalize vectors (~70 cases)

var normalizeVectors: [NormalizeVector] = []
let referenceTokens = ["JKDEPFPN", "DRF92TRD", "QAY3KFYJ", "2S9EW4VS", "WMCEXZ8H"]

for (ti, base) in referenceTokens.enumerated() {
    normalizeVectors.append(NormalizeVector(id: "norm-\(ti)-upper", input: base, normalized: base, valid: true))
    normalizeVectors.append(NormalizeVector(id: "norm-\(ti)-lower", input: base.lowercased(), normalized: base, valid: true))
}

let separators = [" ", "  ", "\t", "-", "_", ".", ",", ";", " - ", "\n"]
for (si, sep) in separators.enumerated() {
    let spaced = chunkJoin("JKDEPFPN", sep: sep)
    let normalized = normalizeToken(spaced)
    normalizeVectors.append(NormalizeVector(
        id: "norm-sep-\(si)",
        input: spaced,
        normalized: normalized,
        valid: isValidNormalized(normalized)
    ))
}

for length in 1...7 {
    let input = String("JKDEPFPN".prefix(length))
    let normalized = normalizeToken(input)
    normalizeVectors.append(NormalizeVector(
        id: "norm-short-\(length)",
        input: input,
        normalized: normalized,
        valid: isValidNormalized(normalized)
    ))
}

let invalidChars = ["0", "O", "1", "I", "L", "U", "!", "@", "/"]
for (ci, ch) in invalidChars.enumerated() {
    var chars = Array("JKDEPFPN")
    chars[ci % chars.count] = Character(ch)
    let input = String(chars)
    let normalized = normalizeToken(input)
    normalizeVectors.append(NormalizeVector(
        id: "norm-invalid-\(ci)",
        input: input,
        normalized: normalized,
        valid: isValidNormalized(normalized)
    ))
}

for (pi, prefix) in ["", " ", "  ", "\t", ">>> ", "(", ") "].enumerated() {
    for (si, suffix) in ["", " ", "!!", "..."].enumerated() {
        if normalizeVectors.count >= 70 { break }
        let input = prefix + "jkdepfpn" + suffix
        let normalized = normalizeToken(input)
        normalizeVectors.append(NormalizeVector(
            id: "norm-wrap-\(pi)-\(si)",
            input: input,
            normalized: normalized,
            valid: isValidNormalized(normalized)
        ))
    }
}

// Pad normalize set to at least 70 entries
while normalizeVectors.count < 70 {
    let n = normalizeVectors.count
    let input = "jkdepfpn" + String(repeating: " ", count: n % 4)
    let normalized = normalizeToken(input)
    normalizeVectors.append(NormalizeVector(
        id: "norm-pad-\(n)",
        input: input,
        normalized: normalized,
        valid: isValidNormalized(normalized)
    ))
}

// MARK: - Export files

func obfuscateById(_ id: String) -> ObfuscateVector? {
    obfuscateVectors.first { $0.id == id }
}

func standardHeaders(_ obf: ObfuscateVector, uppercaseKeys: Bool = false) -> [String] {
    let versionKey = uppercaseKeys ? "VERSION" : "version"
    let wordsKey = uppercaseKeys ? "Words" : "words"
    let iterationsKey = uppercaseKeys ? "ITERATIONS" : "iterations"
    let keyBytesKey = uppercaseKeys ? "KeyBytes" : "keyBytes"
    return [
        "# \(versionKey): \(obf.params.version)",
        "# \(wordsKey): \(obf.word_count)",
        "# \(iterationsKey): \(obf.params.iterations)",
        "# \(keyBytesKey): \(obf.params.key_bytes)",
    ]
}

func joinTokens(_ tokens: [String], style: String) -> String {
    switch style {
    case "comma":
        return tokens.joined(separator: ", ")
    case "semicolon":
        return tokens.joined(separator: ";")
    case "mixed":
        return tokens.enumerated().map { index, token in
            switch index % 3 {
            case 0: return token
            case 1: return ", \(token)"
            default: return " \(token);"
            }
        }.joined()
    default:
        return tokens.joined(separator: " ")
    }
}

struct ExportFileSpec {
    let id: String
    let obfuscateId: String
    let filename: String
    let tokenStyle: String
    let uppercaseHeaders: Bool
    let includeHeaders: Bool
    let extraBlankLines: Bool
    let notes: String?
}

let exportSpecs: [ExportFileSpec] = [
    ExportFileSpec(id: "export-12-100k-space", obfuscateId: "obf-12-first-100k", filename: "sample-12-100k.txt", tokenStyle: "space", uppercaseHeaders: false, includeHeaders: true, extraBlankLines: false, notes: "Canonical 12-word export, space-separated tokens"),
    ExportFileSpec(id: "export-24-100k-space", obfuscateId: "obf-24-first-100k", filename: "sample-24-100k.txt", tokenStyle: "space", uppercaseHeaders: false, includeHeaders: true, extraBlankLines: false, notes: "Canonical 24-word export"),
    ExportFileSpec(id: "export-15-100k-space", obfuscateId: "obf-n15-s00-100k", filename: "sample-15-100k.txt", tokenStyle: "space", uppercaseHeaders: false, includeHeaders: true, extraBlankLines: false, notes: "15-word mnemonic"),
    ExportFileSpec(id: "export-18-100k-space", obfuscateId: "obf-n18-s00-100k", filename: "sample-18-100k.txt", tokenStyle: "space", uppercaseHeaders: false, includeHeaders: true, extraBlankLines: false, notes: "18-word mnemonic"),
    ExportFileSpec(id: "export-21-100k-space", obfuscateId: "obf-n21-s00-100k", filename: "sample-21-100k.txt", tokenStyle: "space", uppercaseHeaders: false, includeHeaders: true, extraBlankLines: false, notes: "21-word mnemonic"),
    ExportFileSpec(id: "export-12-600k", obfuscateId: "obf-12-600k", filename: "sample-12-600k.txt", tokenStyle: "space", uppercaseHeaders: false, includeHeaders: true, extraBlankLines: false, notes: "Default app iteration preset (600k)"),
    ExportFileSpec(id: "export-24-600k", obfuscateId: "obf-24-600k", filename: "sample-24-600k.txt", tokenStyle: "space", uppercaseHeaders: false, includeHeaders: true, extraBlankLines: false, notes: "24 words at 600k iterations"),
    ExportFileSpec(id: "export-12-secure", obfuscateId: "obf-12-secure", filename: "sample-12-secure.txt", tokenStyle: "space", uppercaseHeaders: false, includeHeaders: true, extraBlankLines: false, notes: "Alternate password"),
    ExportFileSpec(id: "export-24-secure", obfuscateId: "obf-24-secure", filename: "sample-24-secure.txt", tokenStyle: "space", uppercaseHeaders: false, includeHeaders: true, extraBlankLines: false, notes: "24 words, alternate password"),
    ExportFileSpec(id: "export-12-comma", obfuscateId: "obf-12-first-100k", filename: "sample-12-100k-comma.txt", tokenStyle: "comma", uppercaseHeaders: false, includeHeaders: true, extraBlankLines: false, notes: "Comma-separated token line"),
    ExportFileSpec(id: "export-12-semicolon", obfuscateId: "obf-12-first-100k", filename: "sample-12-100k-semicolon.txt", tokenStyle: "semicolon", uppercaseHeaders: false, includeHeaders: true, extraBlankLines: false, notes: "Semicolon-separated token line"),
    ExportFileSpec(id: "export-12-mixed-separators", obfuscateId: "obf-12-first-100k", filename: "sample-12-100k-mixed.txt", tokenStyle: "mixed", uppercaseHeaders: false, includeHeaders: true, extraBlankLines: false, notes: "Mixed comma/space/semicolon separators"),
    ExportFileSpec(id: "export-12-uppercase-headers", obfuscateId: "obf-12-first-100k", filename: "sample-12-100k-upper-headers.txt", tokenStyle: "space", uppercaseHeaders: true, includeHeaders: true, extraBlankLines: false, notes: "Mixed-case header keys"),
    ExportFileSpec(id: "export-12-blank-lines", obfuscateId: "obf-12-first-100k", filename: "sample-12-100k-blank-lines.txt", tokenStyle: "space", uppercaseHeaders: false, includeHeaders: true, extraBlankLines: true, notes: "Blank lines between headers and tokens"),
    ExportFileSpec(id: "export-12-tokens-only", obfuscateId: "obf-12-first-100k", filename: "sample-12-tokens-only.txt", tokenStyle: "space", uppercaseHeaders: false, includeHeaders: false, extraBlankLines: false, notes: "No comment headers; caller supplies parameters"),
]

var exportVectors: [ExportVector] = []

for spec in exportSpecs {
    guard let obf = obfuscateById(spec.obfuscateId) else {
        fputs("Missing obfuscate vector for export spec \(spec.id)\n", stderr)
        continue
    }

    var lines: [String] = []
    if spec.includeHeaders {
        lines.append(contentsOf: standardHeaders(obf, uppercaseKeys: spec.uppercaseHeaders))
        if spec.extraBlankLines {
            lines.append("")
            lines.append("")
        }
    }
    lines.append(joinTokens(obf.tokens, style: spec.tokenStyle))

    let content = lines.joined(separator: "\n") + "\n"
    let relativePath = "export-files/\(spec.filename)"
    try content.write(to: exportDir.appendingPathComponent(spec.filename), atomically: true, encoding: .utf8)

    exportVectors.append(ExportVector(
        id: spec.id,
        obfuscate_id: spec.obfuscateId,
        file: relativePath,
        expected_version: spec.includeHeaders ? obf.params.version : nil,
        expected_word_count: spec.includeHeaders ? obf.word_count : nil,
        expected_iterations: spec.includeHeaders ? obf.params.iterations : nil,
        expected_key_bytes: spec.includeHeaders ? obf.params.key_bytes : nil,
        notes: spec.notes
    ))
}

// MARK: - Write JSON

try writeJSON(kdfVectors, to: outDir.appendingPathComponent("kdf.json"))
try writeJSON(tokenVectors, to: outDir.appendingPathComponent("tokens.json"))
try writeJSON(obfuscateVectors, to: outDir.appendingPathComponent("obfuscate.json"))
try writeJSON(recoveryVectors, to: outDir.appendingPathComponent("recovery.json"))
try writeJSON(normalizeVectors, to: outDir.appendingPathComponent("normalize.json"))
try writeJSON(exportVectors, to: outDir.appendingPathComponent("export.json"))

let manifest = Manifest(
    format_version: "v1",
    generated_at: ISO8601DateFormatter().string(from: Date()),
    radix: radix,
    alphabet: String(alphabet),
    spec: "algorithm-spec-v1.md",
    verification: "../CONFORMANCE.md",
    files: [
        "kdf": "kdf.json",
        "tokens": "tokens.json",
        "obfuscate": "obfuscate.json",
        "recovery": "recovery.json",
        "normalize": "normalize.json",
        "export": "export.json",
    ]
)
try writeJSON(manifest, to: outDir.appendingPathComponent("manifest.json"))

print("Generated test vectors in \(outDir.path)")
print("  KDF: \(kdfVectors.count)")
print("  Tokens: \(tokenVectors.count)")
print("  Obfuscate: \(obfuscateVectors.count)")
print("  Recovery: \(recoveryVectors.count)")
print("  Normalize: \(normalizeVectors.count)")
print("  Export: \(exportVectors.count)")
