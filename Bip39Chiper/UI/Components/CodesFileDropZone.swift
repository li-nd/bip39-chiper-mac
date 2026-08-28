//
//  CodesFileDropZone.swift
//  Bip39Chiper
//

import SwiftUI
import UniformTypeIdentifiers

struct CodesFileDropZone: View {
    var enabled: Bool = true
    let onPickFile: () -> Void
    let onDropURL: (URL) -> Void

    @State private var isTargeted = false
    @State private var isHovered = false

    private var borderColor: Color {
        if isTargeted { return AppTheme.accent }
        if isHovered { return AppTheme.interactiveStroke }
        return AppTheme.panelStroke
    }

    var body: some View {
        Button(action: onPickFile) {
            HStack(spacing: 12) {
                Image(systemName: "doc.badge.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.dropzoneTitle)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(L10n.dropzoneSubtitle)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isTargeted || isHovered ? AppTheme.accentSoft : AppTheme.wordCell)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        borderColor,
                        style: StrokeStyle(lineWidth: isTargeted ? 2 : 1, dash: isTargeted ? [] : [6, 4])
                    )
            )
        }
        .appPlainButton()
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
        .onHover { isHovered = enabled && $0 }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard enabled else { return false }
            guard let provider = providers.first else { return false }
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                let url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let value = item as? URL {
                    url = value
                } else {
                    url = nil
                }
                guard let url else { return }
                DispatchQueue.main.async {
                    onDropURL(url)
                }
            }
            return true
        }
    }
}
