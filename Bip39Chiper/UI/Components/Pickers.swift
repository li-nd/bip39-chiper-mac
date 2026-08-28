//
//  Pickers.swift
//  Bip39Chiper
//

import SwiftUI

struct WordCountPicker: View {
    @Binding var selection: MnemonicWordCount

    var body: some View {
        HStack(spacing: 8) {
            ForEach(MnemonicWordCount.allCases) { count in
                let selected = selection == count
                Button {
                    selection = count
                } label: {
                    Text("\(count.rawValue)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .appButtonChrome(
                            fill: selected ? AppTheme.accentSoft : AppTheme.panel,
                            stroke: selected ? AppTheme.accent.opacity(0.7) : AppTheme.panelStroke,
                            cornerRadius: 9
                        )
                        .foregroundStyle(selected ? AppTheme.accent : AppTheme.textSecondary)
                }
                .appPlainButton(cornerRadius: 9)
                .help(count.label)
            }
        }
    }
}

struct ConfirmingWordCountPicker: View {
    @Binding var selection: MnemonicWordCount
    var hasContent: () -> Bool
    var onReset: () -> Void

    @State private var pending: MnemonicWordCount?
    @State private var showConfirm = false

    var body: some View {
        WordCountPicker(selection: Binding(
            get: { selection },
            set: { newValue in
                guard newValue != selection else { return }
                if hasContent() {
                    pending = newValue
                    showConfirm = true
                } else {
                    selection = newValue
                }
            }
        ))
        .confirmationDialog(L10n.resetWordsTitle, isPresented: $showConfirm, titleVisibility: .visible) {
            Button(L10n.resetWordsConfirm, role: .destructive) {
                if let pending {
                    selection = pending
                    onReset()
                }
                pending = nil
            }
            Button(L10n.cancel, role: .cancel) {
                pending = nil
            }
        } message: {
            Text(L10n.resetWordsMessage)
        }
    }
}
