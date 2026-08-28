//
//  CodesFileImportTests.swift
//  Bip39ChiperTests
//

import XCTest
@testable import Bip39Chiper

final class CodesFileImportTests: XCTestCase {
    func testParseHeadersAndTokens() throws {
        let text = """
        # version: v1
        # words: 12
        # iterations: 600000
        # keyBytes: 32
        ABCD2345 EFGH6789
        """

        let imported = try CodesFileImport.parse(text: text)
        XCTAssertEqual(imported.version, .v1)
        XCTAssertEqual(imported.wordCount, 12)
        XCTAssertEqual(imported.iterations, 600_000)
        XCTAssertEqual(imported.keyBytes, 32)
        XCTAssertTrue(imported.tokensText.contains("ABCD2345"))
    }

    func testEmptyFileThrows() {
        XCTAssertThrowsError(try CodesFileImport.parse(text: "   ")) { error in
            XCTAssertTrue(error is CodesFileImportError)
        }
    }

    func testHeadersOnlyThrows() {
        XCTAssertThrowsError(try CodesFileImport.parse(text: "# version: v1\n"))
    }
}
