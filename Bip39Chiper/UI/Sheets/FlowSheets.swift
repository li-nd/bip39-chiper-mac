//
//  FlowSheets.swift
//  Bip39Chiper
//

import AppKit
import SwiftUI

struct ImportConfirmSheet: View {
    let diff: ImportSettingsDiff
    let onApply: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.importConfirmTitle)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text(L10n.importConfirmMessage)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(diff.changes.enumerated()), id: \.offset) { _, change in
                    HStack {
                        Text(change.label)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        Text("\(change.from) → \(change.to)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            .padding(12)
            .appButtonChrome(fill: AppTheme.wordCell, cornerRadius: 10)
            .ltrContent()

            HStack(spacing: 10) {
                SecondaryButton(title: L10n.cancel, action: onCancel)
                PrimaryButton(title: L10n.apply, action: onApply)
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(AppTheme.panel)
    }
}

struct PosterPreviewSheet: View {
    let image: NSImage
    let onSave: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 16) {
                Text(L10n.posterPreview)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 480, maxHeight: 380)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppTheme.panelStroke, lineWidth: 1)
                    )
                HStack(spacing: 10) {
                    SecondaryButton(title: L10n.close, action: onClose)
                    PrimaryButton(title: L10n.posterSavePNG, systemImage: "square.and.arrow.down", action: onSave)
                }
            }
            .padding(24)
        }
        .frame(minWidth: 520, minHeight: 500)
        .preferredColorScheme(.dark)
    }
}

struct OnboardingSheet: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L10n.onboardingTitle)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            onboardingRow("key.fill", L10n.onboarding1)
            onboardingRow("doc.text.fill", L10n.onboarding2)
            onboardingRow("wifi.slash", L10n.onboarding3)

            PrimaryButton(title: L10n.understood, systemImage: "checkmark", action: onDismiss)
        }
        .padding(28)
        .frame(width: 420)
        .background(AppTheme.panel)
    }

    private func onboardingRow(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}
