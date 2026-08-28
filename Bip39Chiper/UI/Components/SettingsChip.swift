//
//  SettingsChip.swift
//  Bip39Chiper
//

import SwiftUI

struct SettingsChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .appButtonChrome(fill: AppTheme.wordCell, cornerRadius: 8)
    }
}
