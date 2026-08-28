//
//  DecryptFlowView.swift
//  Bip39Chiper
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

private enum DecryptStep: Equatable {
    case phraseLength
    case password
    case codes
    case result

    var indicatorIndex: Int {
        switch self {
        case .phraseLength: return 0
        case .password: return 1
        case .codes: return 2
        case .result: return 3
        }
    }
}

struct DecryptFlowView: View {
    let onExit: () -> Void

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var toast: ToastCenter

    @State private var step: DecryptStep = .phraseLength
    @State private var wordCount: MnemonicWordCount = .twentyFour
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var singleToken = ""
    @State private var slots: [String] = Array(repeating: "", count: 24)
    @State private var isWorking = false
    @State private var didCopy = false
    @State private var wordsHidden = true
    @State private var suppressWordCountReset = false
    @State private var fileImported = false
    @State private var pendingImport: ImportedCodesFile?
    @State private var showImportConfirm = false
    @State private var showExitConfirm = false
    @State private var highlightedIndex: Int?
    @FocusState private var tokenFieldFocused: Bool
    @State private var session = DecryptSession()
    @State private var isDerivingKey = false

    private var filled: Int { slots.filter { !$0.isEmpty }.count }
    private var config: HasherConfig { settings.hasherConfig }

    private var configCacheKey: String {
        "\(config.version.rawValue)-\(config.pbkdf2Iterations)-\(config.derivedKeyByteCount)"
    }

    private let stepLabels = [L10n.stepPhrase, L10n.stepPassword, L10n.stepCodes, L10n.stepDone]

    var body: some View {
        FlowChrome(
            title: stepTitle,
            subtitle: stepSubtitle,
            stepIndex: step.indicatorIndex,
            stepLabels: stepLabels,
            onBack: backAction
        ) {
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    switch step {
                    case .phraseLength: phraseLengthStep
                    case .password: passwordStep
                    case .codes: codesStep
                    case .result: resultStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(step)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                footer
                    .padding(.top, 14)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: step)
        .onAppear {
            wordCount = settings.defaultWordCount
            slots = Array(repeating: "", count: wordCount.rawValue)
        }
        .onChange(of: step) { _, newStep in
            switch newStep {
            case .codes:
                FocusHelper.afterTransition { tokenFieldFocused = true }
            default:
                break
            }
        }
        .onChange(of: wordCount) { _, newValue in
            if suppressWordCountReset {
                suppressWordCountReset = false
                return
            }
            slots = Array(repeating: "", count: newValue.rawValue)
            session.invalidateCache()
        }
        .onChange(of: password) { _, _ in
            session.invalidateCache()
        }
        .sheet(isPresented: $showImportConfirm) {
            if let imported = pendingImport {
                ImportConfirmSheet(
                    diff: ImportSettingsDiff.compare(imported: imported, settings: settings),
                    onApply: {
                        pendingImport = nil
                        showImportConfirm = false
                        applyAndProcess(imported)
                    },
                    onCancel: {
                        pendingImport = nil
                        showImportConfirm = false
                    }
                )
            }
        }
        .confirmationDialog(L10n.exitClearTitle, isPresented: $showExitConfirm, titleVisibility: .visible) {
            Button(L10n.exitClearConfirm, role: .destructive) {
                clearSensitiveData()
                onExit()
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.exitClearMessage)
        }
    }

    private var stepTitle: String {
        switch step {
        case .phraseLength: return L10n.stepPhrase
        case .password: return L10n.stepPassword
        case .codes: return L10n.stepCodes
        case .result: return L10n.stepDone
        }
    }

    private var stepSubtitle: String {
        switch step {
        case .phraseLength: return L10n.decryptSubtitlePhraseLength
        case .password: return L10n.decryptSubtitlePassword
        case .codes: return L10n.decryptSubtitleCodes
        case .result: return L10n.decryptSubtitleResult
        }
    }

    private var backAction: (() -> Void)? {
        switch step {
        case .phraseLength:
            return requestExit
        case .password:
            return {
                withAnimation { step = .phraseLength }
            }
        case .codes:
            return {
                withAnimation { step = .password }
            }
        case .result:
            return requestExit
        }
    }

    private var phraseLengthStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.phraseLength)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                WordCountPicker(selection: $wordCount)
            }
            Spacer(minLength: 0)
        }
    }

    private var passwordStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            PasswordFields(
                password: $password,
                confirm: $passwordConfirm,
                requireConfirm: false,
                showStrength: true,
                autoFocus: true
            )

            Text(L10n.decryptPasswordHint)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)

            Spacer(minLength: 0)
        }
    }

    private var codesStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(L10n.progress)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text("\(filled)/\(wordCount.rawValue)")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(AppTheme.accent)
                        .contentTransition(.numericText())
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.a11yProgress(filled, wordCount.rawValue))
                ProgressView(value: Double(filled), total: Double(max(wordCount.rawValue, 1)))
                    .tint(AppTheme.accent)
            }
            .padding(12)
            .appButtonChrome(fill: AppTheme.wordCell, cornerRadius: 10)

            if fileImported {
                CollapsedFileImportRow {
                    fileImported = false
                }
            } else {
                CodesFileDropZone(
                    enabled: !isWorking && password.count >= 8,
                    onPickFile: pickCodesFile,
                    onDropURL: importCodesFile(from:)
                )
            }

            HStack(spacing: 10) {
                TextField(L10n.decryptEnterCode, text: $singleToken)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .padding(12)
                    .appButtonChrome(fill: AppTheme.wordCell, cornerRadius: 10)
                    .focused($tokenFieldFocused)
                    .onSubmit { addTokenField() }
                    .onChange(of: singleToken) { _, newValue in
                        let upper = newValue.uppercased()
                        if upper != newValue { singleToken = upper }
                        if newValue.contains(where: \.isWhitespace) {
                            let batch = newValue
                            singleToken = ""
                            processTokens(batch)
                        }
                    }

                PrimaryButton(
                    title: L10n.add,
                    enabled: PositionalHasher.isValidTokenFormat(singleToken, config: config),
                    busy: isWorking,
                    busyTitle: isDerivingKey ? L10n.busyPassword : L10n.busyCheckingToken,
                    useDefaultAction: false,
                    action: addTokenField
                )
                .frame(width: 100)
            }
            .ltrContent()

            if isWorking {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text(isDerivingKey ? L10n.busyPassword : L10n.busyCheckingToken)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            RevealableTokenGrid(
                items: slots,
                isHidden: $wordsHidden,
                highlightedIndex: highlightedIndex
            )
            .frame(maxHeight: .infinity)
        }
    }

    private var resultStep: some View {
        RevealableTokenGrid(
            items: slots,
            isHidden: $wordsHidden
        )
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private var footer: some View {
        switch step {
        case .phraseLength:
            PrimaryButton(title: L10n.next, systemImage: "arrow.forward") {
                withAnimation { step = .password }
            }
        case .password:
            PrimaryButton(
                title: L10n.next,
                systemImage: "arrow.forward",
                enabled: password.count >= 8
            ) {
                goToCodes()
            }
        case .codes:
            HStack(spacing: 10) {
                SecondaryButton(title: L10n.paste, systemImage: "doc.on.clipboard") {
                    pasteBatch()
                }
                .disabled(isWorking)

                SecondaryButton(title: L10n.clear, systemImage: "trash", width: 110) {
                    clearAll()
                }
            }
            .background(shortcutCapture(paste: pasteBatch, primary: nil))
        case .result:
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    SecondaryButton(
                        title: didCopy ? L10n.copied : L10n.copy,
                        systemImage: didCopy ? "checkmark" : "doc.on.doc"
                    ) {
                        ExportService.copyToPasteboard(slots.joined(separator: " "))
                        didCopy = true
                        toast.show(L10n.toastCopiedClipboard)
                        Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            didCopy = false
                        }
                    }
                    SecondaryButton(title: L10n.toFile, systemImage: "square.and.arrow.down") {
                        ExportService.saveTextFile(
                            content: slots.joined(separator: " ") + "\n",
                            suggestedName: "bip39-seed.txt"
                        )
                    }
                }
                HStack(spacing: 10) {
                    PrimaryButton(title: L10n.home, systemImage: "house.fill", action: requestExit)
                    SecondaryButton(title: L10n.again, systemImage: "arrow.counterclockwise", action: restartFlow)
                }
            }
        }
    }

    @ViewBuilder
    private func shortcutCapture(paste: (() -> Void)?, primary: (() -> Void)?) -> some View {
        Group {
            if let paste {
                Button("", action: paste)
                    .keyboardShortcut("v", modifiers: .command)
                    .frame(width: 0, height: 0)
                    .opacity(0)
            }
            if let primary {
                Button("", action: primary)
                    .keyboardShortcut(.return, modifiers: .command)
                    .frame(width: 0, height: 0)
                    .opacity(0)
            }
        }
    }

    private func goToCodes() {
        guard password.count >= 8 else { return }
        slots = Array(repeating: "", count: wordCount.rawValue)
        singleToken = ""
        fileImported = false
        withAnimation { step = .codes }
        FocusHelper.afterTransition { tokenFieldFocused = true }
    }

    private var hasSensitiveData: Bool {
        !password.isEmpty || filled > 0 || slots.contains(where: { !$0.isEmpty })
    }

    private func requestExit() {
        if hasSensitiveData {
            showExitConfirm = true
        } else {
            clearSensitiveData()
            onExit()
        }
    }

    private func clearSensitiveData() {
        password = ""
        passwordConfirm = ""
        singleToken = ""
        slots = Array(repeating: "", count: wordCount.rawValue)
        session.invalidateCache()
    }

    private func restartFlow() {
        wordCount = settings.defaultWordCount
        clearSensitiveData()
        didCopy = false
        wordsHidden = true
        fileImported = false
        highlightedIndex = nil
        withAnimation { step = .phraseLength }
    }

    private func addTokenField() {
        let raw = singleToken
        singleToken = ""
        processTokens(raw)
    }

    private func pasteBatch() {
        guard let raw = NSPasteboard.general.string(forType: .string) else {
            toast.show(L10n.toastClipboardEmpty, error: true)
            return
        }
        if raw.contains("#") {
            do {
                let imported = try CodesFileImport.parse(text: raw)
                handleImportedFile(imported)
                return
            } catch {
                // Clipboard contains `#` but is not a codes export — paste as raw tokens.
            }
        }
        processTokens(raw)
    }

    @MainActor
    private func pickCodesFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, .text]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = L10n.decryptPickCodesFile
        guard panel.runModal() == .OK, let url = panel.url else { return }
        importCodesFile(from: url)
    }

    @MainActor
    private func importCodesFile(from url: URL) {
        do {
            let imported = try CodesFileImport.parse(url: url)
            handleImportedFile(imported)
        } catch {
            toast.show(error.localizedDescription, error: true)
        }
    }

    @MainActor
    private func handleImportedFile(_ imported: ImportedCodesFile) {
        let diff = ImportSettingsDiff.compare(imported: imported, settings: settings)
        if diff.hasChanges {
            pendingImport = imported
            showImportConfirm = true
        } else {
            applyAndProcess(imported)
        }
    }

    @MainActor
    private func applyAndProcess(_ imported: ImportedCodesFile) {
        applyImportedMetadata(imported)
        slots = Array(repeating: "", count: wordCount.rawValue)
        singleToken = ""
        session.invalidateCache()
        fileImported = true
        toast.show(L10n.fileLoaded)
        processTokens(imported.tokensText)
    }

    @MainActor
    private func applyImportedMetadata(_ imported: ImportedCodesFile) {
        settings.applyFromImportedFile(
            version: imported.version,
            iterations: imported.iterations,
            keyBytes: imported.keyBytes
        )

        if let count = imported.wordCount, let mnemonicCount = MnemonicWordCount(rawValue: count) {
            if wordCount != mnemonicCount {
                suppressWordCountReset = true
                wordCount = mnemonicCount
            }
        }
    }

    private func processTokens(_ raw: String) {
        guard password.count >= 8 else {
            toast.show(HasherError.passwordTooShort.localizedDescription, error: true)
            return
        }

        isWorking = true
        isDerivingKey = !session.hasCache
        let pwd = password
        let length = wordCount.rawValue
        let existing = slots
        let cfg = config
        let cfgKey = configCacheKey

        Task {
            do {
                let outcome = try await session.process(
                    raw: raw,
                    password: pwd,
                    phraseLength: length,
                    existingSlots: existing,
                    config: cfg,
                    configKey: cfgKey
                )
                slots = outcome.slots
                isWorking = false
                if outcome.complete {
                    wordsHidden = true
                    withAnimation { step = .result }
                    toast.show(L10n.toastPhraseRestored)
                } else if outcome.placed == 1, let last = outcome.lastToken {
                    if let m = outcome.cache.lookupTable[last]?.first(
                        where: { outcome.slots[$0.position - 1] == $0.word }
                    ) {
                        toast.show(L10n.decryptWordFound(m.position, outcome.filledCount, length))
                    } else {
                        toast.show(L10n.decryptAdded(outcome.filledCount, length))
                    }
                    if let lastFilledIndex = outcome.lastFilledIndex {
                        flashHighlight(at: lastFilledIndex)
                    }
                } else {
                    toast.show(L10n.decryptAddedBatch(outcome.placed, outcome.filledCount, length))
                }
                FocusHelper.afterTransition { tokenFieldFocused = true }
            } catch is DecryptSessionError {
                isWorking = false
            } catch {
                isWorking = false
                toast.show(error.localizedDescription, error: true)
                FocusHelper.afterTransition { tokenFieldFocused = true }
            }
        }
    }

    private func flashHighlight(at index: Int) {
        withAnimation { highlightedIndex = index }
        Task {
            try? await Task.sleep(for: .seconds(0.6))
            withAnimation { highlightedIndex = nil }
        }
    }

    private func clearAll() {
        slots = Array(repeating: "", count: wordCount.rawValue)
        singleToken = ""
        highlightedIndex = nil
    }
}
