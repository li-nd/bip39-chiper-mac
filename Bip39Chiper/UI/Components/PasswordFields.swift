//
//  PasswordFields.swift
//  Bip39Chiper
//

import SwiftUI

enum PasswordStrength: Int {
    case empty = 0
    case weak
    case fair
    case strong

    var label: String {
        switch self {
        case .empty: return ""
        case .weak: return L10n.passwordStrengthWeak
        case .fair: return L10n.passwordStrengthFair
        case .strong: return L10n.passwordStrengthStrong
        }
    }

    var color: Color {
        switch self {
        case .empty: return AppTheme.panelStroke
        case .weak: return AppTheme.danger
        case .fair: return AppTheme.accent
        case .strong: return AppTheme.success
        }
    }

    static func evaluate(_ password: String) -> PasswordStrength {
        guard !password.isEmpty else { return .empty }
        if password.count < 8 { return .weak }
        var score = 0
        if password.count >= 12 { score += 1 }
        if password.count >= 16 { score += 1 }
        if password.contains(where: \.isNumber) { score += 1 }
        if password.contains(where: \.isUppercase), password.contains(where: \.isLowercase) { score += 1 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { score += 1 }
        if score <= 1 { return .weak }
        if score <= 3 { return .fair }
        return .strong
    }
}

struct PasswordFields: View {
    enum Field: Hashable {
        case password
        case confirm
    }

    @Binding var password: String
    @Binding var confirm: String
    var requireConfirm: Bool = true
    var showStrength: Bool = false
    var autoFocus: Bool = false
    @State private var show = false
    @FocusState private var focusedField: Field?

    private var strength: PasswordStrength { PasswordStrength.evaluate(password) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.password)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Button {
                    show.toggle()
                } label: {
                    Image(systemName: show ? "eye.slash" : "eye")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .appPlainButton(cornerRadius: 8)
            }

            Group {
                if show {
                    TextField(L10n.passwordMinPlaceholder, text: $password)
                } else {
                    SecureField(L10n.passwordMinPlaceholder, text: $password)
                }
            }
            .textFieldStyle(.plain)
            .font(.system(size: 14, design: .monospaced))
            .padding(12)
            .appButtonChrome(fill: AppTheme.wordCell, cornerRadius: 10)
            .focused($focusedField, equals: .password)

            if showStrength, !password.isEmpty {
                HStack(spacing: 6) {
                    ForEach(1...3, id: \.self) { level in
                        Capsule()
                            .fill(strength.rawValue >= level ? strength.color : AppTheme.wordCell)
                            .frame(height: 4)
                    }
                    Text(strength.label)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(strength.color)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(strength.label)
            }

            if requireConfirm {
                Group {
                    if show {
                        TextField(L10n.passwordConfirmPlaceholder, text: $confirm)
                    } else {
                        SecureField(L10n.passwordConfirmPlaceholder, text: $confirm)
                    }
                }
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .monospaced))
                .padding(12)
                .appButtonChrome(fill: AppTheme.wordCell, cornerRadius: 10)
                .focused($focusedField, equals: .confirm)

                if !confirm.isEmpty, password != confirm {
                    Text(L10n.passwordMismatchInline)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.danger)
                }
            }
        }
        .ltrContent()
        .onAppear {
            guard autoFocus else { return }
            FocusHelper.afterTransition { focusedField = .password }
        }
    }
}
