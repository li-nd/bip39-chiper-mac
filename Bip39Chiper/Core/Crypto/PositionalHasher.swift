//
//  PositionalHasher.swift
//  Bip39Chiper
//
//  Maps each BIP-39 word to a position-dependent HMAC token (PBKDF2 key + SHA-256 HMAC).
//  Decryption builds a token→(position, word) lookup table once; incoming token order is ignored.
//

import CommonCrypto
import CryptoKit
import Foundation

struct TokenMatch: Equatable, Sendable {
    let position: Int
    let word: String
    let wordIndex: Int
}

enum PositionalHasher {
    static let tokenByteCount = 5

    /// Base32-like alphabet without 0/O, 1/I/L, or U (30 characters, radix 30).
    static let alphabet = Array("23456789ABCDEFGHJKMNPQRSTVWXYZ")
    private static let alphabetSet = Set(alphabet)
    private static let radix = alphabet.count

    private static let wordIndex: [String: Int] = {
        var map: [String: Int] = [:]
        map.reserveCapacity(BIP39Wordlist.words.count)
        for (i, word) in BIP39Wordlist.words.enumerated() {
            map[word] = i
        }
        return map
    }()

    // MARK: - Key derivation

    static func deriveKey(from password: String, config: HasherConfig) throws -> SymmetricKey {
        guard !password.isEmpty else { throw HasherError.emptyPassword }
        guard password.count >= 8 else { throw HasherError.passwordTooShort }

        let keyLength = config.derivedKeyByteCount
        let salt = config.applicationSalt
        var derived = Data(count: keyLength)
        let status: Int32 = derived.withUnsafeMutableBytes { derivedBytes in
            password.withCString { passwordPtr in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordPtr,
                        password.lengthOfBytes(using: .utf8),
                        saltBytes.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        config.pbkdf2Iterations,
                        derivedBytes.bindMemory(to: UInt8.self).baseAddress,
                        keyLength
                    )
                }
            }
        }
        guard status == kCCSuccess else { throw HasherError.keyDerivationFailed }
        return SymmetricKey(data: derived)
    }

    // MARK: - Obfuscate

    static func obfuscate(words: [String], password: String, config: HasherConfig) throws -> [String] {
        let key = try deriveKey(from: password, config: config)
        return try obfuscate(words: words, key: key, config: config)
    }

    static func obfuscate(words: [String], key: SymmetricKey, config: HasherConfig) throws -> [String] {
        guard MnemonicWordCount(rawValue: words.count) != nil else {
            throw HasherError.invalidWordCount(words.count)
        }

        var tokens: [String] = []
        tokens.reserveCapacity(words.count)
        for (offset, word) in words.enumerated() {
            guard let index = wordIndex[word] else {
                throw HasherError.unknownWord(word)
            }
            tokens.append(token(position: offset + 1, wordIndex: index, key: key, config: config))
        }
        return tokens
    }

    // MARK: - Recover

    /// Precomputes every (position, word) → token mapping for O(1) token lookup during decrypt.
    static func buildLookupTable(
        key: SymmetricKey,
        phraseLength: Int,
        config: HasherConfig
    ) throws -> [String: [TokenMatch]] {
        guard MnemonicWordCount(rawValue: phraseLength) != nil else {
            throw HasherError.invalidWordCount(phraseLength)
        }

        var table: [String: [TokenMatch]] = [:]
        table.reserveCapacity(phraseLength * 2048)

        for position in 1...phraseLength {
            for index in 0..<BIP39Wordlist.words.count {
                let t = token(position: position, wordIndex: index, key: key, config: config)
                let match = TokenMatch(
                    position: position,
                    word: BIP39Wordlist.words[index],
                    wordIndex: index
                )
                table[t, default: []].append(match)
            }
        }
        return table
    }

    // MARK: - Token format

    static func normalizeToken(_ raw: String) -> String {
        raw.uppercased().filter { alphabetSet.contains($0) }
    }

    static func isValidTokenFormat(_ raw: String, config: HasherConfig) -> Bool {
        let t = normalizeToken(raw)
        return t.count == config.tokenLength && t.allSatisfy { alphabetSet.contains($0) }
    }

    /// HMAC-SHA256 over "version:position:wordIndex", truncated and base-encoded to `tokenLength` chars.
    static func token(
        position: Int,
        wordIndex: Int,
        key: SymmetricKey,
        config: HasherConfig
    ) -> String {
        let payload = Data("\(config.versionPrefix):\(position):\(wordIndex)".utf8)
        let mac = HMAC<SHA256>.authenticationCode(for: payload, using: key)
        let bytes = Array(mac.prefix(tokenByteCount))
        return encodeFixed(bytes: bytes, length: config.tokenLength)
    }

    static func encodeFixed(bytes: [UInt8], length: Int) -> String {
        precondition(bytes.count <= 8)
        var value: UInt64 = 0
        for byte in bytes {
            value = (value << 8) | UInt64(byte)
        }

        let modulus = powRadix(length)
        value %= modulus

        if value == 0 {
            return String(repeating: String(alphabet[0]), count: length)
        }

        var chars: [Character] = []
        var n = value
        let base = UInt64(radix)
        while n > 0 {
            let rem = Int(n % base)
            precondition(rem >= 0 && rem < alphabet.count)
            chars.append(alphabet[rem])
            n /= base
        }
        while chars.count < length {
            chars.append(alphabet[0])
        }
        return String(chars.reversed())
    }

    private static func powRadix(_ exp: Int) -> UInt64 {
        let base = UInt64(radix)
        var result: UInt64 = 1
        for _ in 0..<exp {
            result *= base
        }
        return result
    }
}

enum HasherError: LocalizedError {
    case emptyPassword
    case passwordTooShort
    case keyDerivationFailed
    case invalidWordCount(Int)
    case unknownWord(String)
    case invalidTokenFormat(String)
    case tokenNotFound(String)
    case ambiguousToken(String, Int)
    case slotConflict(position: Int)
    case passwordMismatch

    var errorDescription: String? {
        switch self {
        case .emptyPassword:
            return L10n.errorEmptyPassword
        case .passwordTooShort:
            return L10n.errorPasswordTooShort
        case .keyDerivationFailed:
            return L10n.errorKeyDerivationFailed
        case .invalidWordCount(let count):
            return L10n.errorInvalidWordCount(count)
        case .unknownWord(let word):
            return L10n.errorUnknownWord(word)
        case .invalidTokenFormat(let token):
            return L10n.errorInvalidTokenFormat(token)
        case .tokenNotFound:
            return L10n.errorTokenNotFound
        case .ambiguousToken:
            return L10n.errorAmbiguousToken
        case .slotConflict(let position):
            return L10n.errorSlotConflict(position)
        case .passwordMismatch:
            return L10n.errorPasswordMismatch
        }
    }
}
