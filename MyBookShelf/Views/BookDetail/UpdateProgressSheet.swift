//
//  UpdateProgressSheet.swift
//  MyBookShelf
//

import SwiftUI
import CoreData

struct UpdateProgressSheet: View {
    let book: Book
    let onDismiss: () -> Void
    @State private var currentPage: Int
    @State private var durationMinutes: String = ""
    @State private var showFinishedCelebration = false

    init(book: Book, onDismiss: @escaping () -> Void) {
        self.book = book
        self.onDismiss = onDismiss
        _currentPage = State(initialValue: Int(book.currentPage))
    }

    private var progressPercent: Double {
        let total = max(1, Int(book.totalPages))
        return Double(currentPage) / Double(total) * 100
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("\(Int(progressPercent))%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(AppTheme.accentOrange)

                ProgressBarView(progress: progressPercent)
                    .frame(height: 12)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Current page")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    TextField("Page", value: $currentPage, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Pages: \(currentPage) / \(book.totalPages)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Slider(value: Binding(
                        get: { Double(currentPage) },
                        set: { currentPage = Int($0) }
                    ), in: 0...Double(max(1, Int(book.totalPages))), step: 1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Reading time (minutes)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    TextField("Optional", text: $durationMinutes)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(24)
            .background(AppTheme.background)
            .navigationTitle("Update progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: currentPage) { new in
                currentPage = min(max(0, new), Int(book.totalPages))
            }
            .sheet(isPresented: $showFinishedCelebration) {
                FinishedCelebrationView(onDismiss: {
                    showFinishedCelebration = false
                    onDismiss()
                })
            }
        }
    }

    private func save() {
        let dur = Int(durationMinutes)
        let ctx = PersistenceController.shared.container.viewContext
        let vm = BookDetailViewModel(book: book, context: ctx)
        vm.updateProgress(to: currentPage, durationMinutes: dur)
        HapticsService.shared.success()
        if currentPage >= Int(book.totalPages) {
            showFinishedCelebration = true
        } else {
            onDismiss()
        }
    }
}

struct FinishedCelebrationView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.accentOrange)
            Text("Book finished!")
                .font(.title.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text("Congratulations on completing another book.")
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button("Done") {
                onDismiss()
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.accentOrange)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 40)
        }
        .padding(40)
        .background(AppTheme.background)
    }
}
