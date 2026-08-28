//
//  DecryptTokenProcessorTests.swift
//  Bip39ChiperTests
//

import XCTest
@testable import Bip39Chiper

final class DecryptTokenProcessorTests: XCTestCase {
    private let config = HasherConfig(
        version: .v1,
        pbkdf2Iterations: 100_000,
        derivedKeyByteCount: 32
    )
    private let configKey = "v1-100000-32"

    func testParseTokensSplitsOnWhitespaceAndCommas() {
        let parts = DecryptTokenProcessor.parseTokens("abc def, ghi;\njkl")
        XCTAssertEqual(parts, ["ABC", "DEF", "GHI", "JKL"])
    }

    func testFullRoundtripThroughProcessor() throws {
        let words = try BIP39Mnemonic.generate(wordCount: .twelve)
        let password = "testpassword99"
        let tokens = try PositionalHasher.obfuscate(words: words, password: password, config: config)

        var slots = Array(repeating: "", count: 12)
        var cache: DecryptTokenProcessor.Cache?

        for token in tokens {
            let outcome = try DecryptTokenProcessor.process(
                tokens: [token],
                existingSlots: slots,
                password: password,
                phraseLength: 12,
                config: config,
                configKey: configKey,
                cache: cache
            )
            slots = outcome.slots
            cache = outcome.cache
        }

        XCTAssertTrue(outcomeComplete(slots))
        XCTAssertEqual(slots, words)
    }

    func testReusesCacheWhenPasswordUnchanged() throws {
        let words = try BIP39Mnemonic.generate(wordCount: .twelve)
        let password = "testpassword99"
        let tokens = try PositionalHasher.obfuscate(words: words, password: password, config: config)

        let first = try DecryptTokenProcessor.process(
            tokens: [tokens[0]],
            existingSlots: Array(repeating: "", count: 12),
            password: password,
            phraseLength: 12,
            config: config,
            configKey: configKey,
            cache: nil
        )

        let second = try DecryptTokenProcessor.process(
            tokens: [tokens[1]],
            existingSlots: first.slots,
            password: password,
            phraseLength: 12,
            config: config,
            configKey: configKey,
            cache: first.cache
        )

        XCTAssertEqual(second.cache.keyData, first.cache.keyData)
        XCTAssertEqual(second.filledCount, 2)
    }

    private func outcomeComplete(_ slots: [String]) -> Bool {
        slots.allSatisfy { !$0.isEmpty }
    }
}
