//
//  ToastCenter.swift
//  Bip39Chiper
//

import Combine
import SwiftUI

@MainActor
final class ToastCenter: ObservableObject {
    @Published private(set) var message: String?
    @Published private(set) var isError = false

    private var dismissTask: Task<Void, Never>?

    func show(_ text: String, error: Bool = false, duration: TimeInterval = 4) {
        dismissTask?.cancel()
        message = text
        isError = error
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            if message == text {
                dismiss()
            }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        message = nil
        isError = false
    }
}

struct ToastOverlay: View {
    @ObservedObject var toast: ToastCenter

    var body: some View {
        VStack {
            if let message = toast.message {
                HStack(spacing: 10) {
                    Image(systemName: toast.isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(toast.isError ? AppTheme.danger : AppTheme.success)
                    Text(message)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    Button {
                        toast.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .appPlainButton(cornerRadius: 8)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.panel)
                        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(toast.isError ? AppTheme.danger.opacity(0.5) : AppTheme.success.opacity(0.4), lineWidth: 1)
                )
                .padding(.horizontal, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .animation(.easeInOut(duration: 0.2), value: toast.message)
        .allowsHitTesting(toast.message != nil)
    }
}

enum FocusHelper {
    /// Defers focus until after SwiftUI finishes a step transition.
    static func afterTransition(_ action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: action)
    }
}
