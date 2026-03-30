//
//  StatsView.swift
//  MyBookShelf
//

import SwiftUI
import CoreData

struct StatsView: View {
    @State private var profile: UserProfile?
    @State private var books: [Book] = []
    @State private var sessions: [ReadingSession] = []
    var tabBarHeight: CGFloat = 80

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let p = profile {
                        summaryCard(p)
                        last7DaysChart
                        heatmapSection
                        genresSection
                        activeBooksSection
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
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.background.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { fetch() }
        }
    }

    private func summaryCard(_ p: UserProfile) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                statBlock(title: "Books read", value: "\(p.totalBooksFinished)")
                statBlock(title: "Pages read", value: "\(p.totalPagesRead)")
            }
            HStack(spacing: 20) {
                statBlock(title: "Streak", value: "\(p.currentStreak)", icon: "flame.fill")
                let avg = avgPagesPerDay(p)
                statBlock(title: "Avg/day (30d)", value: "\(avg)")
            }
        }
        .padding(20)
        .background(AppTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statBlock(title: String, value: String, icon: String? = nil) -> some View {
        VStack(spacing: 4) {
            if let i = icon {
                Image(systemName: i)
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.accentOrange)
            }
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var last7DaysChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 days")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            let data = last7DaysData
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.offset) { i, d in
                    VStack(spacing: 4) {
                        Text("\(d.pages)")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.textSecondary)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.accentOrange)
                            .frame(height: max(4, CGFloat(d.pages) / CGFloat(max(1, data.map(\.pages).max() ?? 1)) * 80))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
            HStack(spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.offset) { i, d in
                    Text(d.label)
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(AppTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var last7DaysData: [(label: String, pages: Int)] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return (0..<7).reversed().map { offset in
            let d = cal.date(byAdding: .day, value: -offset, to: Date())!
            let start = cal.startOfDay(for: d)
            let end = cal.date(byAdding: .day, value: 1, to: start)!
            let pages = sessions.filter { ($0.date ?? .distantPast) >= start && ($0.date ?? .distantPast) < end }.reduce(0) { $0 + Int($1.pagesRead) }
            return (formatter.string(from: d), pages)
        }
    }

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This month")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            let cal = Calendar.current
            let comp = cal.dateComponents([.year, .month], from: Date())
            let first = cal.date(from: comp)!
            let days = cal.range(of: .day, in: .month, for: Date())!.count
            let weekday = cal.component(.weekday, from: first)
            let pad = weekday - 1
            let cols = 7
            let total = pad + days
            let rows = (total + cols - 1) / cols
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: cols), spacing: 4) {
                ForEach(0..<rows * cols, id: \.self) { i in
                    if i < pad {
                        Color.clear.aspectRatio(1, contentMode: .fit)
                    } else if i - pad < days {
                        let dayNum = i - pad + 1
                        let d = cal.date(byAdding: .day, value: dayNum - 1, to: first)!
                        let start = cal.startOfDay(for: d)
                        let end = cal.date(byAdding: .day, value: 1, to: start)!
                        let p = sessions.filter { ($0.date ?? .distantPast) >= start && ($0.date ?? .distantPast) < end }.reduce(0) { $0 + Int($1.pagesRead) }
                        let intensity = min(1, Double(p) / 50)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.accentOrange.opacity(0.15 + intensity * 0.85))
                            .aspectRatio(1, contentMode: .fit)
                    } else {
                        Color.clear.aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding(20)
        .background(AppTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top genres")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            let finished = books.filter { $0.statusEnum == .finished }
            let byGenre = Dictionary(grouping: finished, by: { $0.genre ?? "Other" })
            let sorted = byGenre.sorted { $0.value.count > $1.value.count }.prefix(5)
            let maxCount = sorted.map(\.value.count).max() ?? 1
            ForEach(Array(sorted), id: \.key) { genre, items in
                HStack {
                    Text(genre)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 100, alignment: .leading)
                    GeometryReader { g in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.accentOrange.opacity(0.6))
                            .frame(width: g.size.width * CGFloat(items.count) / CGFloat(maxCount))
                    }
                    .frame(height: 20)
                    Text("\(items.count)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .padding(20)
        .background(AppTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var activeBooksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Currently reading")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            let reading = books.filter { $0.statusEnum == .reading }
            ForEach(reading, id: \.id) { book in
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title ?? "")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                    ProgressBarView(progress: book.progressPercent)
                        .frame(height: 6)
                }
            }
            if reading.isEmpty {
                Text("No books in progress")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .padding(20)
        .background(AppTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func avgPagesPerDay(_ p: UserProfile) -> Int {
        let cal = Calendar.current
        let monthAgo = cal.date(byAdding: .day, value: -30, to: Date())!
        let relevant = sessions.filter { ($0.date ?? .distantPast) >= monthAgo }
        let total = relevant.reduce(0) { $0 + Int($1.pagesRead) }
        let days = Set(relevant.compactMap { $0.date.map { cal.startOfDay(for: $0) } }).count
        return days > 0 ? total / days : 0
    }

    private func fetch() {
        let ctx = PersistenceController.shared.container.viewContext
        let preq = UserProfile.fetchRequest()
        preq.fetchLimit = 1
        profile = try? ctx.fetch(preq).first
        let breq = Book.fetchRequest()
        books = (try? ctx.fetch(breq)) ?? []
        let sreq = ReadingSession.fetchRequest()
        sreq.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingSession.date, ascending: false)]
        sessions = (try? ctx.fetch(sreq)) ?? []
    }
}
