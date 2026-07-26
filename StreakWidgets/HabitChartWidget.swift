// StreakWidgets/HabitChartWidget.swift

import WidgetKit
import SwiftUI

// MARK: - Entry

struct HabitChartEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let statusToday: String
    let recentDays: [String: String]
    let categories: [WidgetData.CategoryWidgetData]
}

// MARK: - Provider

struct HabitChartProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitChartEntry {
        HabitChartEntry(
            date: Date(),
            streak: 14,
            statusToday: "green",
            recentDays: [:],
            categories: [
                WidgetData.CategoryWidgetData(id: "1", name: "Gym", colorHex: "#FF5733", streak: 10, statusToday: "green", recentDays: [:]),
                WidgetData.CategoryWidgetData(id: "2", name: "Reading", colorHex: "#33FF57", streak: 7, statusToday: "green", recentDays: [:])
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitChartEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitChartEntry>) -> Void) {
        let e = entry()
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        completion(Timeline(entries: [e], policy: .after(midnight)))
    }

    private func entry() -> HabitChartEntry {
        let data = WidgetDataStore.load()
        return HabitChartEntry(
            date: Date(),
            streak: data?.masterStreak ?? 0,
            statusToday: data?.masterStatusToday ?? "future",
            recentDays: data?.masterRecentDays ?? [:],
            categories: data?.categories ?? []
        )
    }
}

// MARK: - Custom Full Heatmap Grid Chart Component

struct FullHabitHeatmapChart: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let recentDays: [String: String]
    var columnsCount: Int = 16
    var cellSize: CGFloat = 7
    var cellSpacing: CGFloat = 2

    static let keyFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    var body: some View {
        HStack(spacing: cellSpacing) {
            ForEach(0..<columnsCount, id: \.self) { col in
                VStack(spacing: cellSpacing) {
                    ForEach(0..<7, id: \.self) { row in
                        let date = dateFor(col: col, row: row)
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(cellColor(for: date))
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
    }

    private func cellColor(for date: Date) -> Color {
        let today = Calendar.current.startOfDay(for: Date())
        let day   = Calendar.current.startOfDay(for: date)
        if day > today { return Color.clear }
        let key = Self.keyFmt.string(from: day)

        switch recentDays[key] {
        case "green":
            return renderingMode == .fullColor ? WColor.green : .white
        case "red":
            return renderingMode == .fullColor ? WColor.red : .white.opacity(0.35)
        default:
            return renderingMode == .fullColor ? WColor.blank.opacity(0.35) : .white.opacity(0.12)
        }
    }

    private func dateFor(col: Int, row: Int) -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        let thisMonday = cal.date(byAdding: .day, value: -daysFromMonday, to: today)!
        let weekOffset = columnsCount - 1 - col
        let weekStart = cal.date(byAdding: .day, value: -weekOffset * 7, to: thisMonday)!
        return cal.date(byAdding: .day, value: row, to: weekStart)!
    }
}

// MARK: - Medium Habit Chart View

struct HabitChartWidgetMedium: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let entry: HabitChartEntry

    var body: some View {
        let theme = WidgetColorTheme.theme(for: renderingMode)

        VStack(alignment: .leading, spacing: 6) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("HABIT TRACKER CHART")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(theme.textSecondary)
                    Text("Consistency Grid")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                }

                Spacer()

                WStreakLabel(count: entry.streak, size: .subheadline)
            }

            Divider().background(theme.border.opacity(0.4))

            Spacer(minLength: 0)

            // Heatmap Grid Chart
            HStack {
                Spacer()
                FullHabitHeatmapChart(recentDays: entry.recentDays, columnsCount: 18, cellSize: 7.5, cellSpacing: 2)
                Spacer()
            }

            Spacer(minLength: 0)

            // Legend
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Circle().fill(WColor.green).frame(width: 6, height: 6)
                    Text("Followed").font(.system(size: 8, weight: .bold)).foregroundStyle(theme.textSecondary)
                }
                HStack(spacing: 4) {
                    Circle().fill(WColor.red).frame(width: 6, height: 6)
                    Text("Missed").font(.system(size: 8, weight: .bold)).foregroundStyle(theme.textSecondary)
                }
                HStack(spacing: 4) {
                    Circle().fill(WColor.blank).frame(width: 6, height: 6)
                    Text("Blank").font(.system(size: 8, weight: .bold)).foregroundStyle(theme.textSecondary)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(theme.border, lineWidth: 2)
                .padding(1)
        )
    }
}

// MARK: - Large Habit Chart View

struct HabitChartWidgetLarge: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let entry: HabitChartEntry

    var body: some View {
        let theme = WidgetColorTheme.theme(for: renderingMode)

        VStack(alignment: .leading, spacing: 8) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HABIT CONSISTENCY CHART")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(theme.textSecondary)
                    Text("Overall & Category Heatmaps")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                }

                Spacer()

                WStreakLabel(count: entry.streak, size: .title3)
            }

            Divider().background(theme.border.opacity(0.4))

            // Main Master Chart Grid
            VStack(alignment: .leading, spacing: 4) {
                Text("OVERALL CONSISTENCY")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(theme.textSecondary)

                HStack {
                    Spacer()
                    FullHabitHeatmapChart(recentDays: entry.recentDays, columnsCount: 22, cellSize: 8, cellSpacing: 2)
                    Spacer()
                }
            }

            Divider().background(theme.border.opacity(0.3))

            // Category Mini Charts
            Text("CATEGORY BREAKDOWN")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(theme.textSecondary)

            VStack(spacing: 6) {
                ForEach(entry.categories.prefix(3)) { cat in
                    HStack {
                        Circle()
                            .fill(Color(hex: cat.colorHex))
                            .frame(width: 8, height: 8)

                        Text(cat.name)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(theme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text("🔥\(cat.streak)d")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(theme.textSecondary)

                        MiniHeatmap(recentDays: cat.recentDays, categoryColor: Color(hex: cat.colorHex))
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(theme.border, lineWidth: 2)
                .padding(1)
        )
    }
}

// MARK: - Small Habit Chart View

struct HabitChartWidgetSmall: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let entry: HabitChartEntry

    var body: some View {
        let theme = WidgetColorTheme.theme(for: renderingMode)

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("HABITS")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                WStreakLabel(count: entry.streak, size: .caption)
            }

            Spacer(minLength: 0)

            FullHabitHeatmapChart(recentDays: entry.recentDays, columnsCount: 11, cellSize: 7.5, cellSpacing: 2)

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                StatusDot(status: entry.statusToday, size: 6)
                Text("Today")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(theme.border, lineWidth: 2)
                .padding(1)
        )
    }
}

// MARK: - Main Widget Configuration

struct HabitChartWidget: Widget {
    let kind = "HabitChartWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitChartProvider()) { entry in
            HabitChartEntryView(entry: entry)
                .environment(\.colorScheme, .light)
                .containerBackground(WColor.background, for: .widget)
        }
        .configurationDisplayName("Habit Tracker Chart")
        .description("Visual consistency heatmap chart showing your habit streaks and history.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge
        ])
    }
}

struct HabitChartEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: HabitChartEntry

    var body: some View {
        switch family {
        case .systemSmall:   HabitChartWidgetSmall(entry: entry)
        case .systemMedium:  HabitChartWidgetMedium(entry: entry)
        case .systemLarge:   HabitChartWidgetLarge(entry: entry)
        default:             HabitChartWidgetMedium(entry: entry)
        }
    }
}
