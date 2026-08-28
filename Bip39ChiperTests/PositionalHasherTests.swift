//
//  PositionalHasherTests.swift
//  Bip39ChiperTests
//

import XCTest
@testable import Bip39Chiper

final class PositionalHasherTests: XCTestCase {
    private let config = HasherConfig(
        version: .v1,
        pbkdf2Iterations: 100_000,
        derivedKeyByteCount: 32
    )

    func testTokenFormatIsStableForSameInputs() throws {
        let key = try PositionalHasher.deriveKey(from: "testpassword", config: config)
        let a = PositionalHasher.token(position: 3, wordIndex: 42, key: key, config: config)
        let b = PositionalHasher.token(position: 3, wordIndex: 42, key: key, config: config)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.count, config.tokenLength)
        XCTAssertTrue(PositionalHasher.isValidTokenFormat(a, config: config))
    }

    func testObfuscateProducesOneTokenPerWord() throws {
        let words = Array(BIP39Wordlist.words.prefix(12))
        let tokens = try PositionalHasher.obfuscate(words: words, password: "testpassword", config: config)
        XCTAssertEqual(tokens.count, words.count)
        XCTAssertTrue(tokens.allSatisfy { PositionalHasher.isValidTokenFormat($0, config: config) })
    }

    func testLookupTableMapsTokensBackToWords() throws {
        let words = try BIP39Mnemonic.generate(wordCount: .twelve)
        let password = "securepassphrase"
        let key = try PositionalHasher.deriveKey(from: password, config: config)
        let table = try PositionalHasher.buildLookupTable(key: key, phraseLength: 12, config: config)
        let tokens = try PositionalHasher.obfuscate(words: words, key: key, config: config)

        var recovered = Array(repeating: "", count: 12)
        for token in tokens {
            guard let matches = table[token], let match = matches.first else {
                XCTFail("Missing token \(token)")
                return
            }
            recovered[match.position - 1] = match.word
        }

        XCTAssertEqual(recovered, words)
    }
}
