//
//  AppLanguage.swift
//  Bip39Chiper
//

import SwiftUI

/// In-app language override. `.system` follows macOS preferred languages.
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case en
    case ru
    case de
    case es
    case fr
    case it
    case nl
    case pl
    case cs
    case ro
    case uk
    case tr
    case vi
    case id
    case ja
    case ko
    case ar
    case he
    case fa
    case ptBR = "pt-BR"
    case zhHans = "zh-Hans"

    var id: String { rawValue }

    /// Bundled `.lproj` folder name, or `nil` for system default.
    var lprojName: String? {
        self == .system ? nil : rawValue
    }

    var activeLocale: Locale {
        switch self {
        case .system:
            if let code = Bundle.main.preferredLocalizations.first {
                return Locale(identifier: code)
            }
            return .current
        default:
            return Locale(identifier: rawValue)
        }
    }

    var layoutDirection: LayoutDirection {
        let languageCode: String
        switch self {
        case .system:
            languageCode = Bundle.main.preferredLocalizations.first
                ?? Locale.current.language.languageCode?.identifier
                ?? "en"
        default:
            languageCode = rawValue.components(separatedBy: "-").first ?? rawValue
        }
        return Self.rtlLanguageCodes.contains(languageCode) ? .rightToLeft : .leftToRight
    }

    /// Endonym shown in the language picker (always in the target language).
    func pickerLabel(systemOptionTitle: String) -> String {
        switch self {
        case .system:
            return systemOptionTitle
        default:
            let locale = Locale(identifier: rawValue)
            if let name = locale.localizedString(forIdentifier: rawValue), !name.isEmpty {
                return name.prefix(1).uppercased() + name.dropFirst()
            }
            return rawValue
        }
    }

    static func bundle(for language: AppLanguage) -> Bundle {
        guard let name = language.lprojName else {
            return .main
        }
        if let path = Bundle.main.path(forResource: name, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return englishFallbackBundle
    }

    static let englishFallbackBundle: Bundle = {
        if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }()

    static let pickerLanguages: [AppLanguage] = allCases.filter { $0 != .system }

    private static let rtlLanguageCodes: Set<String> = ["ar", "he", "fa"]
}
