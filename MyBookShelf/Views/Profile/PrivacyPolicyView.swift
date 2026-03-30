//
//  PrivacyPolicyView.swift
//  MyBookShelf
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your reading life stays on your device. MyBookShelf is built for local use: we don’t run analytics, ads, or background tracking.")
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary)

                policyBlock(
                    title: "What we don’t collect",
                    body: "We don’t ask for an account. We don’t upload your library, notes, streaks, or profile to our servers—there’s no central database of your books. Nothing is sold to third parties."
                )

                policyBlock(
                    title: "Camera & photos",
                    body: "The camera and photo library are used only when you choose to add a book cover or a profile picture. Those images are saved locally on your iPhone, like the rest of your data."
                )

                policyBlock(
                    title: "Your control",
                    body: "You can remove a custom photo anytime in Edit profile, change book covers in the book editor, or erase everything with “Reset all progress” in Settings (this deletes local app data)."
                )

                Text("If you have questions, use the support channel listed on the App Store page for this app.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(AppTheme.background)
        .navigationTitle("Privacy policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.background.opacity(0.95), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .suppressesFloatingTabBar()
        .toolbar(.hidden, for: .tabBar)
    }

    private func policyBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
