//
//  Buttons.swift
//  Bip39Chiper
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var enabled: Bool = true
    var busy: Bool = false
    var busyTitle: String? = nil
    var useDefaultAction: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if busy {
                    ProgressView().controlSize(.small)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(busy ? (busyTitle ?? title) : title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .appButtonChrome(fill: AppTheme.accent, showStroke: false)
            .foregroundStyle(AppTheme.onAccent)
        }
        .appPlainButton()
        .disabled(!enabled || busy)
        .opacity(enabled && !busy ? 1 : 0.45)
        .modifier(PrimaryButtonShortcuts(enabled: useDefaultAction && enabled && !busy))
    }
}

private struct PrimaryButtonShortcuts: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content
                .keyboardShortcut(.defaultAction)
                .keyboardShortcut(.return, modifiers: .command)
        } else {
            content
        }
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    var enabled: Bool = true
    var width: CGFloat? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .frame(width: width)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .padding(.vertical, 12)
            .padding(.horizontal, width == nil ? 0 : 12)
            .appButtonChrome(fill: AppTheme.wordCell)
            .foregroundStyle(enabled ? AppTheme.textPrimary : AppTheme.textSecondary.opacity(0.45))
        }
        .appPlainButton()
        .disabled(!enabled)
    }
}
