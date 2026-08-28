//
//  L10n.swift
//  Bip39Chiper
//

import Foundation

enum L10n {
    // MARK: - Home
    static var homeTitle: String { tr("home.title") }
    static var homeSubtitle: String { tr("home.subtitle") }
    static var homeEncrypt: String { tr("home.encrypt") }
    static var homeDecrypt: String { tr("home.decrypt") }
    static var homeEncryptSubtitle: String { tr("home.encryptSubtitle") }
    static var homeDecryptSubtitle: String { tr("home.decryptSubtitle") }
    static var homeSettingsHelp: String { tr("home.settingsHelp") }
    static func homeSettingsSummary(_ words: Int, _ iterations: String, _ keyBytes: Int) -> String {
        String(format: tr("home.settingsSummary"), words, iterations, keyBytes)
    }

    // MARK: - Common
    static var next: String { tr("common.next") }
    static var show: String { tr("common.show") }
    static var hide: String { tr("common.hide") }
    static var paste: String { tr("common.paste") }
    static var clear: String { tr("common.clear") }
    static var copy: String { tr("common.copy") }
    static var copied: String { tr("common.copied") }
    static var toFile: String { tr("common.toFile") }
    static var home: String { tr("common.home") }
    static var again: String { tr("common.again") }
    static var apply: String { tr("common.apply") }
    static var cancel: String { tr("common.cancel") }
    static var understood: String { tr("common.understood") }
    static var add: String { tr("common.add") }
    static var password: String { tr("common.password") }
    static var close: String { tr("common.close") }
    static var generate: String { tr("common.generate") }
    static var encrypt: String { tr("common.encrypt") }
    static var validate: String { tr("common.validate") }
    static var progress: String { tr("common.progress") }
    static var poster: String { tr("common.poster") }
    static var busyPassword: String { tr("common.busyPassword") }
    static var busyCheckingToken: String { tr("common.busyCheckingToken") }
    static var toastCopiedClipboard: String { tr("common.toastCopiedClipboard") }

    // MARK: - Steps
    static var stepSource: String { tr("step.source") }
    static var stepPhrase: String { tr("step.phrase") }
    static var stepPassword: String { tr("step.password") }
    static var stepCodes: String { tr("step.codes") }
    static var stepDone: String { tr("step.done") }

    // MARK: - Encrypt
    static var encryptTitleCreate: String { tr("encrypt.titleCreate") }
    static var encryptTitleEnter: String { tr("encrypt.titleEnter") }
    static var encryptSubtitleSource: String { tr("encrypt.subtitleSource") }
    static var encryptSubtitleCreate: String { tr("encrypt.subtitleCreate") }
    static var encryptSubtitleEnter: String { tr("encrypt.subtitleEnter") }
    static var encryptSubtitlePassword: String { tr("encrypt.subtitlePassword") }
    static var encryptSubtitleResult: String { tr("encrypt.subtitleResult") }
    static var encryptSourceNewTitle: String { tr("encrypt.sourceNewTitle") }
    static var encryptSourceNewSubtitle: String { tr("encrypt.sourceNewSubtitle") }
    static var encryptSourceExistingTitle: String { tr("encrypt.sourceExistingTitle") }
    static var encryptSourceExistingSubtitle: String { tr("encrypt.sourceExistingSubtitle") }
    static var phraseLength: String { tr("phrase.length") }
    static var phraseNotCreated: String { tr("phrase.notCreated") }
    static var phraseNotCreatedHint: String { tr("phrase.notCreatedHint") }
    static var shuffleExport: String { tr("encrypt.shuffleExport") }
    static var shuffleExportHint: String { tr("encrypt.shuffleExportHint") }
    static var toastDone: String { tr("encrypt.toastDone") }
    static var toastPhrasePasted: String { tr("encrypt.toastPhrasePasted") }

    // MARK: - Decrypt
    static var decryptSubtitlePhraseLength: String { tr("decrypt.subtitlePhraseLength") }
    static var decryptSubtitlePassword: String { tr("decrypt.subtitlePassword") }
    static var decryptSubtitleCodes: String { tr("decrypt.subtitleCodes") }
    static var decryptSubtitleResult: String { tr("decrypt.subtitleResult") }
    static var decryptPasswordHint: String { tr("decrypt.passwordHint") }
    static var decryptEnterCode: String { tr("decrypt.enterCode") }
    static var decryptPickCodesFile: String { tr("decrypt.pickCodesFile") }
    static var toastPhraseRestored: String { tr("decrypt.toastPhraseRestored") }
    static func wordLengthChip(_ count: Int) -> String {
        String(format: tr("decrypt.wordLength"), count)
    }
    static func decryptWordFound(_ position: Int, _ filled: Int, _ total: Int) -> String {
        String(format: tr("decrypt.toastWordFound"), position, filled, total)
    }
    static func decryptAdded(_ filled: Int, _ total: Int) -> String {
        String(format: tr("decrypt.toastAdded"), filled, total)
    }
    static func decryptAddedBatch(_ placed: Int, _ filled: Int, _ total: Int) -> String {
        String(format: tr("decrypt.toastAddedBatch"), placed, filled, total)
    }

    // MARK: - Seed entry
    static func seedWordProgress(_ index: Int, _ total: Int) -> String {
        String(format: tr("seed.wordProgress"), index, total)
    }
    static var seedAllWordsEntered: String { tr("seed.allWordsEntered") }
    static var seedPlaceholder: String { tr("seed.placeholder") }
    static var seedHint: String { tr("seed.hint") }
    static var seedPhraseComplete: String { tr("seed.phraseComplete") }
    static var seedHelpReplaceClipboard: String { tr("seed.helpReplaceClipboard") }
    static var seedHelpPastePhrase: String { tr("seed.helpPastePhrase") }
    static var seedHelpClearAll: String { tr("seed.helpClearAll") }
    static var seedToastClipboardEmpty: String { tr("seed.toastClipboardEmpty") }
    static func seedToastFillAll(_ count: Int) -> String {
        String(format: tr("seed.toastFillAll"), count)
    }
    static var seedToastValidated: String { tr("seed.toastValidated") }

    // MARK: - Password fields
    static var passwordMinPlaceholder: String { tr("password.minPlaceholder") }
    static var passwordConfirmPlaceholder: String { tr("password.confirmPlaceholder") }
    static var passwordMismatchInline: String { tr("password.mismatchInline") }
    static var passwordStrengthWeak: String { tr("password.strength.weak") }
    static var passwordStrengthFair: String { tr("password.strength.fair") }
    static var passwordStrengthStrong: String { tr("password.strength.strong") }

    // MARK: - Drop zone
    static var dropzoneTitle: String { tr("dropzone.title") }
    static var dropzoneSubtitle: String { tr("dropzone.subtitle") }

    // MARK: - Word search
    static var wordSearchNoMatch: String { tr("wordSearch.noMatch") }
    static var wordSearchEnterHint: String { tr("wordSearch.enterHint") }

    // MARK: - Poster
    static var posterPreview: String { tr("poster.preview") }
    static var posterSavePNG: String { tr("poster.savePNG") }

    // MARK: - Import
    static var importWords: String { tr("import.words") }
    static var importVersion: String { tr("import.version") }
    static var importIterations: String { tr("import.iterations") }
    static var importKeyBytes: String { tr("import.keyBytes") }
    static var importConfirmTitle: String { tr("import.confirmTitle") }
    static var importConfirmMessage: String { tr("import.confirmMessage") }
    static var fileLoaded: String { tr("import.fileLoaded") }
    static var changeFile: String { tr("import.changeFile") }

    // MARK: - Word count
    static var resetWordsTitle: String { tr("wordCount.resetTitle") }
    static var resetWordsMessage: String { tr("wordCount.resetMessage") }
    static var resetWordsConfirm: String { tr("wordCount.resetConfirm") }
    static func wordCountLabel(_ count: MnemonicWordCount) -> String {
        switch count {
        case .twentyOne:
            return tr("wordCount.label21")
        case .twentyFour:
            return tr("wordCount.label24")
        default:
            return String(format: tr("wordCount.label"), count.rawValue)
        }
    }

    // MARK: - Paste / clipboard
    static var toastClipboardEmpty: String { tr("toast.clipboardEmpty") }
    static func toastWrongWordCount(_ count: Int) -> String {
        String(format: tr("toast.wrongWordCount"), count)
    }
    static func toastWordNotInDictionary(_ index: Int, _ token: String) -> String {
        String(format: tr("toast.wordNotInDictionary"), index, token)
    }

    // MARK: - Exit
    static var exitClearTitle: String { tr("exit.clearTitle") }
    static var exitClearConfirm: String { tr("exit.clearConfirm") }
    static var exitClearMessage: String { tr("exit.clearMessage") }

    // MARK: - Onboarding
    static var onboardingTitle: String { tr("onboarding.title") }
    static var onboarding1: String { tr("onboarding.1") }
    static var onboarding2: String { tr("onboarding.2") }
    static var onboarding3: String { tr("onboarding.3") }

    // MARK: - Settings
    static var settingsTitle: String { tr("settings.title") }
    static var settingsSectionFormat: String { tr("settings.sectionFormat") }
    static var settingsSectionDefaultPhrase: String { tr("settings.sectionDefaultPhrase") }
    static var settingsSectionPassword: String { tr("settings.sectionPassword") }
    static var settingsSectionLanguage: String { tr("settings.sectionLanguage") }
    static var settingsLanguage: String { tr("settings.language") }
    static var settingsLanguageSystem: String { tr("settings.languageSystem") }
    static var settingsTabGeneral: String { tr("settings.tabGeneral") }
    static var settingsTabEncryption: String { tr("settings.tabEncryption") }
    static var settingsSectionHelp: String { tr("settings.sectionHelp") }
    static var settingsShowOnboarding: String { tr("settings.showOnboarding") }
    static var settingsVersion: String { tr("settings.version") }
    static var settingsDefaultPhraseLength: String { tr("settings.defaultPhraseLength") }
    static var settingsCompatWarning: String { tr("settings.compat") }
    static var settingsIterations: String { tr("settings.iterations") }
    static var settingsKeySize: String { tr("settings.keySize") }
    static var settingsIterationsHint: String { tr("settings.iterationsHint") }

    // MARK: - Accessibility
    static func a11yHiddenWord(_ position: Int) -> String {
        String(format: tr("a11y.hiddenWord"), position)
    }
    static func a11yProgress(_ filled: Int, _ total: Int) -> String {
        String(format: tr("a11y.progress"), filled, total)
    }
    static func a11yStepNamed(_ name: String, _ current: Int, _ total: Int) -> String {
        String(format: tr("a11y.stepNamed"), name, current, total)
    }
    static func a11yStepGeneric(_ current: Int, _ total: Int) -> String {
        String(format: tr("a11y.stepGeneric"), current, total)
    }

    // MARK: - Hasher errors
    static var errorEmptyPassword: String { tr("error.hasher.emptyPassword") }
    static var errorPasswordTooShort: String { tr("error.hasher.passwordTooShort") }
    static var errorKeyDerivationFailed: String { tr("error.hasher.keyDerivationFailed") }
    static func errorInvalidWordCount(_ count: Int) -> String {
        String(format: tr("error.hasher.invalidWordCount"), count)
    }
    static func errorUnknownWord(_ word: String) -> String {
        String(format: tr("error.hasher.unknownWord"), word)
    }
    static func errorInvalidTokenFormat(_ token: String) -> String {
        String(format: tr("error.hasher.invalidTokenFormat"), token)
    }
    static var errorTokenNotFound: String { tr("error.hasher.tokenNotFound") }
    static var errorAmbiguousToken: String { tr("error.hasher.ambiguousToken") }
    static func errorSlotConflict(_ position: Int) -> String {
        String(format: tr("error.hasher.slotConflict"), position)
    }
    static var errorPasswordMismatch: String { tr("error.hasher.passwordMismatch") }

    // MARK: - BIP39 errors
    static var errorRandomGenerationFailed: String { tr("error.bip39.randomGenerationFailed") }
    static var errorInvalidEntropyLength: String { tr("error.bip39.invalidEntropyLength") }
    static var errorWordlistCorrupted: String { tr("error.bip39.wordlistCorrupted") }
    static func errorInvalidWordBIP39(_ word: String) -> String {
        String(format: tr("error.bip39.invalidWord"), word)
    }
    static var errorInvalidChecksum: String { tr("error.bip39.invalidChecksum") }

    // MARK: - Import errors
    static var errorImportUnreadable: String { tr("error.import.unreadable") }
    static var errorImportEmpty: String { tr("error.import.empty") }
    static var errorImportNoTokens: String { tr("error.import.noTokens") }

    // MARK: - Menu & About
    static func menuAbout(_ appName: String = "Bip39Chiper") -> String {
        String(format: tr("menu.about"), appName)
    }

    static var menuNavigate: String { tr("menu.navigate") }
    static var aboutAuthor: String { tr("about.author") }
    static func aboutCopyright(_ year: Int) -> String {
        String(format: tr("about.copyright"), String(year) as CVarArg)
    }
    static var aboutTagline: String { tr("about.tagline") }
    static var aboutOffline: String { tr("about.offline") }

    private static let missingSentinel = "\u{0001}"

    /// Uses a sentinel value to detect missing keys, then loads from the bundled English strings.
    private static func tr(_ key: String) -> String {
        let bundle = MainActor.assumeIsolated {
            AppSettings.current?.localizationBundle ?? .main
        }
        let localized = NSLocalizedString(
            key,
            tableName: nil,
            bundle: bundle,
            value: missingSentinel,
            comment: ""
        )
        if localized != missingSentinel {
            return localized
        }
        return NSLocalizedString(
            key,
            tableName: nil,
            bundle: AppLanguage.englishFallbackBundle,
            value: key,
            comment: ""
        )
    }
}
