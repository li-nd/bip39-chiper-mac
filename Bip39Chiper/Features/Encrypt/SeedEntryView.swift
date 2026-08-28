//
//  SeedEntryView.swift
//  Bip39Chiper
//

import AppKit
import SwiftUI

struct SeedEntryView: View {
    @Binding var words: [String]
    @Binding var selectedWordCount: MnemonicWordCount
    var showsOwnFooter: Bool = true
    /// Update to refocus the search field after navigating back to this step.
    var focusTrigger: UUID = UUID()

    @State private var activeIndex: Int = 0
    @State private var statusMessage: String?
    @State private var statusIsError = false
    @State private var didCopy = false
    @State private var fieldResetID = UUID()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    private var filledCount: Int {
        words.filter { !$0.isEmpty }.count
    }

    private var isComplete: Bool {
        !words.isEmpty && words.allSatisfy { !$0.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            lengthPicker
                .padding(.bottom, 16)

            inputSection
                .padding(.bottom, 14)

            slotsGrid
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let statusMessage {
                Text(statusMessage)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(statusIsError ? AppTheme.danger : AppTheme.success)
                    .padding(.top, 12)
            }

            if showsOwnFooter {
                footer
                    .padding(.top, 16)
            } else {
                HStack(spacing: 10) {
                    SecondaryButton(title: L10n.paste, systemImage: "doc.on.clipboard", action: pasteFromClipboard)
                        .frame(width: 130)
                    SecondaryButton(title: L10n.clear, systemImage: "trash", width: 110, action: clearAll)
                    Spacer()
                }
                .padding(.top, 12)
            }
        }
        .onAppear {
            syncActiveIndex()
        }
        .onChange(of: selectedWordCount) { _, newCount in
            resizeWords(to: newCount.rawValue)
            statusMessage = nil
            fieldResetID = UUID()
        }
        .onChange(of: words) { _, _ in
            if activeIndex >= words.count || (activeIndex < words.count && !words[activeIndex].isEmpty && words.contains(where: \.isEmpty) == false) {
                syncActiveIndex()
            }
        }
    }

    private func syncActiveIndex() {
        if let nextEmpty = words.indices.first(where: { words[$0].isEmpty }) {
            activeIndex = nextEmpty
        } else {
            activeIndex = words.count
        }
    }

    private var lengthPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.phraseLength)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)

            ConfirmingWordCountPicker(
                selection: $selectedWordCount,
                hasContent: { filledCount > 0 },
                onReset: {
                    words = Array(repeating: "", count: selectedWordCount.rawValue)
                    activeIndex = 0
                    fieldResetID = UUID()
                }
            )
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(activeIndex < words.count
                     ? L10n.seedWordProgress(activeIndex + 1, words.count)
                     : L10n.seedAllWordsEntered)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                Text("\(filledCount)/\(words.count)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.accent)
                    .contentTransition(.numericText())
                    .accessibilityLabel(L10n.a11yProgress(filledCount, words.count))
            }

            if activeIndex < words.count {
                BIP39WordSearchField(
                    placeholder: L10n.seedPlaceholder,
                    focusTrigger: focusTrigger,
                    onCommit: commitWord,
                    onPastePhrase: applyPastedPhrase
                )
                .id(fieldResetID)

                Text(L10n.seedHint)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.85))
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AppTheme.success)
                    Text(L10n.seedPhraseComplete)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)

                    Spacer(minLength: 0)

                    Button(action: pasteFromClipboard) {
                        Label(L10n.paste, systemImage: "doc.on.clipboard")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                    }
                    .appPlainButton(cornerRadius: 8)
                    .foregroundStyle(AppTheme.accent)
                    .help(L10n.seedHelpReplaceClipboard)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.wordCell)
                )
            }
        }
    }

    private var slotsGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(words.indices, id: \.self) { index in
                    slotCell(index: index)
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.panelStroke, lineWidth: 1)
        )
        .ltrContent()
    }

    private func slotCell(index: Int) -> some View {
        let word = words[index]
        let isActive = index == activeIndex
        let isFilled = !word.isEmpty

        return Button {
            activeIndex = index
            statusMessage = nil
            fieldResetID = UUID()
        } label: {
            HStack(spacing: 8) {
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isActive ? AppTheme.accent : AppTheme.textSecondary)
                    .frame(width: 22, alignment: .trailing)

                Text(isFilled ? word : "—")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(isFilled ? AppTheme.textPrimary : AppTheme.textSecondary.opacity(0.45))
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .scaleEffect(isActive ? 1.03 : 1)
            .appButtonChrome(
                fill: isActive ? AppTheme.accentSoft : AppTheme.wordCell,
                stroke: isActive ? AppTheme.accent.opacity(0.75) : AppTheme.panelStroke,
                cornerRadius: 10
            )
            .animation(.easeInOut(duration: 0.2), value: isFilled)
        }
        .appPlainButton(cornerRadius: 10)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button(action: pasteFromClipboard) {
                Label(L10n.paste, systemImage: "doc.on.clipboard")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .frame(width: 120)
                    .padding(.vertical, 12)
                    .appButtonChrome(fill: AppTheme.wordCell)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .appPlainButton()
            .keyboardShortcut("v", modifiers: [.command, .shift])
            .help(L10n.seedHelpPastePhrase)

            Button(action: validatePhrase) {
                Label(L10n.validate, systemImage: "checkmark.shield")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .appButtonChrome(fill: AppTheme.accent, showStroke: false)
                    .foregroundStyle(AppTheme.onAccent)
            }
            .appPlainButton()
            .disabled(!isComplete)
            .opacity(isComplete ? 1 : 0.45)

            Button(action: copyPhrase) {
                Label(didCopy ? L10n.copied : L10n.copy, systemImage: didCopy ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .frame(width: 130)
                    .padding(.vertical, 12)
                    .appButtonChrome(fill: AppTheme.wordCell)
                    .foregroundStyle(isComplete ? AppTheme.textPrimary : AppTheme.textSecondary.opacity(0.45))
            }
            .appPlainButton()
            .disabled(!isComplete)

            Button(action: clearAll) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .appButtonChrome(fill: AppTheme.wordCell)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .appPlainButton()
            .help(L10n.seedHelpClearAll)
        }
    }

    private func commitWord(_ word: String) {
        guard words.indices.contains(activeIndex) else { return }
        words[activeIndex] = word
        statusMessage = nil

        if let nextEmpty = words.indices.first(where: { words[$0].isEmpty }) {
            activeIndex = nextEmpty
        } else {
            activeIndex = words.count
            validatePhrase()
        }
        fieldResetID = UUID()
    }

    private func pasteFromClipboard() {
        guard let raw = NSPasteboard.general.string(forType: .string), !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusIsError = true
            statusMessage = L10n.seedToastClipboardEmpty
            return
        }
        applyPastedPhrase(raw)
    }

    private func applyPastedPhrase(_ raw: String) {
        let tokens = BIP39Autocomplete.tokenizePhrase(raw)
        guard let count = MnemonicWordCount(rawValue: tokens.count) else {
            statusIsError = true
            statusMessage = L10n.toastWrongWordCount(tokens.count)
            fieldResetID = UUID()
            return
        }

        var resolved: [String] = []
        resolved.reserveCapacity(tokens.count)
        for (index, token) in tokens.enumerated() {
            guard let word = BIP39Autocomplete.resolveWord(token) else {
                statusIsError = true
                statusMessage = L10n.toastWordNotInDictionary(index + 1, token)
                fieldResetID = UUID()
                return
            }
            resolved.append(word)
        }

        selectedWordCount = count
        words = resolved
        activeIndex = words.count
        fieldResetID = UUID()
        validatePhrase()
    }

    private func resizeWords(to count: Int) {
        if words.count > count {
            words = Array(words.prefix(count))
        } else if words.count < count {
            words.append(contentsOf: Array(repeating: "", count: count - words.count))
        }
        if let nextEmpty = words.indices.first(where: { words[$0].isEmpty }) {
            activeIndex = nextEmpty
        } else {
            activeIndex = words.isEmpty ? 0 : min(activeIndex, words.count - 1)
        }
    }

    private func validatePhrase() {
        guard isComplete else {
            statusIsError = true
            statusMessage = L10n.seedToastFillAll(words.count)
            return
        }
        do {
            try BIP39Mnemonic.validate(words)
            statusIsError = false
            statusMessage = L10n.seedToastValidated
        } catch {
            statusIsError = true
            statusMessage = error.localizedDescription
        }
    }

    private func copyPhrase() {
        guard isComplete else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(words.joined(separator: " "), forType: .string)
        withAnimation(.easeInOut(duration: 0.15)) {
            didCopy = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeInOut(duration: 0.15)) {
                didCopy = false
            }
        }
    }

    private func clearAll() {
        words = Array(repeating: "", count: selectedWordCount.rawValue)
        activeIndex = 0
        statusMessage = nil
        fieldResetID = UUID()
    }
}
