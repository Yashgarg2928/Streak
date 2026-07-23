// StreakWidgets/CategoryWidget.swift
// Per-category streak + heatmap. User picks category from a dropdown list.

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Category App Entity (for dynamic options)

struct CategoryAppEntity: AppEntity {
    let id: String          // UUID string
    let name: String
    let colorHex: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static var defaultQuery = CategoryEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct CategoryEntityQuery: EntityQuery {
    static var cache: [CategoryAppEntity] = []

    func entities(for identifiers: [String]) async throws -> [CategoryAppEntity] {
        let all = allEntities()
        if !all.isEmpty {
            Self.cache = all
        }
        let resolvedAll = all.isEmpty ? Self.cache : all
        
        // Return all if identifiers is empty, else filter
        guard !identifiers.isEmpty else { return resolvedAll }
        let lowercasedIds = identifiers.map { $0.lowercased() }
        return resolvedAll.filter { lowercasedIds.contains($0.id.lowercased()) }
    }

    func suggestedEntities() async throws -> [CategoryAppEntity] {
        let all = allEntities()
        if !all.isEmpty {
            Self.cache = all
        }
        return all
    }

    func defaultResult() async -> CategoryAppEntity? {
        let all = allEntities()
        if !all.isEmpty {
            Self.cache = all
        }
        return all.first
    }

    private func allEntities() -> [CategoryAppEntity] {
        guard let data = WidgetDataStore.load() else { return [] }
        return data.categories.map {
            CategoryAppEntity(id: $0.id, name: $0.name, colorHex: $0.colorHex)
        }
    }
}

// MARK: - Configuration Intent

struct CategoryIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Category"
    static var description = IntentDescription("Choose which category to display.")

    @Parameter(title: "Category")
    var category: CategoryAppEntity?
}

// MARK: - Entry

struct CategoryEntry: TimelineEntry {
    let date: Date
    let name: String
    let colorHex: String
    let streak: Int
    let statusToday: String
    let recentDays: [String: String]
    let availableNames: [String]
}

// MARK: - Provider

struct CategoryProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CategoryEntry {
        CategoryEntry(date: Date(), name: "Gym", colorHex: "#E74C3C",
                      streak: 12, statusToday: "green", recentDays: [:],
                      availableNames: [])
    }

    func snapshot(for config: CategoryIntent, in context: Context) async -> CategoryEntry {
        entry(for: config)
    }

    func timeline(for config: CategoryIntent, in context: Context) async -> Timeline<CategoryEntry> {
        let e = entry(for: config)
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        return Timeline(entries: [e], policy: .after(midnight))
    }

    private func entry(for config: CategoryIntent) -> CategoryEntry {
        guard let data = WidgetDataStore.load(), !data.categories.isEmpty else {
            return CategoryEntry(date: Date(), name: "No categories",
                                 colorHex: "#9A9A9A", streak: 0,
                                 statusToday: "future", recentDays: [:],
                                 availableNames: [])
        }

        let names = data.categories.map { $0.name }

        // Match by selected entity id (UUID string) case-insensitively, fall back to first
        let selectedId = (config.category?.id ?? "").lowercased()
        let cat = data.categories.first(where: { $0.id.lowercased() == selectedId })
                  ?? data.categories[0]

        return CategoryEntry(
            date: Date(),
            name: cat.name,
            colorHex: cat.colorHex,
            streak: cat.streak,
            statusToday: cat.statusToday,
            recentDays: cat.recentDays,
            availableNames: names
        )
    }
}

// MARK: - Views (unchanged from before)

struct CategoryWidgetSmall: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let entry: CategoryEntry
    var body: some View {
        let theme = WidgetColorTheme.theme(for: renderingMode)
        let catColor = Color(hex: entry.colorHex)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.name.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                Spacer()
                StatusDot(status: entry.statusToday, size: 8)
            }
            WStreakLabel(count: entry.streak, size: .title2)
            Spacer()
            MiniHeatmap(recentDays: entry.recentDays,
                        categoryColor: catColor)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.background)
        .overlay(RoundedRectangle(cornerRadius: 6)
            .stroke(renderingMode == .fullColor ? catColor : theme.border, lineWidth: 2).padding(1))
    }
}

struct CategoryWidgetMedium: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let entry: CategoryEntry
    var body: some View {
        let theme = WidgetColorTheme.theme(for: renderingMode)
        let catColor = Color(hex: entry.colorHex)
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.name.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                WStreakLabel(count: entry.streak, size: .title)
                Spacer()
                HStack(spacing: 4) {
                    StatusDot(status: entry.statusToday, size: 8)
                    Text("Today").font(.system(size: 11)).foregroundStyle(theme.textSecondary)
                }
            }
            Spacer()
            MiniHeatmap(recentDays: entry.recentDays,
                        categoryColor: catColor)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .overlay(RoundedRectangle(cornerRadius: 6)
            .stroke(renderingMode == .fullColor ? catColor : theme.border, lineWidth: 2).padding(1))
    }
}

struct CategoryWidgetLarge: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let entry: CategoryEntry
    var body: some View {
        let theme = WidgetColorTheme.theme(for: renderingMode)
        let catColor = Color(hex: entry.colorHex)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.name.uppercased())
                    .font(.system(.headline).weight(.semibold))
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                StatusDot(status: entry.statusToday, size: 10)
            }
            WStreakLabel(count: entry.streak, size: .largeTitle)
            LargeHeatmap(recentDays: entry.recentDays,
                         categoryColor: catColor)
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.background)
        .overlay(RoundedRectangle(cornerRadius: 6)
            .stroke(renderingMode == .fullColor ? catColor : theme.border, lineWidth: 2).padding(1))
    }
}

struct CategoryLockRectangular: View {
    let entry: CategoryEntry
    var body: some View {
        HStack(spacing: 6) {
            Text(entry.name).font(.system(.caption).weight(.semibold)).lineLimit(1)
            Text("🔥\(entry.streak)d").font(.system(.caption, design: .rounded).weight(.bold))
        }
    }
}

struct CategoryLockCircular: View {
    let entry: CategoryEntry
    var body: some View {
        VStack(spacing: 0) {
            Text("\(entry.streak)").font(.system(.title3, design: .rounded).weight(.heavy))
            Text(String(entry.name.prefix(3)).uppercased())
                .font(.system(size: 7).weight(.semibold)).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Large heatmap

struct LargeHeatmap: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let recentDays: [String: String]
    var categoryColor: Color = WColor.green
    private let cols = 12, rows = 7
    private let cell: CGFloat = 10, gap: CGFloat = 3

    static let keyFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    var body: some View {
        HStack(spacing: gap) {
            ForEach(0..<cols, id: \.self) { col in
                VStack(spacing: gap) {
                    ForEach(0..<rows, id: \.self) { row in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(cellColor(col: col, row: row))
                            .frame(width: cell, height: cell)
                    }
                }
            }
        }
    }

    private func cellColor(col: Int, row: Int) -> Color {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        let thisMonday = cal.date(byAdding: .day, value: -daysFromMonday, to: today)!
        let weekStart = cal.date(byAdding: .day, value: -(cols - 1 - col) * 7, to: thisMonday)!
        let date = cal.date(byAdding: .day, value: row, to: weekStart)!
        if date > today { return Color.clear }
        let key = Self.keyFmt.string(from: cal.startOfDay(for: date))
        switch recentDays[key] {
        case "green":
            return renderingMode == .fullColor ? WColor.green : .white
        case "red":
            return renderingMode == .fullColor ? WColor.red : .white.opacity(0.3)
        default:
            return renderingMode == .fullColor ? WColor.blank.opacity(0.4) : .white.opacity(0.1)
        }
    }
}

// MARK: - Widget

struct CategoryWidget: Widget {
    let kind = "CategoryWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: CategoryIntent.self,
                               provider: CategoryProvider()) { entry in
            CategoryWidgetEntryView(entry: entry)
                .environment(\.colorScheme, .light)
                .containerBackground(WColor.background, for: .widget)
        }
        .configurationDisplayName("Category Streak")
        .description("Pick a category to show its streak and consistency.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryRectangular, .accessoryCircular
        ])
    }
}

struct CategoryWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: CategoryEntry
    var body: some View {
        switch family {
        case .systemSmall:          CategoryWidgetSmall(entry: entry)
        case .systemMedium:         CategoryWidgetMedium(entry: entry)
        case .systemLarge:          CategoryWidgetLarge(entry: entry)
        case .accessoryRectangular: CategoryLockRectangular(entry: entry)
        case .accessoryCircular:    CategoryLockCircular(entry: entry)
        default:                    CategoryWidgetSmall(entry: entry)
        }
    }
}
