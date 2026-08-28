//
//  TestVectorLoader.swift
//  Bip39ChiperTests
//

import Foundation
@testable import Bip39Chiper

enum TestVectorLoader {
    enum Error: Swift.Error, LocalizedError {
        case missingVectors(path: String)

        var errorDescription: String? {
            switch self {
            case .missingVectors(let path):
                return """
                Test vectors not found at \(path).
                Initialize the Git submodule: git submodule update --init --recursive
                Or set BIP39_CHIPER_TEST_VECTORS_V1 to a directory containing manifest.json.
                See docs/test-vectors.md for details.
                """
            }
        }
    }

    struct Manifest: Decodable {
        let format_version: String
        let radix: Int
        let alphabet: String
        let spec: String?
        let verification: String?
        let files: [String: String]
    }

    struct Params: Decodable {
        let version: String
        let salt_utf8: String
        let iterations: Int
        let key_bytes: Int
    }

    struct KDFVector: Decodable {
        let id: String
        let password_utf8: String
        let params: Params
        let key_hex: String
    }

    struct TokenVector: Decodable {
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
        let token: String
        let radix: Int
    }

    struct ObfuscateVector: Decodable {
        let id: String
        let password_utf8: String
        let params: Params
        let word_count: Int
        let mnemonic: [String]
        let tokens: [String]
        let key_hex: String
    }

    struct RecoveryVector: Decodable {
        let id: String
        let obfuscate_id: String
        let password_utf8: String
        let params: Params
        let word_count: Int
        let tokens_shuffled: [String]
        let expected_mnemonic: [String]
    }

    struct NormalizeVector: Decodable {
        let id: String
        let input: String
        let normalized: String
        let valid: Bool
    }

    struct ExportVector: Decodable {
        let id: String
        let obfuscate_id: String
        let file: String
        let expected_version: String?
        let expected_word_count: Int?
        let expected_iterations: Int?
        let expected_key_bytes: Int?
        let notes: String?
    }

    static let v1Directory: URL = {
        if let override = ProcessInfo.processInfo.environment["BIP39_CHIPER_TEST_VECTORS_V1"],
           !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("test-vectors/v1", isDirectory: true)
    }()

    static func load<T: Decodable>(_ name: String, as type: T.Type = T.self) throws -> T {
        let url = v1Directory.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw Error.missingVectors(path: v1Directory.path)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    static func fileURL(_ relativePath: String) -> URL {
        v1Directory.appendingPathComponent(relativePath)
    }

    static func hasherConfig(from params: Params) -> HasherConfig {
        HasherConfig(
            version: CipherFormatVersion(rawValue: params.version) ?? .v1,
            pbkdf2Iterations: UInt32(clamping: params.iterations, min: 100_000, max: 50_000_000),
            derivedKeyByteCount: params.key_bytes
        )
    }

    static func dataFromHex(_ hex: String) -> Data {
        var data = Data()
        data.reserveCapacity(hex.count / 2)
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2, limitedBy: hex.endIndex) ?? hex.endIndex
            let byte = UInt8(hex[index..<next], radix: 16) ?? 0
            data.append(byte)
            index = next
        }
        return data
    }
}

private extension UInt32 {
    init(clamping value: Int, min: Int, max: Int) {
        let clamped = Swift.min(Swift.max(value, min), max)
        self = UInt32(clamped)
    }
}
