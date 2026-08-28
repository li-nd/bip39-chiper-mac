//
//  CodesFileImport.swift
//  Bip39Chiper
//
//  Parses token export files: `# key: value` headers plus a whitespace-separated token line.
//

import Foundation

struct ImportedCodesFile: Equatable {
    var version: CipherFormatVersion?
    var wordCount: Int?
    var iterations: Int?
    var keyBytes: Int?
    var tokensText: String
}

enum CodesFileImportError: LocalizedError {
    case unreadable
    case empty
    case noTokens

    var errorDescription: String? {
        switch self {
        case .unreadable: return L10n.errorImportUnreadable
        case .empty: return L10n.errorImportEmpty
        case .noTokens: return L10n.errorImportNoTokens
        }
    }
}

struct ImportSettingsDiff: Equatable {
    struct Change: Equatable {
        let label: String
        let from: String
        let to: String
    }

    var changes: [Change]

    var hasChanges: Bool { !changes.isEmpty }

    var summaryLine: String {
        changes.map { "\($0.label): \($0.to)" }.joined(separator: " · ")
    }

    static func compare(imported: ImportedCodesFile, settings: AppSettings) -> ImportSettingsDiff {
        var changes: [Change] = []
        if let count = imported.wordCount, count != settings.defaultWordCount.rawValue {
            changes.append(.init(label: L10n.importWords, from: "\(settings.defaultWordCount.rawValue)", to: "\(count)"))
        }
        if let version = imported.version, version != settings.formatVersion {
            changes.append(.init(label: L10n.importVersion, from: settings.formatVersion.displayName, to: version.displayName))
        }
        if let iterations = imported.iterations, iterations != settings.pbkdf2Iterations {
            changes.append(.init(label: L10n.importIterations, from: formatNumber(settings.pbkdf2Iterations), to: formatNumber(iterations)))
        }
        if let keyBytes = imported.keyBytes, keyBytes != settings.derivedKeyByteCount {
            changes.append(.init(label: L10n.importKeyBytes, from: "\(settings.derivedKeyByteCount)", to: "\(keyBytes)"))
        }
        return ImportSettingsDiff(changes: changes)
    }

    private static func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

enum CodesFileImport {
    static func parse(text: String) throws -> ImportedCodesFile {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { throw CodesFileImportError.empty }

        var version: CipherFormatVersion?
        var wordCount: Int?
        var iterations: Int?
        var keyBytes: Int?
        var tokenLines: [String] = []

        for line in text.split(whereSeparator: \.isNewline).map(String.init) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            if trimmed.hasPrefix("#") {
                let body = trimmed
                    .drop(while: { $0 == "#" || $0.isWhitespace })
                    .trimmingCharacters(in: .whitespaces)
                guard let colon = body.firstIndex(of: ":") else { continue }
                let key = body[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
                let value = body[body.index(after: colon)...]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: "\u{00a0}", with: "")

                switch key {
                case "version":
                    version = CipherFormatVersion(rawValue: value.lowercased())
                case "words":
                    wordCount = Int(value)
                case "iterations":
                    iterations = Int(value)
                case "keybytes":
                    keyBytes = Int(value)
                default:
                    break
                }
                continue
            }

            tokenLines.append(trimmed)
        }

        let tokensText = tokenLines.joined(separator: " ")
        let tokenParts = tokensText
            .uppercased()
            .split { $0.isWhitespace || $0 == "," || $0 == ";" }
            .filter { !$0.isEmpty }

        guard !tokenParts.isEmpty else { throw CodesFileImportError.noTokens }

        return ImportedCodesFile(
            version: version,
            wordCount: wordCount,
            iterations: iterations,
            keyBytes: keyBytes,
            tokensText: tokensText
        )
    }

    static func parse(url: URL) throws -> ImportedCodesFile {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw CodesFileImportError.unreadable
        }
        guard let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .utf16) else {
            throw CodesFileImportError.unreadable
        }
        return try parse(text: text)
    }
}
