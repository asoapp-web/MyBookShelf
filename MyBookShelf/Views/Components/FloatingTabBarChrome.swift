//
//  FloatingTabBarChrome.swift
//  MyBookShelf
//

import Combine
import SwiftUI

/// Hides the custom floating tab bar while a pushed (or full-screen) child is visible.
final class FloatingTabBarChrome: ObservableObject {
    @Published private var depth = 0
    var isHidden: Bool { depth > 0 }

    func push() {
        depth += 1
    }

    func pop() {
        depth = max(0, depth - 1)
    }
}

private struct SuppressFloatingTabBarModifier: ViewModifier {
    @EnvironmentObject private var chrome: FloatingTabBarChrome

    func body(content: Content) -> some View {
        content
            .onAppear { chrome.push() }
            .onDisappear { chrome.pop() }
    }
}

extension View {
    func suppressesFloatingTabBar() -> some View {
        modifier(SuppressFloatingTabBarModifier())
    }
}
