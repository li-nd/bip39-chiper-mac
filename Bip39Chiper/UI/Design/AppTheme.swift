//
//  AppTheme.swift
//  Bip39Chiper
//

import SwiftUI

enum AppTheme {
    static let bgTop = Color(red: 0.09, green: 0.11, blue: 0.13)
    static let bgBottom = Color(red: 0.06, green: 0.07, blue: 0.08)
    static let panel = Color(red: 0.13, green: 0.15, blue: 0.17)
    static let panelStroke = Color.white.opacity(0.08)
    static let accent = Color(red: 0.93, green: 0.62, blue: 0.28)
    static let accentSoft = Color(red: 0.93, green: 0.62, blue: 0.28).opacity(0.16)
    static let textPrimary = Color(red: 0.95, green: 0.95, blue: 0.93)
    static let textSecondary = Color(red: 0.62, green: 0.65, blue: 0.66)
    static let wordCell = Color(red: 0.16, green: 0.18, blue: 0.20)
    static let danger = Color(red: 1.0, green: 0.45, blue: 0.42)
    static let success = Color(red: 0.45, green: 0.78, blue: 0.55)
    static let onAccent = Color(red: 0.12, green: 0.09, blue: 0.05)

    static let interactiveStroke = accent.opacity(0.45)
}

/// Rounded hover/focus ring; uses the label bounds as the hit target.
struct AppPlainButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        AppPlainButtonBody(configuration: configuration, cornerRadius: cornerRadius)
    }
}

private struct AppPlainButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let cornerRadius: CGFloat

    @Environment(\.isFocused) private var isFocused
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    private var showRing: Bool {
        isEnabled && (isHovered || isFocused)
    }

    var body: some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.82 : 1)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.interactiveStroke, lineWidth: 2)
                    .opacity(showRing ? 1 : 0)
            }
            .animation(.easeInOut(duration: 0.15), value: showRing)
            .onHover { isHovered = $0 }
    }
}

extension View {
    func appPlainButton(cornerRadius: CGFloat = 12) -> some View {
        buttonStyle(AppPlainButtonStyle(cornerRadius: cornerRadius))
            .focusEffectDisabled()
    }
}

extension View {
    /// Filled rounded background, optional stroke, and matching `contentShape` for hit testing.
    func appButtonChrome(
        fill: Color,
        stroke: Color = AppTheme.panelStroke,
        cornerRadius: CGFloat = 12,
        showStroke: Bool = true
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
            )
            .overlay {
                if showStroke {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(stroke, lineWidth: 1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
