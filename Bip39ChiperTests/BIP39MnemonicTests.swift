//
//  BIP39MnemonicTests.swift
//  Bip39ChiperTests
//

import XCTest
@testable import Bip39Chiper

final class BIP39MnemonicTests: XCTestCase {
    func testGenerateTwelveWordsValidates() throws {
        let words = try BIP39Mnemonic.generate(wordCount: .twelve)
        XCTAssertEqual(words.count, 12)
        XCTAssertNoThrow(try BIP39Mnemonic.validate(words))
    }

    func testGenerateTwentyFourWordsValidates() throws {
        let words = try BIP39Mnemonic.generate(wordCount: .twentyFour)
        XCTAssertEqual(words.count, 24)
        XCTAssertNoThrow(try BIP39Mnemonic.validate(words))
    }

    func testInvalidChecksumRejected() {
        var words = try! BIP39Mnemonic.generate(wordCount: .twelve)
        words[0] = words[0] == "abandon" ? "ability" : "abandon"
        XCTAssertThrowsError(try BIP39Mnemonic.validate(words))
    }

    func testWordCountEntropyBytes() {
        XCTAssertEqual(MnemonicWordCount.twelve.entropyByteCount, 16)
        XCTAssertEqual(MnemonicWordCount.twentyFour.entropyByteCount, 32)
    }
}
