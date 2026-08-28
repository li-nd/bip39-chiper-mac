//
//  Grids.swift
//  Bip39Chiper
//

import SwiftUI

struct TokenOrWordGrid: View {
    let items: [String]
    var emptyPlaceholder: String = "—"
    var highlightFilled: Bool = true
    var masked: Bool = false
    var blurWords: Bool = false
    var highlightedIndex: Int? = nil

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, value in
                    gridCell(index: index, value: value)
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.panelStroke, lineWidth: 1)
        )
        .ltrContent()
    }

    private func displayText(for value: String) -> String {
        if value.isEmpty { return emptyPlaceholder }
        if masked { return String(repeating: "•", count: min(value.count, 8)) }
        return value
    }

    private func gridCell(index: Int, value: String) -> some View {
        let filled = !value.isEmpty
        let display = displayText(for: value)
        let shouldBlurWord = blurWords && filled
        let isHighlighted = highlightedIndex == index
        return HStack(spacing: 6) {
            Text("\(index + 1)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AppTheme.accent)
                .frame(width: 18, alignment: .trailing)
            Text(display)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(filled ? AppTheme.textPrimary : AppTheme.textSecondary.opacity(0.4))
                .lineLimit(1)
                .blur(radius: shouldBlurWord ? 7 : 0)
                .opacity(shouldBlurWord ? 0.75 : 1)
                .modifier(OptionalTextSelection(enabled: !masked && !blurWords))
                .accessibilityLabel(shouldBlurWord && filled ? L10n.a11yHiddenWord(index + 1) : display)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .scaleEffect(isHighlighted ? 1.03 : 1)
        .appButtonChrome(
            fill: filled && highlightFilled ? AppTheme.accentSoft.opacity(0.5) : AppTheme.wordCell,
            stroke: isHighlighted ? AppTheme.accent : (filled && highlightFilled ? AppTheme.accent.opacity(0.4) : AppTheme.panelStroke),
            cornerRadius: 8
        )
        .animation(.easeInOut(duration: 0.25), value: isHighlighted)
    }
}

/// Inert grid shown before a phrase is generated or entered.
struct SkeletonPhraseGrid: View {
    let wordCount: Int
    var emptyPlaceholder: String = "···"

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<wordCount, id: \.self) { index in
                    skeletonCell(index: index)
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.panelStroke, lineWidth: 1)
        )
        .opacity(0.55)
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.phraseNotCreated)
        .ltrContent()
    }

    private func skeletonCell(index: Int) -> some View {
        HStack(spacing: 6) {
            Text("\(index + 1)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AppTheme.accent.opacity(0.7))
                .frame(width: 18, alignment: .trailing)
            Text(emptyPlaceholder)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.35))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .appButtonChrome(
            fill: AppTheme.wordCell.opacity(0.65),
            stroke: AppTheme.panelStroke.opacity(0.6),
            cornerRadius: 8
        )
    }
}

/// Word grid with optional blur-reveal; position numbers stay visible when blurred.
struct RevealableTokenGrid: View {
    let items: [String]
    @Binding var isHidden: Bool
    var emptyPlaceholder: String = "—"
    var highlightFilled: Bool = true
    var highlightedIndex: Int? = nil

    var body: some View {
        VStack(spacing: 8) {
            TokenOrWordGrid(
                items: items,
                emptyPlaceholder: emptyPlaceholder,
                highlightFilled: highlightFilled,
                masked: false,
                blurWords: isHidden,
                highlightedIndex: highlightedIndex
            )
            .allowsHitTesting(!isHidden)

            HStack {
                Spacer(minLength: 0)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHidden.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isHidden ? "eye.fill" : "eye.slash")
                        Text(isHidden ? L10n.show : L10n.hide)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .appButtonChrome(
                        fill: isHidden ? AppTheme.accent : AppTheme.wordCell,
                        cornerRadius: 8,
                        showStroke: !isHidden
                    )
                    .foregroundStyle(isHidden ? AppTheme.onAccent : AppTheme.textSecondary)
                }
                .appPlainButton(cornerRadius: 8)
                Spacer(minLength: 0)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isHidden)
    }
}

private struct OptionalTextSelection: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.textSelection(.enabled)
        } else {
            content.textSelection(.disabled)
        }
    }
}
