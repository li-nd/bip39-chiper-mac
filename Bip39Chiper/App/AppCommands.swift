//
//  AppCommands.swift
//  Bip39Chiper
//

import SwiftUI

struct AppCommands: Commands {
    @ObservedObject var navigation: AppNavigation
    @ObservedObject var settings: AppSettings

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button(L10n.menuAbout()) {
                navigation.showAbout = true
            }
        }

        CommandMenu(L10n.menuNavigate) {
            Button(L10n.home) {
                navigation.goHome()
            }
            .keyboardShortcut("1", modifiers: .command)

            Divider()

            Button(L10n.homeEncrypt) {
                navigation.goEncrypt()
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])

            Button(L10n.homeDecrypt) {
                navigation.goDecrypt()
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
        }
    }
}
