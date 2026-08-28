//
//  Bip39ChiperApp.swift
//  Bip39Chiper
//

import SwiftUI

@main
struct Bip39ChiperApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var toast = ToastCenter()
    @StateObject private var navigation = AppNavigation()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(toast)
                .environmentObject(navigation)
                .environment(\.locale, settings.activeLocale)
                .environment(\.layoutDirection, settings.layoutDirection)
                .id(settings.localizationRevision)
                .sheet(isPresented: $navigation.showAbout) {
                    AboutView()
                }
        }
        .windowResizability(.contentSize)
        .windowStyle(.titleBar)
        .commands {
            AppCommands(navigation: navigation, settings: settings)
        }

        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(navigation)
                .environment(\.locale, settings.activeLocale)
                .environment(\.layoutDirection, settings.layoutDirection)
                .id(settings.localizationRevision)
        }
    }
}
