//
//  SettingsView.swift
//  Bip39Chiper
//

import AppKit
import SwiftUI

private enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case encryption

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: L10n.settingsTabGeneral
        case .encryption: L10n.settingsTabEncryption
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var navigation: AppNavigation
    @State private var selectedTab: SettingsTab = .general

    private let contentHeight: CGFloat = 380

    var body: some View {
        ZStack {
            AppBackground()
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.settingsTitle)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)

                tabBar

                tabContentPanel
                    .frame(height: contentHeight, alignment: .topLeading)
            }
            .padding(20)
            .frame(width: 480, height: 520, alignment: .topLeading)
        }
        .frame(width: 480, height: 520)
        .preferredColorScheme(.dark)
        .onAppear { settings.clampIterations() }
        .onDisappear { settings.clampIterations() }
    }

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(SettingsTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(4)
        .appButtonChrome(fill: AppTheme.wordCell, cornerRadius: 10, showStroke: false)
    }

    private func tabButton(_ tab: SettingsTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            Text(tab.title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .appButtonChrome(
                    fill: isSelected ? AppTheme.accent : AppTheme.panel,
                    stroke: isSelected ? AppTheme.accent : AppTheme.panelStroke,
                    cornerRadius: 8,
                    showStroke: !isSelected
                )
                .foregroundStyle(isSelected ? AppTheme.onAccent : AppTheme.textSecondary)
        }
        .appPlainButton(cornerRadius: 8)
    }

    private var tabContentPanel: some View {
        ZStack(alignment: .topLeading) {
            generalTab
                .opacity(selectedTab == .general ? 1 : 0)
                .allowsHitTesting(selectedTab == .general)

            encryptionTab
                .opacity(selectedTab == .encryption ? 1 : 0)
                .allowsHitTesting(selectedTab == .encryption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipped()
    }

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            settingsSection(title: L10n.settingsSectionLanguage) {
                settingsMenuRow(label: L10n.settingsLanguage) {
                    languagePicker
                }
            }

            settingsSection(title: L10n.settingsSectionHelp) {
                SecondaryButton(
                    title: L10n.settingsShowOnboarding,
                    systemImage: "questionmark.circle",
                    action: showOnboardingAgain
                )
            }
        }
    }

    private func showOnboardingAgain() {
        navigation.presentOnboarding()
        NSApp.activate(ignoringOtherApps: true)
    }

    private var languagePicker: some View {
        Picker("", selection: $settings.appLanguage) {
            Text(L10n.settingsLanguageSystem).tag(AppLanguage.system)
            ForEach(AppLanguage.pickerLanguages.sorted {
                $0.pickerLabel(systemOptionTitle: "") < $1.pickerLabel(systemOptionTitle: "")
            }) { language in
                Text(language.pickerLabel(systemOptionTitle: L10n.settingsLanguageSystem))
                    .tag(language)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .tint(AppTheme.accent)
    }

    private var encryptionTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            warningBanner

            settingsSection(title: L10n.settingsSectionFormat) {
                settingsMenuRow(label: L10n.settingsVersion) {
                    Picker("", selection: $settings.formatVersion) {
                        ForEach(CipherFormatVersion.allCases) { version in
                            Text(version.displayName).tag(version)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(AppTheme.accent)
                }
            }

            settingsSection(title: L10n.settingsSectionDefaultPhrase) {
                settingsMenuRow(label: L10n.settingsDefaultPhraseLength) {
                    Picker("", selection: $settings.defaultWordCount) {
                        ForEach(MnemonicWordCount.allCases) { count in
                            Text(count.label).tag(count)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(AppTheme.accent)
                }
            }

            settingsSection(title: L10n.settingsSectionPassword) {
                settingsMenuRow(label: L10n.settingsIterations) {
                    Picker("", selection: $settings.pbkdf2Iterations) {
                        ForEach(AppSettings.iterationPresets, id: \.self) { value in
                            Text(presetTitle(value)).tag(value)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(AppTheme.accent)
                }

                Text(L10n.settingsIterationsHint)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                settingsMenuRow(label: L10n.settingsKeySize) {
                    keySizePicker
                }
            }
        }
    }

    private var warningBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.accent)
            Text(L10n.settingsCompatWarning)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appButtonChrome(fill: AppTheme.wordCell, cornerRadius: 12)
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appButtonChrome(fill: AppTheme.panel, cornerRadius: 14)
    }

    private var keySizePicker: some View {
        HStack(spacing: 8) {
            ForEach(AppSettings.keyLengthOptions, id: \.self) { value in
                let selected = settings.derivedKeyByteCount == value
                Button {
                    settings.derivedKeyByteCount = value
                } label: {
                    Text(keyLengthTitle(value))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .frame(width: 36)
                        .padding(.vertical, 7)
                        .appButtonChrome(
                            fill: selected ? AppTheme.accentSoft : AppTheme.panel,
                            stroke: selected ? AppTheme.accent.opacity(0.7) : AppTheme.panelStroke,
                            cornerRadius: 9
                        )
                        .foregroundStyle(selected ? AppTheme.accent : AppTheme.textSecondary)
                }
                .appPlainButton(cornerRadius: 9)
            }
        }
    }

    private func settingsMenuRow<Control: View>(label: String, @ViewBuilder control: () -> Control) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer(minLength: 8)
            control()
        }
    }

    private func presetTitle(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func keyLengthTitle(_ value: Int) -> String {
        switch value {
        case 16: return "16"
        case 32: return "32"
        case 64: return "64"
        default: return "\(value)"
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
        .environmentObject(AppNavigation())
}
