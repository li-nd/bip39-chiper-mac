//
//  AboutView.swift
//  Bip39Chiper
//

import AppKit
import SwiftUI

private enum AboutLinks {
    static let appName = "Bip39Chiper"
    static let repository = URL(string: "https://github.com/li-nd/bip39-chiper-mac")!
    static let documentation = URL(string: "https://chiper.developer.pm/")!
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var versionLine: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    private var copyrightYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(spacing: 6) {
                Text(AboutLinks.appName)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(versionLine)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Text(L10n.aboutAuthor)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)

            aboutLink(AboutLinks.repository)
            aboutLink(AboutLinks.documentation)

            Text(L10n.aboutCopyright(copyrightYear))
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.top, 4)

            PrimaryButton(title: L10n.close, action: { dismiss() })
                .frame(width: 120)
                .padding(.top, 8)
        }
        .padding(28)
        .frame(width: 360)
        .background(AppTheme.panel)
        .preferredColorScheme(.dark)
    }

    private func aboutLink(_ url: URL) -> some View {
        Link(destination: url) {
            Text(url.absoluteString)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(AppTheme.accent)
                .multilineTextAlignment(.center)
        }
        .pointingHandCursor()
    }
}

private extension View {
    func pointingHandCursor() -> some View {
        onHover { inside in
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
