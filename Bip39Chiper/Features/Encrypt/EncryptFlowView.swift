//
//  EncryptFlowView.swift
//  Bip39Chiper
//

import AppKit
import SwiftUI

private enum EncryptStep: Equatable {
    case source
    case create
    case enter
    case password
    case result

    var indicatorIndex: Int {
        switch self {
        case .source: return 0
        case .create, .enter: return 1
        case .password: return 2
        case .result: return 3
        }
    }
}

struct EncryptFlowView: View {
    let onExit: () -> Void

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var toast: ToastCenter

    @State private var step: EncryptStep = .source
    @State private var cameFromCreate = true
    @State private var wordCount: MnemonicWordCount = .twentyFour
    @State private var words: [String] = Array(repeating: "", count: 24)
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var tokens: [String] = []
    @State private var isWorking = false
    @State private var didCopy = false
    @State private var wordsHidden = true
    @State private var tokensHidden = true
    @State private var posterPreview: IdentifiedImage?
    @State private var showExitConfirm = false
    @State private var wordFieldFocusTrigger = UUID()

    private let stepLabels = [L10n.stepSource, L10n.stepPhrase, L10n.stepPassword, L10n.stepCodes]

    var body: some View {
        FlowChrome(
            title: stepTitle,
            subtitle: stepSubtitle,
            stepIndex: step.indicatorIndex,
            stepLabels: stepLabels,
            onBack: backAction
        ) {
            VStack(alignment: .leading, spacing: 0) {
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                stepFooter
                    .padding(.top, 14)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: step)
        .onAppear {
            wordCount = settings.defaultWordCount
            words = Array(repeating: "", count: wordCount.rawValue)
        }
        .onChange(of: wordCount) { _, newValue in
            if step == .create || step == .enter {
                words = Array(repeating: "", count: newValue.rawValue)
            }
        }
        .onChange(of: step) { _, newStep in
            if newStep == .enter {
                wordFieldFocusTrigger = UUID()
            }
        }
        .sheet(item: $posterPreview) { item in
            PosterPreviewSheet(
                image: item.image,
                onSave: {
                    ExportService.savePNG(item.image, suggestedName: "seed-codes.png")
                    posterPreview = nil
                },
                onClose: { posterPreview = nil }
            )
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
        case .source: return L10n.homeEncrypt
        case .create: return L10n.encryptTitleCreate
        case .enter: return L10n.encryptTitleEnter
        case .password: return L10n.stepPassword
        case .result: return L10n.stepDone
        }
    }

    private var stepSubtitle: String {
        switch step {
        case .source: return L10n.encryptSubtitleSource
        case .create: return L10n.encryptSubtitleCreate
        case .enter: return L10n.encryptSubtitleEnter
        case .password: return L10n.encryptSubtitlePassword
        case .result: return L10n.encryptSubtitleResult
        }
    }

    private var backAction: (() -> Void)? {
        switch step {
        case .source:
            return requestExit
        case .create, .enter:
            return {
                withAnimation { step = .source }
            }
        case .password:
            return {
                withAnimation { step = cameFromCreate ? .create : .enter }
            }
        case .result:
            return requestExit
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .source:
            sourceStep
        case .create:
            createStep
        case .enter:
            SeedEntryView(
                words: $words,
                selectedWordCount: $wordCount,
                showsOwnFooter: false,
                focusTrigger: wordFieldFocusTrigger
            )
        case .password:
            passwordStep
        case .result:
            resultStep
        }
    }

    private var sourceStep: some View {
        VStack(spacing: 12) {
            sourceCard(
                title: L10n.encryptSourceNewTitle,
                subtitle: L10n.encryptSourceNewSubtitle,
                icon: "plus.circle.fill"
            ) {
                cameFromCreate = true
                wordCount = settings.defaultWordCount
                words = Array(repeating: "", count: wordCount.rawValue)
                withAnimation { step = .create }
            }

            sourceCard(
                title: L10n.encryptSourceExistingTitle,
                subtitle: L10n.encryptSourceExistingSubtitle,
                icon: "keyboard"
            ) {
                cameFromCreate = false
                wordCount = settings.defaultWordCount
                words = Array(repeating: "", count: wordCount.rawValue)
                withAnimation { step = .enter }
                wordFieldFocusTrigger = UUID()
            }
            Spacer()
        }
    }

    private func sourceCard(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(AppTheme.accentSoft))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(16)
            .appButtonChrome(fill: AppTheme.panel, cornerRadius: 14)
        }
        .appPlainButton(cornerRadius: 14)
    }

    private var createStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.phraseLength)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            ConfirmingWordCountPicker(
                selection: $wordCount,
                hasContent: { !words.allSatisfy(\.isEmpty) },
                onReset: { words = Array(repeating: "", count: wordCount.rawValue) }
            )

            if words.allSatisfy(\.isEmpty) {
                SkeletonPhraseGrid(wordCount: wordCount.rawValue)
            } else {
                RevealableTokenGrid(
                    items: words,
                    isHidden: $wordsHidden,
                    emptyPlaceholder: "—",
                    highlightFilled: true
                )
                .frame(maxHeight: .infinity)
            }
        }
    }

    private var passwordStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            PasswordFields(
                password: $password,
                confirm: $passwordConfirm,
                requireConfirm: true,
                showStrength: true,
                autoFocus: true
            )

            if isWorking {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text(L10n.busyPassword)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.top, 4)
            }

            Spacer(minLength: 0)
        }
    }

    private var resultStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $settings.shuffleOnExport) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.shuffleExport)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Text(L10n.shuffleExportHint)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .toggleStyle(.switch)
            .tint(AppTheme.accent)

            RevealableTokenGrid(
                items: tokens,
                isHidden: $tokensHidden,
                emptyPlaceholder: "————————",
                highlightFilled: false
            )
            .frame(maxHeight: .infinity)
        }
        .onAppear {
            tokensHidden = true
        }
    }

    @ViewBuilder
    private var stepFooter: some View {
        switch step {
        case .source:
            EmptyView()
        case .create:
            HStack(spacing: 10) {
                if words.allSatisfy(\.isEmpty) {
                    PrimaryButton(title: L10n.generate, systemImage: "arrow.triangle.2.circlepath") {
                        generate()
                    }
                } else {
                    SecondaryButton(title: L10n.again, systemImage: "arrow.triangle.2.circlepath") {
                        generate()
                    }
                    .frame(width: 140)
                    PrimaryButton(
                        title: L10n.next,
                        systemImage: "arrow.forward",
                        enabled: words.allSatisfy { !$0.isEmpty }
                    ) {
                        goToPasswordIfValid()
                    }
                }
            }
        case .enter:
            PrimaryButton(
                title: L10n.next,
                systemImage: "arrow.forward",
                enabled: words.allSatisfy { !$0.isEmpty } && words.count == wordCount.rawValue
            ) {
                goToPasswordIfValid()
            }
            .background(
                Group {
                    Button("", action: pastePhraseFromClipboard)
                        .keyboardShortcut("v", modifiers: .command)
                        .frame(width: 0, height: 0)
                        .opacity(0)
                }
            )
        case .password:
            PrimaryButton(
                title: L10n.encrypt,
                systemImage: "lock.fill",
                enabled: password.count >= 8 && password == passwordConfirm,
                busy: isWorking,
                busyTitle: L10n.busyPassword
            ) {
                obfuscate()
            }
        case .result:
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    SecondaryButton(
                        title: didCopy ? L10n.copied : L10n.copy,
                        systemImage: didCopy ? "checkmark" : "doc.on.doc",
                        action: copyTokens
                    )
                    SecondaryButton(title: L10n.toFile, systemImage: "square.and.arrow.down", action: saveTokensFile)
                    SecondaryButton(title: L10n.poster, systemImage: "photo", action: previewPoster)
                }
                HStack(spacing: 10) {
                    PrimaryButton(title: L10n.home, systemImage: "house.fill", action: requestExit)
                    SecondaryButton(title: L10n.again, systemImage: "arrow.counterclockwise", action: restartFlow)
                }
            }
        }
    }

    private var hasSensitiveData: Bool {
        !password.isEmpty || !words.allSatisfy(\.isEmpty) || !tokens.isEmpty
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
        words = Array(repeating: "", count: wordCount.rawValue)
        tokens = []
    }

    private func restartFlow() {
        wordCount = settings.defaultWordCount
        clearSensitiveData()
        didCopy = false
        wordsHidden = true
        tokensHidden = true
        cameFromCreate = true
        withAnimation { step = .source }
    }

    private func generate() {
        do {
            words = try BIP39Mnemonic.generate(wordCount: wordCount)
            wordsHidden = true
        } catch {
            toast.show(error.localizedDescription, error: true)
        }
    }

    private func goToPasswordIfValid() {
        do {
            try BIP39Mnemonic.validate(words)
            password = ""
            passwordConfirm = ""
            withAnimation { step = .password }
        } catch {
            toast.show(error.localizedDescription, error: true)
        }
    }

    private func pastePhraseFromClipboard() {
        guard let raw = NSPasteboard.general.string(forType: .string), !raw.isEmpty else {
            toast.show(L10n.toastClipboardEmpty, error: true)
            return
        }
        let tokens = BIP39Autocomplete.tokenizePhrase(raw)
        guard let count = MnemonicWordCount(rawValue: tokens.count) else {
            toast.show(L10n.toastWrongWordCount(tokens.count), error: true)
            return
        }
        var resolved: [String] = []
        for (index, token) in tokens.enumerated() {
            guard let word = BIP39Autocomplete.resolveWord(token) else {
                toast.show(L10n.toastWordNotInDictionary(index + 1, token), error: true)
                return
            }
            resolved.append(word)
        }
        wordCount = count
        words = resolved
        wordFieldFocusTrigger = UUID()
        toast.show(L10n.toastPhrasePasted)
    }

    private func obfuscate() {
        guard password == passwordConfirm else {
            toast.show(HasherError.passwordMismatch.localizedDescription, error: true)
            return
        }
        isWorking = true
        let source = words
        let pwd = password
        let config = settings.hasherConfig
        Task.detached(priority: .userInitiated) {
            do {
                let result = try PositionalHasher.obfuscate(words: source, password: pwd, config: config)
                await MainActor.run {
                    tokens = result
                    isWorking = false
                    tokensHidden = true
                    withAnimation { step = .result }
                    toast.show(L10n.toastDone)
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    toast.show(error.localizedDescription, error: true)
                }
            }
        }
    }

    private func preparedExportTokens() -> [String] {
        ExportService.exportTokens(tokens, shuffle: settings.shuffleOnExport)
    }

    private func copyTokens() {
        ExportService.copyToPasteboard(ExportService.joinTokens(preparedExportTokens()))
        didCopy = true
        toast.show(L10n.toastCopiedClipboard)
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            didCopy = false
        }
    }

    private func saveTokensFile() {
        let body = ExportService.tokensFileContent(
            tokens: preparedExportTokens(),
            config: settings.hasherConfig,
            wordCount: words.count
        )
        ExportService.saveTextFile(content: body, suggestedName: "seed-codes.txt")
    }

    private func previewPoster() {
        posterPreview = IdentifiedImage(
            image: ExportService.makeTokensPoster(
                tokens: preparedExportTokens(),
                config: settings.hasherConfig,
                wordCount: words.count
            )
        )
    }
}

private struct IdentifiedImage: Identifiable {
    let id = UUID()
    let image: NSImage
}
