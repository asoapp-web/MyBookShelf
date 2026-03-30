//
//  MyBookShelfApp.swift
//  MyBookShelf
//

import CoreData
import SwiftUI

@main
struct MyBookShelfApp: App {
    let persistence = PersistenceController.shared
    /// Uses `UserDefaults` so “Show onboarding again” in Settings applies without relaunching.
    @AppStorage(OnboardingUserDefaults.completedKey) private var hasCompletedOnboardingFlag = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboardingFlag {
                    OnboardingView(isComplete: Binding(
                        get: { hasCompletedOnboardingFlag },
                        set: { hasCompletedOnboardingFlag = $0 }
                    ))
                } else {
                    MainTabView()
                        .environment(\.managedObjectContext, persistence.container.viewContext)
                        .onAppear {
                            Task { @MainActor in
                                persistence.ensureUserProfile()
                            }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.35), value: hasCompletedOnboardingFlag)
        }
    }
}
