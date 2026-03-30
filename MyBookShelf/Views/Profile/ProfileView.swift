//
//  ProfileView.swift
//  MyBookShelf
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    var tabBarHeight: CGFloat = 80

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let p = vm.profile {
                        profileHeader(p)
                        streakSection(p)
                        ProfileFavoritesEntryRow()
                        NavigationLink {
                            SettingsView()
                        } label: {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                Text("Settings")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(AppTheme.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                    } else {
                        ProgressView()
                            .tint(AppTheme.accentOrange)
                            .padding(40)
                    }
                }
                .padding(20)
                .padding(.bottom, tabBarHeight)
            }
            .background(AppTheme.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.background.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { vm.fetch() }
        }
    }

    private func xpProgressCaption(for p: UserProfile) -> String {
        let lvl = Int(p.currentLevel)
        let low = GamificationEngine.shared.xpForLevel(lvl)
        let high = GamificationEngine.shared.xpForLevel(lvl + 1)
        let inLevel = max(0, Int(p.totalXP) - low)
        let span = max(1, high - low)
        return "\(inLevel) / \(span) XP to level \(lvl + 1) · \(Int(p.totalXP)) total"
    }

    private func profileHeader(_ p: UserProfile) -> some View {
        VStack(spacing: 16) {
            Group {
                if let img = vm.profileAvatarUIImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: ProfileAvatarSymbolSet.names[min(Int(p.avatarIndex), ProfileAvatarSymbolSet.names.count - 1)])
                        .font(.system(size: 56))
                        .foregroundStyle(AppTheme.accentOrange)
                }
            }
            .frame(width: 100, height: 100)
            .background(AppTheme.backgroundTertiary)
            .clipShape(Circle())
            .overlay(Circle().stroke(AppTheme.accentOrange.opacity(0.35), lineWidth: 2))

            Text(p.displayName ?? "Reader")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)

            NavigationLink {
                EditProfileView(vm: vm)
            } label: {
                Text("Edit profile")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accentOrange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.accentOrange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Text("Level \(p.currentLevel)")
                .font(.headline)
                .foregroundStyle(AppTheme.textSecondary)
            ProgressBarView(progress: vm.progressToNext * 100)
                .frame(height: 8)
            Text(xpProgressCaption(for: p))
                .font(.caption)
                .foregroundStyle(AppTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AppTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func streakSection(_ p: UserProfile) -> some View {
        HStack(spacing: 20) {
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.accentOrange)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(p.currentStreak) days in a row")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Best: \(p.longestStreak) days")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(20)
        .background(AppTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

}
