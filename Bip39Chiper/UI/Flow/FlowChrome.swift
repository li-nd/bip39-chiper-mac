//
//  FlowChrome.swift
//  Bip39Chiper
//

import SwiftUI

struct FlowChrome<Content: View>: View {
    let title: String
    let subtitle: String
    var stepIndex: Int? = nil
    var stepLabels: [String]? = nil
    var onBack: (() -> Void)?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                if let onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 32, height: 32)
                            .appButtonChrome(fill: AppTheme.panel, cornerRadius: 8)
                    }
                    .appPlainButton(cornerRadius: 8)
                    .keyboardShortcut(.escape, modifiers: [])
                    .padding(.trailing, 8)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("BIP39 CHIPER")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(AppTheme.accent)
                    Text(title)
                        .font(.system(size: 28, weight: .semibold, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 12)

            if let stepIndex, let stepLabels, !stepLabels.isEmpty {
                StepIndicator(current: stepIndex, labels: stepLabels)
            }

            content()
        }
    }
}
