// StreakWidgets/MasterStreakWidget.swift
// Shows overall streak + today's status. Small, medium, lock screen.

import WidgetKit
import SwiftUI

// MARK: - Entry

struct MasterEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let statusToday: String
    let tasksTotal: Int
    let tasksCompleted: Int
    let recentDays: [String: String]
}

// MARK: - Provider

struct MasterProvider: TimelineProvider {
    func placeholder(in context: Context) -> MasterEntry {
        MasterEntry(date: Date(), streak: 12, statusToday: "green",
                    tasksTotal: 5, tasksCompleted: 3, recentDays: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (MasterEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MasterEntry>) -> Void) {
        let e = entry()
        // Refresh at midnight
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        completion(Timeline(entries: [e], policy: .after(midnight)))
    }

    private func entry() -> MasterEntry {
        let data = WidgetDataStore.load()
        return MasterEntry(
            date: Date(),
            streak: data?.masterStreak ?? 0,
            statusToday: data?.masterStatusToday ?? "future",
            tasksTotal: data?.tasksToday.total ?? 0,
            tasksCompleted: data?.tasksToday.completed ?? 0,
            recentDays: data?.masterRecentDays ?? [:]
        )
    }
}

// MARK: - Views

struct MasterWidgetSmall: View {
    let entry: MasterEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STREAK")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(WColor.textSecondary)

            WStreakLabel(count: entry.streak, size: .title)

            Spacer()

            HStack(spacing: 4) {
                StatusDot(status: entry.statusToday, size: 8)
                Text("Today")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(WColor.textSecondary)
                Spacer()
                Text("\(entry.tasksCompleted)/\(entry.tasksTotal)")
                    .font(.system(size: 11, weight: .medium).monospacedDigit())
                    .foregroundStyle(WColor.textSecondary)
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
}

struct MasterWidgetMedium: View {
    let entry: MasterEntry

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("OVERALL")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WColor.textSecondary)

                WStreakLabel(count: entry.streak, size: .title)

                Spacer()

                HStack(spacing: 4) {
                    StatusDot(status: entry.statusToday, size: 8)
                    Text("\(entry.tasksCompleted)/\(entry.tasksTotal) tasks")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(WColor.textSecondary)
                }
            }

            Spacer()

            MiniHeatmap(recentDays: entry.recentDays)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WColor.background)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(WColor.border, lineWidth: 2)
                .padding(1)
        )
    }
}

// Lock screen — accessory rectangular
struct MasterLockRectangular: View {
    let entry: MasterEntry

    var body: some View {
        HStack(spacing: 6) {
            Text("🔥\(entry.streak)d")
                .font(.system(.caption, design: .rounded).weight(.bold))
            Text("·")
                .foregroundStyle(.secondary)
            Text("\(entry.tasksCompleted)/\(entry.tasksTotal) tasks")
                .font(.system(.caption).weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

// Lock screen — accessory circular
struct MasterLockCircular: View {
    let entry: MasterEntry

    var body: some View {
        VStack(spacing: 0) {
            Text("\(entry.streak)")
                .font(.system(.title3, design: .rounded).weight(.heavy))
            Text("days")
                .font(.system(size: 8).weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Widget

struct MasterStreakWidget: Widget {
    let kind = "MasterStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MasterProvider()) { entry in
            MasterWidgetEntryView(entry: entry)
                .environment(\.colorScheme, .light)
                .containerBackground(WColor.background, for: .widget)
        }
        .configurationDisplayName("Overall Streak")
        .description("Your master consistency streak and today's task progress.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryCircular
        ])
    }
}

struct MasterWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MasterEntry

    var body: some View {
        switch family {
        case .systemSmall:       MasterWidgetSmall(entry: entry)
        case .systemMedium:      MasterWidgetMedium(entry: entry)
        case .accessoryRectangular: MasterLockRectangular(entry: entry)
        case .accessoryCircular: MasterLockCircular(entry: entry)
        default:                 MasterWidgetSmall(entry: entry)
        }
    }
}
