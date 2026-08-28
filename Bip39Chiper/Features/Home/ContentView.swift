//
//  ContentView.swift
//  Bip39Chiper
//

import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var toast: ToastCenter
    @EnvironmentObject private var navigation: AppNavigation
    @Environment(\.openSettings) private var openSettings
    @State private var showOnboarding = false

    private let windowWidth: CGFloat = 560
    private let windowHeight: CGFloat = 760

    var body: some View {
        ZStack {
            AppBackground()

            Group {
                switch navigation.route {
                case .home:
                    home
                case .encrypt:
                    EncryptFlowView { navigation.goHome() }
                case .decrypt:
                    DecryptFlowView { navigation.goHome() }
                }
            }
            .padding(28)

            ToastOverlay(toast: toast)
                .padding(.top, 8)
                .padding(.horizontal, 28)
        }
        .frame(width: windowWidth, height: windowHeight)
        .preferredColorScheme(.dark)
        .onAppear {
            if !settings.hasSeenOnboarding {
                showOnboarding = true
            }
        }
        .onChange(of: navigation.showOnboarding) { _, requested in
            if requested {
                showOnboarding = true
                navigation.showOnboarding = false
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingSheet {
                settings.hasSeenOnboarding = true
                showOnboarding = false
            }
        }
    }

    private var home: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("BIP39 CHIPER")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .tracking(2.4)
                    .foregroundStyle(AppTheme.accent)
                Spacer()
                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 36, height: 36)
                        .appButtonChrome(fill: AppTheme.panel, cornerRadius: 10)
                }
                .appPlainButton(cornerRadius: 10)
                .help(L10n.homeSettingsHelp)
            }
            .padding(.bottom, 8)

            Text(L10n.homeTitle)
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.bottom, 8)

            Text(L10n.homeSubtitle)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.bottom, 8)

            Text(settingsSummaryLine)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.accent.opacity(0.85))
                .padding(.bottom, 20)

            VStack(spacing: 12) {
                homeCard(
                    title: L10n.homeEncrypt,
                    subtitle: L10n.homeEncryptSubtitle,
                    icon: "lock.fill"
                ) {
                    navigation.goEncrypt()
                }

                homeCard(
                    title: L10n.homeDecrypt,
                    subtitle: L10n.homeDecryptSubtitle,
                    icon: "lock.open.fill"
                ) {
                    navigation.goDecrypt()
                }
            }

            Spacer()
        }
    }

    private var settingsSummaryLine: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let iter = formatter.string(from: NSNumber(value: settings.pbkdf2Iterations)) ?? "\(settings.pbkdf2Iterations)"
        return L10n.homeSettingsSummary(settings.defaultWordCount.rawValue, iter, settings.derivedKeyByteCount)
    }

    private func homeCard(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HoverHomeCard {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppTheme.onAccent)
                        .frame(width: 52, height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppTheme.accent)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(subtitle)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()
                    Image(systemName: "chevron.forward")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(18)
            }
        }
        .appPlainButton(cornerRadius: 16)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings())
        .environmentObject(ToastCenter())
        .environmentObject(AppNavigation())
}
