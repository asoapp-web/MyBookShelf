//
//  SearchView.swift
//  MyBookShelf
//

import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @State private var mode = 0
    @State private var selectedDoc: OpenLibraryDoc?
    @FocusState private var searchFocused: Bool
    var tabBarHeight: CGFloat = 118

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    TextField("Search books...", text: $vm.query)
                        .focused($searchFocused)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppTheme.backgroundSecondary)
                        .onSubmit { vm.search() }

                    Picker("", selection: $mode) {
                        Text("Search online").tag(0)
                        Text("Add manually").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    if mode == 0 {
                        if vm.isLoading {
                            Spacer()
                            ProgressView()
                                .tint(AppTheme.accentOrange)
                            Spacer()
                        } else if let err = vm.errorMessage {
                            Spacer()
                            EmptyStateView(icon: "wifi.slash", title: "Error", message: err)
                            Spacer()
                        } else if vm.results.isEmpty && vm.hasSearched {
                            Spacer()
                            EmptyStateView(icon: "magnifyingglass", title: "No results", message: "Try a different search.")
                            Spacer()
                        } else if vm.results.isEmpty {
                            Spacer()
                            Text("Search for books by title or author")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textMuted)
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(Array(vm.results.enumerated()), id: \.offset) { _, doc in
                                        SearchResultRow(doc: doc) {
                                            selectedDoc = doc
                                        }
                                    }
                                }
                                .padding(16)
                                .padding(.bottom, tabBarHeight + 24)
                            }
                        }
                    } else {
                        ManualAddBookView(tabBarClearance: tabBarHeight + 36)
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.background.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedDoc) { doc in
                BookPreviewSheet(doc: doc, vm: vm, onDismiss: { selectedDoc = nil })
            }
            .onChange(of: vm.query) { _ in
                vm.search()
            }
        }
    }
}

struct SearchResultRow: View {
    let doc: OpenLibraryDoc
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                if let coverId = doc.cover_i {
                    AsyncBookCover(
                        urlString: NetworkService.coverURL(coverId: coverId, size: "S"),
                        size: CGSize(width: 50, height: 75)
                    )
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.backgroundTertiary)
                        .frame(width: 50, height: 75)
                        .overlay(Image(systemName: "book.closed").foregroundStyle(AppTheme.textMuted))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(doc.title ?? "Unknown")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)
                    Text(doc.author_name?.joined(separator: ", ") ?? "Unknown")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    HStack(spacing: 8) {
                        if let year = doc.first_publish_year {
                            Text("\(year)")
                        }
                        if let pages = doc.number_of_pages_median {
                            Text("· \(pages) p.")
                        }
                        if let rating = doc.ratings_average, rating > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                Text(String(format: "%.1f", rating))
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(12)
            .background(AppTheme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

extension OpenLibraryDoc: @retroactive Identifiable {
    public var id: String { key ?? UUID().uuidString }
}
