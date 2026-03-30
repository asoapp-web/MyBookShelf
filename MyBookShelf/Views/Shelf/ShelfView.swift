//
//  ShelfView.swift
//  MyBookShelf
//

import SwiftUI
import CoreData

struct ShelfView: View {
    @StateObject private var vm: ShelfViewModel
    @StateObject private var shelfProfileVM = ProfileViewModel()
    @State private var showAddBook = false
    @State private var showDeleteConfirm: Book?
    @State private var showCabinetGallery = false
    @State private var showBookTreeComingSoon = false
    @State private var curtainOpacity: Double = 0
    @State private var cabinetContentOpacity: Double = 0
    var tabBarHeight: CGFloat = 118

    init(tabBarHeight: CGFloat = 118) {
        _vm = StateObject(wrappedValue: ShelfViewModel(context: PersistenceController.shared.container.viewContext))
        self.tabBarHeight = tabBarHeight
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.09, blue: 0.07),
                        AppTheme.background,
                        AppTheme.backgroundSecondary,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                RadialGradient(
                    colors: [AppTheme.shelfWood.opacity(0.35), Color.clear],
                    center: .top,
                    startRadius: 40,
                    endRadius: 420
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                LinearGradient(
                    colors: [Color.white.opacity(0.06), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    ShelfGamificationStrip(profileVM: shelfProfileVM)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)

                    NavigationLink {
                        ReadingStreakHubView()
                    } label: {
                        ShelfStreakEntryCard(
                            currentStreak: Int(shelfProfileVM.profile?.currentStreak ?? 0),
                            longestStreak: Int(shelfProfileVM.profile?.longestStreak ?? 0)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    Picker("", selection: Binding(
                        get: { vm.filter },
                        set: { vm.setFilter($0) }
                    )) {
                        ForEach(ShelfFilter.allCases, id: \.rawValue) { f in
                            Text(f.label).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                if vm.books.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "books.vertical",
                        title: "Your shelf is empty",
                        message: "Add your first book to get started. Tap + next to the title to search or add manually."
                    )
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 24) {
                            ShelfRow(
                                books: Array(vm.books.prefix(3)),
                                onDelete: { showDeleteConfirm = $0 },
                                onUpdate: { vm.fetch() },
                                showLiquidGlass: true,
                                extraHiddenBookCount: max(0, vm.books.count - 3),
                                onGlassTap: { openCabinetGallery() }
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, tabBarHeight + 16)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar(showCabinetGallery ? .hidden : .automatic, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 12) {
                        Text("My Shelf")
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer(minLength: 0)
                        HStack(spacing: 8) {
                            Button {
                                HapticsService.shared.light()
                                showBookTreeComingSoon = true
                            } label: {
                                Image(systemName: "tree.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppTheme.shelfWoodLight)
                                    .frame(width: 34, height: 34)
                                    .background(AppTheme.backgroundTertiary)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Book tree")
                            Button {
                                HapticsService.shared.light()
                                showAddBook = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 34, height: 34)
                                    .background(
                                        LinearGradient(
                                            colors: [AppTheme.accentOrange, AppTheme.accentOrangeDark],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Add book")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .sheet(isPresented: $showAddBook) {
                AddBookFlowView(onDismiss: {
                    showAddBook = false
                    vm.fetch()
                })
            }
            .sheet(isPresented: $showBookTreeComingSoon) {
                BookTreeComingSoonSheet()
            }
            .alert("Delete book?", isPresented: Binding(
                get: { showDeleteConfirm != nil },
                set: { if !$0 { showDeleteConfirm = nil } }
            )) {
                Button("Cancel", role: .cancel) { showDeleteConfirm = nil }
                Button("Delete", role: .destructive) {
                    if let b = showDeleteConfirm {
                        vm.delete(b)
                        showDeleteConfirm = nil
                        vm.fetch()
                    }
                }
            } message: {
                Text("This cannot be undone.")
            }

            if showCabinetGallery {
                CabinetGalleryView(
                    shelfVM: vm,
                    onDismiss: { closeCabinetGallery() },
                    onBooksChanged: { vm.fetch() }
                )
                .opacity(cabinetContentOpacity)
                .transition(.opacity)
                .zIndex(10)
                .ignoresSafeArea()
                .suppressesFloatingTabBar()
            }

            Color.black
                .opacity(curtainOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(curtainOpacity > 0.35)
                .zIndex(20)
            }
        }
        .onAppear {
            vm.fetch()
            shelfProfileVM.fetch()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSManagedObjectContext.didSaveObjectsNotification, object: PersistenceController.shared.container.viewContext)) { _ in
            vm.fetch()
            shelfProfileVM.fetch()
        }
    }

    private func openCabinetGallery() {
        HapticsService.shared.light()
        cabinetContentOpacity = 0
        withAnimation(.easeIn(duration: 0.24)) {
            curtainOpacity = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            showCabinetGallery = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                withAnimation(.easeOut(duration: 0.4)) {
                    curtainOpacity = 0
                    cabinetContentOpacity = 1
                }
            }
        }
    }

    private func closeCabinetGallery() {
        withAnimation(.easeIn(duration: 0.24)) {
            curtainOpacity = 1
            cabinetContentOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            showCabinetGallery = false
            withAnimation(.easeOut(duration: 0.28)) {
                curtainOpacity = 0
            }
            cabinetContentOpacity = 0
        }
    }
}

// MARK: - Book tree (placeholder — full `ShelfBookTreeView` returns in a future update)

private struct BookTreeComingSoonSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(AppTheme.shelfWood.opacity(0.35))
                        .frame(width: 120, height: 120)
                    Image(systemName: "tree.fill")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(AppTheme.shelfWoodLight)
                }
                .padding(.top, 8)

                VStack(spacing: 10) {
                    Text("Book tree")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Coming soon")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accentOrange)
                }

                Text("The reading tree is coming back to My Shelf. This button will open the full interactive tree again—we’re polishing the experience for a future release.")
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)

                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background)
            .navigationTitle("Book tree")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

struct ShelfRow: View {
    let books: [Book]
    let onDelete: (Book) -> Void
    var onUpdate: (() -> Void)?
    var showLiquidGlass: Bool = false
    var extraHiddenBookCount: Int = 0
    var onGlassTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.shelfWoodLight.opacity(0.9), AppTheme.shelfWood],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 6)
                .padding(.horizontal, 28)
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), AppTheme.shelfWoodLight.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 5
                    )
                    .padding(-2)

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(showLiquidGlass ? 0.45 : 0.92)

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppTheme.shelfGlassHighlight,
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.14),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.35), lineWidth: 0.5)
                    .blur(radius: 0.5)
                    .offset(y: 1)
                    .mask(RoundedRectangle(cornerRadius: 22, style: .continuous))

                HStack(spacing: 0) {
                    ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                        if index > 0 {
                            shelfVerticalDivider
                        }
                        Group {
                            if showLiquidGlass {
                                BookCardView(book: book, onDelete: onDelete, onUpdate: onUpdate, usesShelfChrome: false)
                                    .id(bookCardIdentity(book))
                            } else {
                                NavigationLink(destination: BookDetailView(book: book, onDelete: onUpdate)) {
                                    BookCardView(book: book, onDelete: onDelete, onUpdate: onUpdate, usesShelfChrome: true)
                                        .id(bookCardIdentity(book))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 14)

                if showLiquidGlass {
                    liquidGlassOverlay
                }
            }
            .shadow(color: .black.opacity(0.35), radius: 16, y: 8)

            if showLiquidGlass {
                Text("Tap the glass to open the cabinet and see your full library.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
            }

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.shelfWoodLight, AppTheme.shelfWood],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 12)
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 4)
                }
                .shadow(color: .black.opacity(0.55), radius: 10, y: 5)
                .padding(.horizontal, 10)
                .offset(y: -2)
        }
        .padding(.bottom, 8)
    }

    private var shelfVerticalDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.2), Color.white.opacity(0.04), Color.white.opacity(0.15)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2)
            .padding(.vertical, 18)
            .shadow(color: .black.opacity(0.35), radius: 1, y: 0)
    }

    private var liquidGlassOverlay: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.42, green: 0.72, blue: 0.95).opacity(0.42),
                            Color(red: 0.22, green: 0.48, blue: 0.78).opacity(0.28),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.55)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.72),
                                    Color.cyan.opacity(0.35),
                                    Color.white.opacity(0.22),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.6
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.38), Color.white.opacity(0.06), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .allowsHitTesting(false)
                )
                .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .onTapGesture {
                    onGlassTap?()
                }

            if extraHiddenBookCount > 0 {
                Text("+\(extraHiddenBookCount)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(AppTheme.accentOrange)
                            .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                    )
                    .padding(12)
                    .allowsHitTesting(false)
            }
        }
    }

    private func bookCardIdentity(_ book: Book) -> String {
        "\(book.objectID)-\(book.currentPage)-\(book.status)-\(book.isFavorite)-\(book.rating)-\(book.progressPercent)"
    }
}
