//
//  StepIndicator.swift
//  Bip39Chiper
//

import SwiftUI

struct StepIndicator: View {
    let current: Int
    let labels: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                VStack(spacing: 5) {
                    Capsule()
                        .fill(index <= current ? AppTheme.accent : AppTheme.wordCell)
                        .frame(height: 4)
                    Text(label)
                        .font(.system(size: 9, weight: index == current ? .semibold : .regular, design: .rounded))
                        .foregroundStyle(index <= current ? AppTheme.accent : AppTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 14)
        .accessibilityLabel(
            labels.indices.contains(current)
                ? L10n.a11yStepNamed(labels[current], current + 1, labels.count)
                : L10n.a11yStepGeneric(current + 1, labels.count)
        )
    }
}
