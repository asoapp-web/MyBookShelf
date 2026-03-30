//
//  BookDetailView.swift
//  MyBookShelf
//

import SwiftUI
import CoreData

struct BookDetailView: View {
    @ObservedObject var vm: BookDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showUpdateProgress = false
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    var onDelete: (() -> Void)?

    init(book: Book, onDelete: (() -> Void)? = nil) {
        _vm = ObservedObject(wrappedValue: BookDetailViewModel(book: book))
        self.onDelete = onDelete
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 20) {
                    BookCoverView(book: vm.book, size: CGSize(width: 110, height: 165))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(vm.book.title ?? "")
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(vm.book.author ?? "")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        if vm.book.publishYear > 0 {
                            Text("\(vm.book.publishYear)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        Text(vm.book.genre ?? "")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Status")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Picker("Status", selection: Binding(
                        get: { vm.book.statusEnum },
                        set: { vm.setStatus($0) }
                    )) {
                        ForEach(ReadingStatus.selectableCases(for: vm.book), id: \.rawValue) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                ProgressBarView(progress: vm.book.progressPercent)
                    .frame(height: 10)
                Text("Page \(vm.book.currentPage) of \(max(1, vm.book.totalPages)) (\(Int(vm.book.progressPercent))%)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                Button {
                    showUpdateProgress = true
                } label: {
                    Text("Update progress")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.accentOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                RatingSection(rating: vm.book.displayRating, onSelect: { newRating in
                    vm.setRating(newRating)
                })

                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    TextField("Add notes...", text: Binding(
                        get: { vm.book.notes ?? "" },
                        set: { vm.saveNotes($0) }
                    ), axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(AppTheme.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(AppTheme.textPrimary)
                }

                if !vm.sessions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reading sessions")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        ForEach(vm.sessions.prefix(5), id: \.id) { s in
                            HStack {
                                Text(s.date?.formatted(date: .abbreviated, time: .omitted) ?? "")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Spacer()
                                Text("\(s.pagesRead) pages")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Button {
                    showDeleteConfirm = true
                } label: {
                    Text("Delete book")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .background(AppTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                            vm.toggleFavorite()
                        }
                    } label: {
                        Image(systemName: vm.book.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundStyle(vm.book.isFavorite ? AppTheme.accentOrange : AppTheme.textSecondary)
                    }
                    if vm.book.sourceTypeEnum == .manual {
                        Button {
                            showEditSheet = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .accessibilityLabel("Edit book details")
                    }
                }
            }
        }
        .sheet(isPresented: $showUpdateProgress) {
            UpdateProgressSheet(book: vm.book, onDismiss: {
                showUpdateProgress = false
                vm.refreshUI()
            })
        }
        .sheet(isPresented: $showEditSheet) {
            EditBookView(book: vm.book, onDismiss: {
                showEditSheet = false
                vm.refreshUI()
            })
        }
        .alert("Delete book?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                PersistenceController.shared.container.viewContext.delete(vm.book)
                try? PersistenceController.shared.container.viewContext.save()
                onDelete?()
                dismiss()
            }
        } message: {
            Text("This cannot be undone.")
        }
        .suppressesFloatingTabBar()
        .toolbar(.hidden, for: .tabBar)
    }
}

struct RatingSection: View {
    let rating: Int?
    let onSelect: (Int?) -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text("Rating")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            ForEach(1...5, id: \.self) { i in
                Button {
                    HapticsService.shared.selection()
                    onSelect(rating == i ? nil : i)
                } label: {
                    Image(systemName: (rating ?? 0) >= i ? "star.fill" : "star")
                        .font(.system(size: 24))
                        .foregroundStyle((rating ?? 0) >= i ? AppTheme.accentOrange : AppTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
