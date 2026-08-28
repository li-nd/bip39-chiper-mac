//
//  AppNavigation.swift
//  Bip39Chiper
//

import Combine
import SwiftUI

enum AppRoute: Equatable {
    case home
    case encrypt
    case decrypt
}

@MainActor
final class AppNavigation: ObservableObject {
    @Published var route: AppRoute = .home
    @Published var showAbout = false
    @Published var showOnboarding = false

    func goHome() { route = .home }
    func goEncrypt() { route = .encrypt }
    func goDecrypt() { route = .decrypt }

    func presentOnboarding() {
        goHome()
        showOnboarding = true
    }
}
