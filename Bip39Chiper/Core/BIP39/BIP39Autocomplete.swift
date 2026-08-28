//
//  BIP39Autocomplete.swift
//  Bip39Chiper
//
//  Prefix search and auto-commit helpers for the English BIP-39 wordlist.
//

import Foundation

enum BIP39Autocomplete {
    static func normalize(_ raw: String) -> String {
        raw.lowercased().filter(\.isLetter)
    }

    static func suggestions(for raw: String, limit: Int = 10) -> [String] {
        let query = normalize(raw)
        guard !query.isEmpty else { return [] }
        var result: [String] = []
        for word in BIP39Wordlist.words where word.hasPrefix(query) {
            result.append(word)
            if result.count >= limit { break }
        }
        return result
    }

    static func matchCount(for raw: String) -> Int {
        let query = normalize(raw)
        guard !query.isEmpty else { return 0 }
        return BIP39Wordlist.words.count { $0.hasPrefix(query) }
    }

    static func uniqueMatch(for raw: String) -> String? {
        let query = normalize(raw)
        guard !query.isEmpty else { return nil }

        var found: String?
        for word in BIP39Wordlist.words where word.hasPrefix(query) {
            if found != nil { return nil }
            found = word
        }
        return found
    }

    /// Shows the list from 4 characters, or earlier when the prefix is still ambiguous.
    static func shouldShowSuggestions(for raw: String) -> Bool {
        let query = normalize(raw)
        guard !query.isEmpty else { return false }
        let matches = suggestions(for: query, limit: 11)
        if matches.isEmpty { return false }
        if matches.count == 1, matches[0] == query { return false }
        return query.count >= 4 || matches.count > 1
    }

    static func tokenizePhrase(_ raw: String) -> [String] {
        raw
            .split { $0.isWhitespace || $0.isNewline || $0 == "," || $0 == ";" }
            .map { normalize(String($0)) }
            .filter { !$0.isEmpty }
    }

    static func resolveWord(_ token: String) -> String? {
        let query = normalize(token)
        guard !query.isEmpty else { return nil }
        if BIP39Wordlist.words.contains(query) {
            return query
        }
        return uniqueMatch(for: query)
    }
}
