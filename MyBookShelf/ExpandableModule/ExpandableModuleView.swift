//
//  ExpandableModuleView.swift
//  MyBookShelf
//

import SwiftUI

struct ExpandableModuleView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.textMuted)
            Text("Coming soon")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text("New content will appear here.")
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.inline)
        .suppressesFloatingTabBar()
        .toolbar(.hidden, for: .tabBar)
    }
}
