//
//  AddBookFlowView.swift
//  MyBookShelf
//

import SwiftUI

struct AddBookFlowView: View {
    let onDismiss: () -> Void
    @State private var mode = 0
    @StateObject private var searchVm = SearchViewModel()
    @State private var selectedDoc: OpenLibraryDoc?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    Picker("", selection: $mode) {
                        Text("Search online").tag(0)
                        Text("Add manually").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(16)

                    if mode == 0 {
                        searchContent
                    } else {
                        ManualAddBookView(onBookAdded: onDismiss)
                    }
                }
            }
            .navigationTitle("Add book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onDismiss() }
                }
            }
            .sheet(item: $selectedDoc) { doc in
                BookPreviewSheet(doc: doc, vm: searchVm, onDismiss: {
                    selectedDoc = nil
                    onDismiss()
                })
            }
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        VStack(spacing: 12) {
            TextField("Search books...", text: $searchVm.query)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 16)
                .onSubmit { searchVm.search() }

            if searchVm.isLoading {
                Spacer()
                ProgressView().tint(AppTheme.accentOrange)
                Spacer()
            } else if let err = searchVm.errorMessage {
                Spacer()
                EmptyStateView(icon: "wifi.slash", title: "Error", message: err)
                Spacer()
            } else if searchVm.results.isEmpty && searchVm.hasSearched {
                Spacer()
                EmptyStateView(icon: "magnifyingglass", title: "No results", message: "Try a different search.")
                Spacer()
            } else if searchVm.results.isEmpty {
                Spacer()
                Text("Search for books by title or author")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textMuted)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(searchVm.results.enumerated()), id: \.offset) { _, doc in
                            SearchResultRow(doc: doc) {
                                selectedDoc = doc
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .onChange(of: searchVm.query) { _ in
            searchVm.search()
        }
    }
}
