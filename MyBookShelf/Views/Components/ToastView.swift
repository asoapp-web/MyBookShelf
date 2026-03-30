//
//  ToastView.swift
//  MyBookShelf
//

import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    let duration: Double

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            if let msg = message {
                Text(msg)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(AppTheme.accentOrange)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                    .padding(.top, 50)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: message)
        .onChange(of: message) { new in
            guard new != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                message = nil
            }
        }
    }
}

extension View {
    func toast(_ message: Binding<String?>, duration: Double = 2) -> some View {
        modifier(ToastModifier(message: message, duration: duration))
    }
}
