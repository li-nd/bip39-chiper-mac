//
//  DecryptTokenProcessor.swift
//  Bip39Chiper
//

import CryptoKit
import Foundation

/// Pure token-matching logic for the decrypt flow (testable off the main thread).
enum DecryptTokenProcessor {
    struct Cache: Sendable, Equatable {
        let password: String
        let phraseLength: Int
        let configKey: String
        let keyData: Data
        let lookupTable: [String: [TokenMatch]]
    }

    struct Outcome: Sendable, Equatable {
        let slots: [String]
        let placed: Int
        let lastFilledIndex: Int?
        let lastToken: String?
        let complete: Bool
        let filledCount: Int
        let cache: Cache
    }

    static func parseTokens(_ raw: String) -> [String] {
        raw
            .uppercased()
            .split { $0.isWhitespace || $0.isNewline || $0 == "," || $0 == ";" }
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    static func process(
        tokens: [String],
        existingSlots: [String],
        password: String,
        phraseLength: Int,
        config: HasherConfig,
        configKey: String,
        cache: Cache?
    ) throws -> Outcome {
        guard password.count >= 8 else { throw HasherError.passwordTooShort }

        let key: SymmetricKey
        let table: [String: [TokenMatch]]
        if let cache,
           cache.password == password,
           cache.phraseLength == phraseLength,
           cache.configKey == configKey,
           !cache.lookupTable.isEmpty {
            key = SymmetricKey(data: cache.keyData)
            table = cache.lookupTable
        } else {
            key = try PositionalHasher.deriveKey(from: password, config: config)
            table = try PositionalHasher.buildLookupTable(
                key: key,
                phraseLength: phraseLength,
                config: config
            )
        }

        var next = existingSlots.count == phraseLength
            ? existingSlots
            : Array(repeating: "", count: phraseLength)
        var placed = 0
        var lastFilledIndex: Int?
        var lastToken: String?

        for part in tokens {
            let normalized = PositionalHasher.normalizeToken(part)
            guard PositionalHasher.isValidTokenFormat(normalized, config: config) else {
                throw HasherError.invalidTokenFormat(part)
            }
            guard let matches = table[normalized], !matches.isEmpty else {
                throw HasherError.tokenNotFound(normalized)
            }
            let free = matches.filter { next[$0.position - 1].isEmpty }
            let match: TokenMatch
            if free.count == 1 {
                match = free[0]
            } else if matches.count == 1 {
                match = matches[0]
            } else {
                throw HasherError.ambiguousToken(normalized, matches.count)
            }
            let idx = match.position - 1
            if !next[idx].isEmpty, next[idx] != match.word {
                throw HasherError.slotConflict(position: match.position)
            }
            next[idx] = match.word
            lastFilledIndex = idx
            lastToken = normalized
            placed += 1
        }

        let complete = next.allSatisfy { !$0.isEmpty }
        if complete {
            try BIP39Mnemonic.validate(next)
        }

        let keyData = key.withUnsafeBytes { Data($0) }
        let filledCount = next.filter { !$0.isEmpty }.count
        let newCache = Cache(
            password: password,
            phraseLength: phraseLength,
            configKey: configKey,
            keyData: keyData,
            lookupTable: table
        )

        return Outcome(
            slots: next,
            placed: placed,
            lastFilledIndex: lastFilledIndex,
            lastToken: lastToken,
            complete: complete,
            filledCount: filledCount,
            cache: newCache
        )
    }
}

/// Holds PBKDF2 / lookup-table cache for an in-progress decrypt session.
@MainActor
final class DecryptSession {
    private var cache: DecryptTokenProcessor.Cache?

    func invalidateCache() {
        cache = nil
    }

    var hasCache: Bool { cache != nil }

    func process(
        raw: String,
        password: String,
        phraseLength: Int,
        existingSlots: [String],
        config: HasherConfig,
        configKey: String
    ) async throws -> DecryptTokenProcessor.Outcome {
        let tokens = DecryptTokenProcessor.parseTokens(raw)
        guard !tokens.isEmpty else {
            throw DecryptSessionError.emptyInput
        }

        let snapshot = cache
        let outcome = try await Task.detached(priority: .userInitiated) {
            try DecryptTokenProcessor.process(
                tokens: tokens,
                existingSlots: existingSlots,
                password: password,
                phraseLength: phraseLength,
                config: config,
                configKey: configKey,
                cache: snapshot
            )
        }.value

        cache = outcome.cache
        return outcome
    }
}

enum DecryptSessionError: LocalizedError {
    case emptyInput

    var errorDescription: String? {
        switch self {
        case .emptyInput: return nil
        }
    }
}
