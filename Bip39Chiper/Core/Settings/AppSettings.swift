//
//  AppSettings.swift
//  Bip39Chiper
//

import Combine
import Foundation
import SwiftUI

/// Cipher format version; drives salt, token length, and HMAC payload prefix.
enum CipherFormatVersion: String, CaseIterable, Identifiable, Codable, Sendable {
    case v1

    var id: String { rawValue }

    var displayName: String { "v1" }

    var payloadPrefix: String { rawValue }

    var applicationSalt: Data {
        Data("Bip39Chiper.\(rawValue).positional-hasher".utf8)
    }

    var tokenLength: Int {
        switch self {
        case .v1: return 8
        }
    }
}

/// Immutable settings passed to background crypto work.
struct HasherConfig: Sendable {
    let version: CipherFormatVersion
    let pbkdf2Iterations: UInt32
    let derivedKeyByteCount: Int

    var versionPrefix: String { version.payloadPrefix }
    var applicationSalt: Data { version.applicationSalt }
    var tokenLength: Int { version.tokenLength }

    func exportSummaryLines(wordCount: Int) -> [String] {
        [
            "version: \(version.displayName)",
            "words: \(wordCount)",
            "iterations: \(pbkdf2Iterations)",
            "keyBytes: \(derivedKeyByteCount)"
        ]
    }

    func exportSummaryInline(wordCount: Int) -> String {
        "\(version.displayName) · \(wordCount) words · \(pbkdf2Iterations) iter · key \(derivedKeyByteCount)B"
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var formatVersion: CipherFormatVersion {
        didSet { UserDefaults.standard.set(formatVersion.rawValue, forKey: Keys.version) }
    }

    @Published var defaultWordCount: MnemonicWordCount {
        didSet { UserDefaults.standard.set(defaultWordCount.rawValue, forKey: Keys.wordCount) }
    }

    @Published var pbkdf2Iterations: Int {
        didSet { UserDefaults.standard.set(pbkdf2Iterations, forKey: Keys.iterations) }
    }

    @Published var derivedKeyByteCount: Int {
        didSet { UserDefaults.standard.set(derivedKeyByteCount, forKey: Keys.keyBytes) }
    }

    @Published var hasSeenOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasSeenOnboarding, forKey: Keys.onboarding) }
    }

    @Published var shuffleOnExport: Bool {
        didSet { UserDefaults.standard.set(shuffleOnExport, forKey: Keys.shuffleOnExport) }
    }

    @Published var appLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(appLanguage.rawValue, forKey: Keys.language)
            localizationRevision &+= 1
        }
    }

    @Published private(set) var localizationRevision = 0

    static private(set) weak var current: AppSettings?

    static let iterationPresets: [Int] = [
        210_000,
        600_000,
        1_000_000,
        2_000_000,
        3_000_000,
        5_000_000,
        10_000_000,
        15_000_000,
        20_000_000,
        30_000_000,
        50_000_000
    ]
    static let minIterations = 100_000
    static let maxIterations = 50_000_000
    static let keyLengthOptions = [16, 32, 64]

    private enum Keys {
        static let version = "cipherFormatVersion"
        static let wordCount = "defaultWordCount"
        static let iterations = "pbkdf2Iterations"
        static let keyBytes = "derivedKeyByteCount"
        static let onboarding = "hasSeenOnboarding"
        static let shuffleOnExport = "shuffleOnExport"
        static let language = "appLanguage"
    }

    var localizationBundle: Bundle {
        AppLanguage.bundle(for: appLanguage)
    }

    var activeLocale: Locale {
        appLanguage.activeLocale
    }

    var layoutDirection: LayoutDirection {
        appLanguage.layoutDirection
    }

    init() {
        let defaults = UserDefaults.standard
        hasSeenOnboarding = defaults.bool(forKey: Keys.onboarding)
        if defaults.object(forKey: Keys.shuffleOnExport) == nil {
            shuffleOnExport = true
        } else {
            shuffleOnExport = defaults.bool(forKey: Keys.shuffleOnExport)
        }
        let languageRaw = defaults.string(forKey: Keys.language) ?? AppLanguage.system.rawValue
        appLanguage = AppLanguage(rawValue: languageRaw) ?? .system
        let versionRaw = defaults.string(forKey: Keys.version) ?? CipherFormatVersion.v1.rawValue
        formatVersion = CipherFormatVersion(rawValue: versionRaw) ?? .v1

        let words = defaults.object(forKey: Keys.wordCount) as? Int ?? 24
        defaultWordCount = MnemonicWordCount(rawValue: words) ?? .twentyFour

        let iterations = defaults.object(forKey: Keys.iterations) as? Int ?? 600_000
        if Self.iterationPresets.contains(iterations) {
            pbkdf2Iterations = iterations
        } else {
            pbkdf2Iterations = Self.nearestPreset(to: iterations)
        }

        let keyBytes = defaults.object(forKey: Keys.keyBytes) as? Int ?? 32
        derivedKeyByteCount = Self.keyLengthOptions.contains(keyBytes) ? keyBytes : 32

        Self.current = self
    }

    var hasherConfig: HasherConfig {
        let iterations = UInt32(clamping: pbkdf2Iterations, min: Self.minIterations, max: Self.maxIterations)
        let keyLen = Self.keyLengthOptions.contains(derivedKeyByteCount) ? derivedKeyByteCount : 32
        return HasherConfig(
            version: formatVersion,
            pbkdf2Iterations: iterations,
            derivedKeyByteCount: keyLen
        )
    }

    func clampIterations() {
        if !Self.iterationPresets.contains(pbkdf2Iterations) {
            pbkdf2Iterations = Self.nearestPreset(to: pbkdf2Iterations)
        }
    }

    /// Applies imported crypto settings verbatim (iterations are not snapped to UI presets).
    func applyFromImportedFile(version: CipherFormatVersion?, iterations: Int?, keyBytes: Int?) {
        if let version {
            formatVersion = version
        }
        if let iterations {
            pbkdf2Iterations = Swift.min(Swift.max(iterations, Self.minIterations), Self.maxIterations)
        }
        if let keyBytes, Self.keyLengthOptions.contains(keyBytes) {
            derivedKeyByteCount = keyBytes
        }
    }

    static func nearestPreset(to value: Int) -> Int {
        let clamped = Swift.min(Swift.max(value, minIterations), maxIterations)
        return iterationPresets.min(by: { abs($0 - clamped) < abs($1 - clamped) }) ?? 600_000
    }
}

private extension UInt32 {
    init(clamping value: Int, min: Int, max: Int) {
        let clamped = Swift.min(Swift.max(value, min), max)
        self = UInt32(clamped)
    }
}
