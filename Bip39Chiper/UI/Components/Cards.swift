//
//  Cards.swift
//  Bip39Chiper
//

import SwiftUI

struct HoverHomeCard<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @State private var isHovered = false

    var body: some View {
        content()
            .appButtonChrome(fill: AppTheme.panel, cornerRadius: 16)
            .scaleEffect(isHovered ? 1.01 : 1)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

struct CollapsedFileImportRow: View {
    let onChange: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.success)
            Text(L10n.fileLoaded)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Button(L10n.changeFile, action: onChange)
                .appPlainButton(cornerRadius: 8)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.accent)
        }
        .padding(12)
        .appButtonChrome(fill: AppTheme.wordCell, cornerRadius: 10)
    }
}
