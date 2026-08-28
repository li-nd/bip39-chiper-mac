//
//  AppBackground.swift
//  Bip39Chiper
//

import SwiftUI

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.bgTop, AppTheme.bgBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(AppTheme.accent.opacity(0.07))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: 260, y: -280)
        }
        .ignoresSafeArea()
    }
}
