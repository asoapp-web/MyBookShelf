//
//  Theme.swift
//  MyBookShelf
//

import SwiftUI

enum AppTheme {
    static let background = Color(hex: "#0D0D0D") ?? Color(red: 0.05, green: 0.05, blue: 0.05)
    static let backgroundSecondary = Color(hex: "#1A1A1A") ?? Color(red: 0.1, green: 0.1, blue: 0.1)
    static let backgroundTertiary = Color(hex: "#252525") ?? Color(red: 0.15, green: 0.15, blue: 0.15)
    static let accentOrange = Color(hex: "#FF6B00") ?? Color.orange
    static let accentOrangeLight = Color(hex: "#FF8C42") ?? Color.orange
    static let accentOrangeDark = Color(hex: "#E55A00") ?? Color.orange
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#B0B0B0") ?? Color.gray
    static let textMuted = Color(hex: "#6B6B6B") ?? Color.gray
    static let divider = Color(hex: "#2E2E2E") ?? Color.gray

    /// Shelf / cabinet wood accents
    static let shelfWood = Color(hex: "#2C1F12") ?? Color(red: 0.17, green: 0.12, blue: 0.07)
    static let shelfWoodLight = Color(hex: "#4A3520") ?? Color(red: 0.29, green: 0.2, blue: 0.13)
    static let shelfGlassHighlight = Color.white.opacity(0.22)
}

extension Color {
    /// Parses `#RRGGBB` or `RRGGBB` for theme / shelf accents.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let n = UInt32(s, radix: 16) else { return nil }
        let r = Double((n >> 16) & 0xFF) / 255
        let g = Double((n >> 8) & 0xFF) / 255
        let b = Double(n & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
