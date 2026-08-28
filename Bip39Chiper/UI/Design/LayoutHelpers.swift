//
//  LayoutHelpers.swift
//  Bip39Chiper
//

import SwiftUI

extension View {
    /// Keeps BIP-39 words, codes, and monospaced crypto input left-to-right in RTL locales.
    func ltrContent() -> some View {
        environment(\.layoutDirection, .leftToRight)
    }
}
