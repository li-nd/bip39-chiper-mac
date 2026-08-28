//
//  TestVectorsTests.swift
//  Bip39ChiperTests
//

import CryptoKit
import XCTest
@testable import Bip39Chiper

final class TestVectorsTests: XCTestCase {
    func testManifestLoadsAndMatchesAlphabet() throws {
        let manifest: TestVectorLoader.Manifest = try TestVectorLoader.load("manifest.json")
        XCTAssertEqual(manifest.format_version, "v1")
        XCTAssertEqual(manifest.radix, 30)
        XCTAssertEqual(manifest.alphabet, String(PositionalHasher.alphabet))
        XCTAssertEqual(PositionalHasher.alphabet.count, 30)
        XCTAssertEqual(manifest.spec, "algorithm-spec-v1.md")
        XCTAssertEqual(manifest.verification, "../CONFORMANCE.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: TestVectorLoader.fileURL("algorithm-spec-v1.md").path))
    }

    func testKDFVectors() throws {
        let vectors: [TestVectorLoader.KDFVector] = try TestVectorLoader.load("kdf.json")
        XCTAssertGreaterThanOrEqual(vectors.count, 70)

        for vector in vectors {
            let config = TestVectorLoader.hasherConfig(from: vector.params)
            let key = try PositionalHasher.deriveKey(from: vector.password_utf8, config: config)
            let keyData = key.withUnsafeBytes { Data($0) }
            XCTAssertEqual(
                keyData.map { String(format: "%02x", $0) }.joined(),
                vector.key_hex,
                "KDF mismatch for \(vector.id)"
            )
        }
    }

    func testTokenVectors() throws {
        let vectors: [TestVectorLoader.TokenVector] = try TestVectorLoader.load("tokens.json")
        XCTAssertGreaterThanOrEqual(vectors.count, 90)

        for vector in vectors {
            let config = TestVectorLoader.hasherConfig(from: vector.params)
            XCTAssertEqual(vector.radix, PositionalHasher.alphabet.count)

            let key = try PositionalHasher.deriveKey(from: vector.password_utf8, config: config)
            let keyData = key.withUnsafeBytes { Data($0) }
            XCTAssertEqual(
                keyData.map { String(format: "%02x", $0) }.joined(),
                vector.key_hex,
                "Key mismatch for \(vector.id)"
            )

            let produced = PositionalHasher.token(
                position: vector.position,
                wordIndex: vector.word_index,
                key: key,
                config: config
            )
            XCTAssertEqual(produced, vector.token, "Token mismatch for \(vector.id)")
            XCTAssertTrue(PositionalHasher.isValidTokenFormat(produced, config: config))

            if let expectedWord = vector.word {
                XCTAssertEqual(BIP39Wordlist.words[vector.word_index], expectedWord)
            }

            let payload = Data(vector.payload_utf8.utf8)
            let mac = HMAC<SHA256>.authenticationCode(for: payload, using: key)
            let macHex = mac.map { String(format: "%02x", $0) }.joined()
            XCTAssertEqual(macHex, vector.hmac_sha256_hex, "HMAC mismatch for \(vector.id)")
            XCTAssertEqual(
                mac.prefix(5).map { String(format: "%02x", $0) }.joined(),
                vector.hmac_truncated_hex,
                "Truncated HMAC mismatch for \(vector.id)"
            )
        }
    }

    func testObfuscateVectors() throws {
        let vectors: [TestVectorLoader.ObfuscateVector] = try TestVectorLoader.load("obfuscate.json")
        XCTAssertGreaterThanOrEqual(vectors.count, 80)

        for vector in vectors {
            let config = TestVectorLoader.hasherConfig(from: vector.params)
            let produced = try PositionalHasher.obfuscate(
                words: vector.mnemonic,
                password: vector.password_utf8,
                config: config
            )
            XCTAssertEqual(produced, vector.tokens, "Obfuscate mismatch for \(vector.id)")
            XCTAssertEqual(produced.count, vector.word_count)

            let key = try PositionalHasher.deriveKey(from: vector.password_utf8, config: config)
            let keyHex = key.withUnsafeBytes { Data($0) }.map { String(format: "%02x", $0) }.joined()
            XCTAssertEqual(keyHex, vector.key_hex, "Key mismatch for \(vector.id)")
        }
    }

    func testRecoveryVectors() throws {
        let vectors: [TestVectorLoader.RecoveryVector] = try TestVectorLoader.load("recovery.json")
        XCTAssertGreaterThanOrEqual(vectors.count, 240)

        var cache: DecryptTokenProcessor.Cache?

        for vector in vectors {
            let config = TestVectorLoader.hasherConfig(from: vector.params)
            let configKey = "\(config.version.rawValue)-\(config.pbkdf2Iterations)-\(config.derivedKeyByteCount)"
            let raw = vector.tokens_shuffled.joined(separator: " ")

            let outcome = try DecryptTokenProcessor.process(
                tokens: DecryptTokenProcessor.parseTokens(raw),
                existingSlots: [],
                password: vector.password_utf8,
                phraseLength: vector.word_count,
                config: config,
                configKey: configKey,
                cache: cache
            )
            cache = outcome.cache

            XCTAssertTrue(outcome.complete, "Recovery incomplete for \(vector.id)")
            XCTAssertEqual(outcome.slots, vector.expected_mnemonic, "Recovery mismatch for \(vector.id)")
        }
    }

    func testNormalizeVectors() throws {
        let vectors: [TestVectorLoader.NormalizeVector] = try TestVectorLoader.load("normalize.json")
        XCTAssertGreaterThanOrEqual(vectors.count, 65)
        let config = HasherConfig(version: .v1, pbkdf2Iterations: 100_000, derivedKeyByteCount: 32)

        for vector in vectors {
            let normalized = PositionalHasher.normalizeToken(vector.input)
            XCTAssertEqual(normalized, vector.normalized, "Normalize mismatch for \(vector.id)")
            XCTAssertEqual(
                PositionalHasher.isValidTokenFormat(normalized, config: config),
                vector.valid,
                "Validity mismatch for \(vector.id)"
            )
        }
    }

    func testExportFileVectors() throws {
        let vectors: [TestVectorLoader.ExportVector] = try TestVectorLoader.load("export.json")
        let obfuscate: [TestVectorLoader.ObfuscateVector] = try TestVectorLoader.load("obfuscate.json")
        XCTAssertGreaterThanOrEqual(vectors.count, 12)

        let obfuscateById = Dictionary(uniqueKeysWithValues: obfuscate.map { ($0.id, $0) })

        for vector in vectors {
            let text = try String(contentsOf: TestVectorLoader.fileURL(vector.file), encoding: .utf8)
            let imported = try CodesFileImport.parse(text: text)

            if let expectedVersion = vector.expected_version {
                XCTAssertEqual(imported.version?.rawValue, expectedVersion, "Version mismatch for \(vector.id)")
            } else {
                XCTAssertNil(imported.version, "Expected no version header for \(vector.id)")
            }

            if let expectedWordCount = vector.expected_word_count {
                XCTAssertEqual(imported.wordCount, expectedWordCount, "Word count mismatch for \(vector.id)")
            } else {
                XCTAssertNil(imported.wordCount, "Expected no words header for \(vector.id)")
            }

            if let expectedIterations = vector.expected_iterations {
                XCTAssertEqual(imported.iterations, expectedIterations, "Iterations mismatch for \(vector.id)")
            } else {
                XCTAssertNil(imported.iterations, "Expected no iterations header for \(vector.id)")
            }

            if let expectedKeyBytes = vector.expected_key_bytes {
                XCTAssertEqual(imported.keyBytes, expectedKeyBytes, "Key bytes mismatch for \(vector.id)")
            } else {
                XCTAssertNil(imported.keyBytes, "Expected no keyBytes header for \(vector.id)")
            }

            guard let source = obfuscateById[vector.obfuscate_id] else {
                XCTFail("Missing obfuscate source \(vector.obfuscate_id) for \(vector.id)")
                continue
            }

            let parsedTokens = DecryptTokenProcessor.parseTokens(imported.tokensText)
            XCTAssertEqual(parsedTokens, source.tokens, "Export tokens mismatch for \(vector.id)")
            XCTAssertEqual(parsedTokens.count, source.word_count, "Token count mismatch for \(vector.id)")
        }
    }
}
