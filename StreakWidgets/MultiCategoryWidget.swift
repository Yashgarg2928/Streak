// StreakWidgets/MultiCategoryWidget.swift
// Shows a compact list of categories and their streak counts.
// Users can select which categories to display via the widget edit screen.

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Configuration Intent

struct MultiCategoryIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Categories"
    static var description = IntentDescription("Choose which categories to display in the list.")

    // Allows selecting multiple categories
    @Parameter(title: "Categories", default: [])
    var categories: [CategoryAppEntity]
}

// MARK: - Entry

struct MultiCategoryEntry: TimelineEntry {
    let date: Date
    let categories: [WidgetData.CategoryWidgetData]
}

// MARK: - Provider

struct MultiCategoryProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MultiCategoryEntry {
        MultiCategoryEntry(
            date: Date(),
            categories: [
                WidgetData.CategoryWidgetData(id: "1", name: "Gym", colorHex: "#2D7A2D", streak: 12, statusToday: "green", recentDays: [:]),
                WidgetData.CategoryWidgetData(id: "2", name: "Reading", colorHex: "#C0392B", streak: 5, statusToday: "red", recentDays: [:]),
                WidgetData.CategoryWidgetData(id: "3", name: "Code", colorHex: "#3498DB", streak: 47, statusToday: "green", recentDays: [:]),
                WidgetData.CategoryWidgetData(id: "4", name: "Finance", colorHex: "#8E44AD", streak: 9, statusToday: "future", recentDays: [:])
            ]
        )
    }

    func snapshot(for config: MultiCategoryIntent, in context: Context) async -> MultiCategoryEntry {
        entry(for: config)
    }

    func timeline(for config: MultiCategoryIntent, in context: Context) async -> Timeline<MultiCategoryEntry> {
        let e = entry(for: config)
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        return Timeline(entries: [e], policy: .after(midnight))
    }

    private func entry(for config: MultiCategoryIntent) -> MultiCategoryEntry {
        guard let data = WidgetDataStore.load(), !data.categories.isEmpty else {
            return MultiCategoryEntry(date: Date(), categories: [])
        }

        let displayCategories: [WidgetData.CategoryWidgetData]
        if config.categories.isEmpty {
            // Default: show all categories
            displayCategories = data.categories
        } else {
            // Filter categories based on user's selection in the intent (case-insensitive)
            let selectedIds = config.categories.map { $0.id.lowercased() }
            displayCategories = data.categories.filter { selectedIds.contains($0.id.lowercased()) }
        }

        return MultiCategoryEntry(date: Date(), categories: displayCategories)
    }
}

// MARK: - Views

struct MultiCategoryWidgetSmall: View {
    let entry: MultiCategoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STREAKS")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(WColor.textSecondary)

            if entry.categories.isEmpty {
                Spacer()
                Text("No categories")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(WColor.textDisabled)
                Spacer()
            } else {
                // In small widget, fit up to 4 categories maximum
                VStack(spacing: 5) {
                    ForEach(entry.categories.prefix(4)) { cat in
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color(hex: cat.colorHex))
                                .frame(width: 6, height: 6)
                            Text(cat.name)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(WColor.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Text("🔥\(cat.streak)")
                                .font(.system(size: 10, design: .rounded).weight(.heavy))
                                .foregroundStyle(WColor.textPrimary)
                        }
                    }
                }
                Spacer(minLength: 0)
                if entry.categories.count > 4 {
                    Text("+ \(entry.categories.count - 4) more")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(WColor.textDisabled)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WColor.background)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(WColor.border, lineWidth: 2)
                .padding(1)
        )
    }
}

struct MultiCategoryWidgetMedium: View {
    let entry: MultiCategoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STREAKS")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(WColor.textSecondary)

            if entry.categories.isEmpty {
                Spacer()
                Text("No categories")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WColor.textDisabled)
                Spacer()
            } else {
                // In medium widget, display in two columns (up to 8 categories)
                HStack(alignment: .top, spacing: 14) {
                    // Left Column (first 4)
                    VStack(spacing: 6) {
                        ForEach(entry.categories.prefix(4)) { cat in
                            categoryRow(cat)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if entry.categories.count > 4 {
                        // Right Column (next 4)
                        VStack(spacing: 6) {
                            ForEach(entry.categories.dropFirst(4).prefix(4)) { cat in
                                categoryRow(cat)
                            }
                            if entry.categories.count > 8 {
                                HStack {
                                    Spacer()
                                    Text("+ \(entry.categories.count - 8) more")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(WColor.textDisabled)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        // Spacer to keep layout structured if <= 4 items
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WColor.background)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(WColor.border, lineWidth: 2)
                .padding(1)
        )
    }

    private func categoryRow(_ cat: WidgetData.CategoryWidgetData) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: cat.colorHex))
                .frame(width: 6, height: 6)
            Text(cat.name)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(WColor.textPrimary)
                .lineLimit(1)
            Spacer()
            Text("🔥\(cat.streak)")
                .font(.system(size: 11, design: .rounded).weight(.heavy))
                .foregroundStyle(WColor.textPrimary)
        }
    }
}

// MARK: - Widget Configuration

struct MultiCategoryWidget: Widget {
    let kind = "MultiCategoryWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: MultiCategoryIntent.self,
            provider: MultiCategoryProvider()
        ) { entry in
            MultiCategoryWidgetEntryView(entry: entry)
                .environment(\.colorScheme, .light)
                .containerBackground(WColor.background, for: .widget)
                // Deep link opens home screen
                .widgetURL(URL(string: "streak://home"))
        }
        .configurationDisplayName("Category List Streaks")
        .description("View a compact list of category streaks. Edit the widget to select which ones to show.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MultiCategoryWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MultiCategoryEntry

    var body: some View {
        switch family {
        case .systemSmall:
            MultiCategoryWidgetSmall(entry: entry)
        case .systemMedium:
            MultiCategoryWidgetMedium(entry: entry)
        default:
            MultiCategoryWidgetSmall(entry: entry)
        }
    }
}
