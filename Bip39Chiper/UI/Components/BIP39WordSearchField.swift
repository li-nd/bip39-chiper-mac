//
//  BIP39WordSearchField.swift
//  Bip39Chiper
//

import AppKit
import SwiftUI

struct BIP39WordSearchField: View {
    let placeholder: String
    var isEnabled: Bool = true
    var focusTrigger: UUID = UUID()
    let onCommit: (String) -> Void
    var onPastePhrase: ((String) -> Void)? = nil

    @State private var text = ""
    @State private var suggestions: [String] = []
    @State private var highlightedIndex = 0
    @State private var showList = false
    @State private var isInvalidPrefix = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.textSecondary)

                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
                    .focused($isFocused)
                    .disabled(!isEnabled)
                    .onSubmit {
                        confirmHighlightedOrUnique()
                    }
                    .onChange(of: text) { _, newValue in
                        handleTextChange(newValue)
                    }

                if !text.isEmpty {
                    Button {
                        text = ""
                        suggestions = []
                        showList = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .appPlainButton(cornerRadius: 12)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.wordCell)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isFocused ? AppTheme.accent.opacity(0.7) : AppTheme.panelStroke,
                        lineWidth: 1
                    )
            )

            if showList && !suggestions.isEmpty {
                suggestionsPanel
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else if isInvalidPrefix {
                Text(L10n.wordSearchNoMatch)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.danger)
                    .padding(.top, 8)
                    .transition(.opacity)
            }
        }
        .ltrContent()
        .onAppear {
            FocusHelper.afterTransition { isFocused = true }
        }
        .onChange(of: focusTrigger) { _, _ in
            FocusHelper.afterTransition { isFocused = true }
        }
        .onKeyPress(.downArrow) {
            moveHighlight(1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            moveHighlight(-1)
            return .handled
        }
        .onKeyPress(.escape) {
            showList = false
            return .handled
        }
        .onKeyPress(keys: [.space]) { _ in
            if confirmHighlightedOrUnique() {
                return .handled
            }
            return .ignored
        }
        .animation(.easeInOut(duration: 0.15), value: showList)
    }

    private var suggestionsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(suggestions.enumerated()), id: \.offset) { index, word in
                Button {
                    commit(word)
                } label: {
                    HStack {
                        Text(word)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        if index == highlightedIndex {
                            Text(L10n.wordSearchEnterHint)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        index == highlightedIndex
                            ? AppTheme.accentSoft
                            : Color.clear
                    )
                    .contentShape(Rectangle())
                }
                .appPlainButton(cornerRadius: 8)
            }
        }
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.panelStroke, lineWidth: 1)
        )
        .padding(.top, 6)
    }

    private func handleTextChange(_ raw: String) {
        if let onPastePhrase,
           raw.contains(where: { $0.isWhitespace || $0.isNewline || $0 == "," || $0 == ";" }),
           BIP39Autocomplete.tokenizePhrase(raw).count > 1 {
            text = ""
            suggestions = []
            showList = false
            isInvalidPrefix = false
            onPastePhrase(raw)
            return
        }

        let normalized = BIP39Autocomplete.normalize(raw)
        if normalized != raw {
            text = normalized
            return
        }

        suggestions = BIP39Autocomplete.suggestions(for: normalized)
        highlightedIndex = 0
        isInvalidPrefix = !normalized.isEmpty
            && normalized.count >= 4
            && suggestions.isEmpty

        if let unique = BIP39Autocomplete.uniqueMatch(for: normalized) {
            commit(unique)
            return
        }

        showList = BIP39Autocomplete.shouldShowSuggestions(for: normalized)
            && isFocused
            && !suggestions.isEmpty
    }

    @discardableResult
    private func confirmHighlightedOrUnique() -> Bool {
        if let unique = BIP39Autocomplete.uniqueMatch(for: text) {
            commit(unique)
            return true
        }
        guard showList, suggestions.indices.contains(highlightedIndex) else {
            return false
        }
        commit(suggestions[highlightedIndex])
        return true
    }

    private func commit(_ word: String) {
        onCommit(word)
        text = ""
        suggestions = []
        showList = false
        isInvalidPrefix = false
        highlightedIndex = 0
        DispatchQueue.main.async {
            isFocused = true
        }
    }

    private func moveHighlight(_ delta: Int) {
        guard !suggestions.isEmpty else { return }
        showList = true
        let count = suggestions.count
        highlightedIndex = (highlightedIndex + delta + count) % count
    }
}
