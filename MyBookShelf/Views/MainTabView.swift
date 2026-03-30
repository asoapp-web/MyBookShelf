//
//  MainTabView.swift
//  MyBookShelf
//

import SwiftUI
import UIKit

struct MainTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var floatingTabChrome = FloatingTabBarChrome()
    @StateObject private var gamificationBadgeObserver = GamificationBadgeObserver()

    /// Custom floating pill + clearance used on iOS 16–17 (and as fallback).
    private let legacyTabClearance: CGFloat = 124
    /// With system `TabView`, the tab bar participates in safe area — only a small FAB margin.
    private let systemTabExtraClearance: CGFloat = 8

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                SystemShellTabView(bottomExtraInset: systemTabExtraClearance)
            } else {
                LegacyFloatingTabShell(bottomInset: legacyTabClearance)
            }
        }
        .environmentObject(floatingTabChrome)
        .environmentObject(gamificationBadgeObserver)
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            NotificationCenter.default.post(name: .myBookShelfQuestCalendarTick, object: nil)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                NotificationCenter.default.post(name: .myBookShelfQuestCalendarTick, object: nil)
            }
        }
    }
}

// MARK: - iOS 18+ system TabView (Liquid Glass / floating tab bar on iOS 26)

@available(iOS 18.0, *)
private struct SystemShellTabView: View {
    let bottomExtraInset: CGFloat
    @EnvironmentObject private var gamificationBadgeObserver: GamificationBadgeObserver
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Shelf", systemImage: "books.vertical", value: 0) {
                ShelfView(tabBarHeight: bottomExtraInset)
            }
            Tab("Search", systemImage: "magnifyingglass", value: 1) {
                SearchView(tabBarHeight: bottomExtraInset)
            }
            Tab("Rewards", systemImage: "trophy.fill", value: 2) {
                rewardsRoot(badgeCount: gamificationBadgeObserver.unreadCount)
            }
            Tab("Stats", systemImage: "chart.bar", value: 3) {
                StatsView(tabBarHeight: bottomExtraInset)
            }
            Tab("Profile", systemImage: "person.circle", value: 4) {
                ProfileView(tabBarHeight: bottomExtraInset)
            }
        }
        .tint(AppTheme.accentOrange)
        .modifier(TabBarMinimizeBehaviorIfAvailable())
        .onChange(of: selectedTab) { _, _ in
            HapticsService.shared.selection()
        }
    }

    /// System tab item badge attaches to the tab’s root view (iOS 18+).
    @ViewBuilder
    private func rewardsRoot(badgeCount: Int) -> some View {
        if badgeCount > 0 {
            RewardsHubView()
                .badge(min(99, badgeCount))
        } else {
            RewardsHubView()
        }
    }
}

/// iOS 26+: system minimizes / floats the tab bar with scroll; no custom overlay fighting layout.
private struct TabBarMinimizeBehaviorIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.automatic)
        } else {
            content
        }
    }
}

// MARK: - iOS 16–17 custom floating tab bar

private struct LegacyFloatingTabShell: View {
    let bottomInset: CGFloat
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background
                .ignoresSafeArea()
            Group {
                switch selectedTab {
                case 0:
                    ShelfView(tabBarHeight: bottomInset)
                case 1:
                    SearchView(tabBarHeight: bottomInset)
                case 2:
                    RewardsHubView()
                case 3:
                    StatsView(tabBarHeight: bottomInset)
                case 4:
                    ProfileView(tabBarHeight: bottomInset)
                default:
                    ShelfView(tabBarHeight: bottomInset)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingGlassTabBar(selection: $selectedTab)
                .padding(.bottom, 6)
        }
    }
}
