// StreakWidgets/HabitCommitmentWidget.swift

import WidgetKit
import SwiftUI

// MARK: - Entry

struct HabitEntry: TimelineEntry {
    let date: Date
    let total: Int
    let followed: Int
    let failed: Int
    let pending: Int
    let items: [WidgetData.HabitCommitmentItem]
}

// MARK: - Provider

struct HabitProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(
            date: Date(),
            total: 4,
            followed: 3,
            failed: 1,
            pending: 0,
            items: [
                WidgetData.HabitCommitmentItem(id: "1", title: "No Reels / Short Content", categoryColorHex: "#30D158", status: "FOLLOWED"),
                WidgetData.HabitCommitmentItem(id: "2", title: "No Wasted Money", categoryColorHex: "#0A84FF", status: "FOLLOWED"),
                WidgetData.HabitCommitmentItem(id: "3", title: "Read 15+ Minutes", categoryColorHex: "#FF9F0A", status: "FAILED"),
                WidgetData.HabitCommitmentItem(id: "4", title: "Morning Exercise", categoryColorHex: "#BF5AF2", status: "FOLLOWED")
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        let e = entry()
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        completion(Timeline(entries: [e], policy: .after(midnight)))
    }

    private func entry() -> HabitEntry {
        let data = WidgetDataStore.load()
        let summary = data?.habitSummary
        let items = data?.habitCommitments ?? []
        return HabitEntry(
            date: Date(),
            total: summary?.total ?? 0,
            followed: summary?.followed ?? 0,
            failed: summary?.failed ?? 0,
            pending: summary?.pending ?? 0,
            items: items
        )
    }
}

// MARK: - Views

struct HabitWidgetSmall: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let entry: HabitEntry

    var body: some View {
        let theme = WidgetColorTheme.theme(for: renderingMode)
        let total = max(1, entry.total)
        let followedFrac = Double(entry.followed) / Double(total)
        let failedFrac = Double(entry.failed) / Double(total)

        VStack(alignment: .leading, spacing: 6) {
            Text("HABIT COMMITMENTS")
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundStyle(theme.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(entry.followed)")
                    .font(.system(size: 28, weight: .heavy, design: .monospaced))
                    .foregroundStyle(WColor.green)
                Text("/\(entry.total)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Text("✅")
                    .font(.system(size: 14))
            }

            // Dual Progress Bar
            GeometryReader { geo in
                let w = geo.size.width
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(WColor.green)
                        .frame(width: max(0, w * followedFrac - 1))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(WColor.red)
                        .frame(width: max(0, w * failedFrac - 1))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.blank)
                }
            }
            .frame(height: 6)

            Spacer()

            HStack {
                Text("\(entry.followed) Done")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(WColor.green)
                Spacer()
                Text("\(entry.failed) Failed")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(entry.failed > 0 ? WColor.red : theme.textSecondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.background)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(theme.border, lineWidth: 2)
                .padding(1)
        )
    }
}

struct HabitWidgetMedium: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let entry: HabitEntry

    var body: some View {
        let theme = WidgetColorTheme.theme(for: renderingMode)
        let total = max(1, entry.total)
        let followedFrac = Double(entry.followed) / Double(total)
        let failedFrac = Double(entry.failed) / Double(total)

        HStack(spacing: 14) {
            // Left Stat Column
            VStack(alignment: .leading, spacing: 6) {
                Text("HABIT COMMITMENTS")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(theme.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(entry.followed)")
                        .font(.system(size: 32, weight: .heavy, design: .monospaced))
                        .foregroundStyle(WColor.green)
                    Text("/\(entry.total)")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(theme.textSecondary)
                }

                // Dual Progress Bar
                GeometryReader { geo in
                    let w = geo.size.width
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(WColor.green)
                            .frame(width: max(0, w * followedFrac - 1))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(WColor.red)
                            .frame(width: max(0, w * failedFrac - 1))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.blank)
                    }
                }
                .frame(height: 6)

                Spacer()

                HStack(spacing: 8) {
                    Text("✅ \(entry.followed)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(WColor.green)
                    Text("❌ \(entry.failed)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(entry.failed > 0 ? WColor.red : theme.textSecondary)
                }
            }
            .frame(width: 120)

            Divider().background(theme.border)

            // Right Items List Column
            VStack(alignment: .leading, spacing: 6) {
                if entry.items.isEmpty {
                    Text("No active habit commitments.")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.textSecondary)
                } else {
                    ForEach(entry.items.prefix(3)) { item in
                        HStack(spacing: 6) {
                            Text(item.status == "FOLLOWED" ? "✅" : (item.status == "FAILED" ? "❌" : "⚪"))
                                .font(.system(size: 12))

                            Text(item.title)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(theme.textPrimary)
                                .lineLimit(1)

                            Spacer()
                        }
                    }
                }
            }
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

struct HabitWidgetLarge: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let entry: HabitEntry

    var body: some View {
        let theme = WidgetColorTheme.theme(for: renderingMode)
        let total = max(1, entry.total)
        let followedFrac = Double(entry.followed) / Double(total)
        let failedFrac = Double(entry.failed) / Double(total)

        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MONTHLY HABIT COMMITMENTS")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(theme.textSecondary)
                    Text("\(entry.followed)/\(entry.total) FOLLOWED TODAY")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundStyle(theme.textPrimary)
                }
                Spacer()
            }

            // Dual Progress Bar
            GeometryReader { geo in
                let w = geo.size.width
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(WColor.green)
                        .frame(width: max(0, w * followedFrac - 1))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(WColor.red)
                        .frame(width: max(0, w * failedFrac - 1))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.blank)
                }
            }
            .frame(height: 8)

            Divider().background(theme.border)

            // Items List
            if entry.items.isEmpty {
                Spacer()
                Text("No habit commitments set for this month.")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.textSecondary)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.items.prefix(7)) { item in
                        HStack(spacing: 8) {
                            Text(item.status == "FOLLOWED" ? "✅" : (item.status == "FAILED" ? "❌" : "⚪"))
                                .font(.system(size: 14))

                            Text(item.title)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(theme.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Text(item.status)
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundStyle(item.status == "FOLLOWED" ? WColor.green : (item.status == "FAILED" ? WColor.red : theme.textSecondary))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.background)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(theme.border, lineWidth: 2)
                .padding(1)
        )
    }
}

// Lock screen accessory
struct HabitLockRectangular: View {
    let entry: HabitEntry

    var body: some View {
        HStack(spacing: 6) {
            Text("✅ \(entry.followed)/\(entry.total)")
                .font(.system(.caption, design: .rounded).weight(.bold))
            Text("· Habits")
                .font(.system(.caption).weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Widget Configuration

struct HabitCommitmentWidget: Widget {
    let kind = "HabitCommitmentWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitProvider()) { entry in
            HabitWidgetEntryView(entry: entry)
                .environment(\.colorScheme, .light)
                .containerBackground(WColor.background, for: .widget)
        }
        .configurationDisplayName("Habit Commitments")
        .description("Track your fixed monthly habit commitments with live followed and failed counts.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular
        ])
    }
}

struct HabitWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: HabitEntry

    var body: some View {
        switch family {
        case .systemSmall:          HabitWidgetSmall(entry: entry)
        case .systemMedium:         HabitWidgetMedium(entry: entry)
        case .systemLarge:          HabitWidgetLarge(entry: entry)
        case .accessoryRectangular: HabitLockRectangular(entry: entry)
        default:                    HabitWidgetSmall(entry: entry)
        }
    }
}
