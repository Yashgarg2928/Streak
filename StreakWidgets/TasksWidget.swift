// StreakWidgets/TasksWidget.swift
// Shows today's task list with checkmark status.
// Tapping opens the Tasks tab in the main app.

import WidgetKit
import SwiftUI

// MARK: - Entry

struct TasksEntry: TimelineEntry {
    let date: Date
    let tasksTotal: Int
    let tasksCompleted: Int
    let masterStatus: String
    let masterStreak: Int
    let taskItems: [WidgetData.TaskItem]
    let activeDayDeadline: Date
}

// MARK: - Provider

struct TasksProvider: TimelineProvider {
    func placeholder(in context: Context) -> TasksEntry {
        TasksEntry(
            date: Date(),
            tasksTotal: 5,
            tasksCompleted: 2,
            masterStatus: "red",
            masterStreak: 12,
            taskItems: [
                WidgetData.TaskItem(title: "Morning workout", isCompleted: true, categoryColorHex: "#E74C3C"),
                WidgetData.TaskItem(title: "Read 20 pages", isCompleted: false, categoryColorHex: "#3498DB"),
                WidgetData.TaskItem(title: "Call parents", isCompleted: false, categoryColorHex: nil),
            ],
            activeDayDeadline: Date().addingTimeInterval(3600 * 5)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TasksEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TasksEntry>) -> Void) {
        let e = entry()
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        completion(Timeline(entries: [e], policy: .after(midnight)))
    }

    private func entry() -> TasksEntry {
        let data = WidgetDataStore.load()
        let settings = UserDefaultsSettingsRepository()
        let activeDate = ActiveDayResolver.resolveActiveDate(for: Date(), settings: settings)
        let deadline = ActiveDayResolver.activeDayDeadline(for: activeDate, settings: settings)
        
        return TasksEntry(
            date: Date(),
            tasksTotal: data?.tasksToday.total ?? 0,
            tasksCompleted: data?.tasksToday.completed ?? 0,
            masterStatus: data?.masterStatusToday ?? "future",
            masterStreak: data?.masterStreak ?? 0,
            taskItems: data?.taskItems ?? [],
            activeDayDeadline: deadline
        )
    }
}

// MARK: - Small widget (count + progress bar only)

struct TasksWidgetSmall: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let entry: TasksEntry

    private var fraction: Double {
        guard entry.tasksTotal > 0 else { return 0 }
        return Double(entry.tasksCompleted) / Double(entry.tasksTotal)
    }

    var body: some View {
        let theme = WidgetColorTheme.theme(for: renderingMode)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("TASKS")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Text(entry.activeDayDeadline, style: .timer)
                    .font(.system(size: 10, design: .monospaced).weight(.bold))
                    .foregroundStyle(theme.textSecondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(entry.tasksCompleted)")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(theme.textPrimary)
                Text("/ \(entry.tasksTotal)")
                    .font(.system(.title3).weight(.medium))
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(theme.blank)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(renderingMode == .fullColor ? (fraction == 1 ? WColor.green : WColor.border) : .white)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 8)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(theme.border, lineWidth: 1.5))

            HStack(spacing: 4) {
                StatusDot(status: entry.masterStatus, size: 7)
                Text("🔥 \(entry.masterStreak)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
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

// MARK: - Medium widget (count + first 3 tasks)

struct TasksWidgetMedium: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let entry: TasksEntry

    var body: some View {
        let theme = WidgetColorTheme.theme(for: renderingMode)
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("TODAY")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                Text("·")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.textDisabled)
                Text(entry.activeDayDeadline, style: .timer)
                    .font(.system(size: 10, design: .monospaced).weight(.bold))
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Text("\(entry.tasksCompleted) / \(entry.tasksTotal)")
                    .font(.system(size: 13, design: .rounded).weight(.heavy))
                    .foregroundStyle(theme.textPrimary)
            }
            .padding(.bottom, 8)

            // Task list — up to 3 items
            VStack(alignment: .leading, spacing: 5) {
                ForEach(Array(entry.taskItems.prefix(3).enumerated()), id: \.offset) { _, item in
                    taskRow(item: item, theme: theme, mode: renderingMode)
                }
                if entry.taskItems.count > 3 {
                    Text("+ \(entry.taskItems.count - 3) more")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.textDisabled)
                        .padding(.leading, 22)
                }
            }

            Spacer()
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

// MARK: - Large widget (count + full list)

struct TasksWidgetLarge: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let entry: TasksEntry

    var body: some View {
        let theme = WidgetColorTheme.theme(for: renderingMode)
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("TODAY'S TASKS")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(theme.textSecondary)
                        Text("·")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(theme.textDisabled)
                        Text(entry.activeDayDeadline, style: .timer)
                            .font(.system(size: 10, design: .monospaced).weight(.bold))
                            .foregroundStyle(theme.textSecondary)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(entry.tasksCompleted)")
                            .font(.system(.title, design: .rounded).weight(.heavy))
                            .foregroundStyle(theme.textPrimary)
                        Text("/ \(entry.tasksTotal)")
                            .font(.system(.title3).weight(.medium))
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                Spacer()
                WStreakLabel(count: entry.masterStreak, size: .subheadline)
            }
            .padding(.bottom, 10)

            Divider().background(theme.blank)
                .padding(.bottom, 8)

            // Full task list — up to 8
            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array(entry.taskItems.prefix(8).enumerated()), id: \.offset) { _, item in
                    taskRow(item: item, theme: theme, mode: renderingMode)
                }
                if entry.taskItems.count > 8 {
                    Text("+ \(entry.taskItems.count - 8) more")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.textDisabled)
                        .padding(.leading, 22)
                }
            }

            Spacer()
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

// MARK: - Shared task row

private func taskRow(item: WidgetData.TaskItem, theme: WidgetColorTheme, mode: WidgetRenderingMode) -> some View {
    HStack(spacing: 6) {
        Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(item.isCompleted ? (mode == .fullColor ? WColor.green : .white.opacity(0.6)) : theme.textSecondary)
            .frame(width: 16)

        if let hex = item.categoryColorHex {
            Circle()
                .fill(mode == .fullColor ? Color(hex: hex) : .white)
                .frame(width: 6, height: 6)
        } else {
            Circle()
                .fill(theme.blank)
                .frame(width: 6, height: 6)
        }

        Text(item.title)
            .font(.system(size: 12, weight: item.isCompleted ? .regular : .medium))
            .foregroundStyle(item.isCompleted ? theme.textDisabled : theme.textPrimary)
            .strikethrough(item.isCompleted, color: theme.textDisabled)
            .lineLimit(1)
    }
}

// MARK: - Lock screen

struct TasksLockRectangular: View {
    let entry: TasksEntry
    var body: some View {
        HStack(spacing: 6) {
            StatusDot(status: entry.masterStatus, size: 8)
            Text("Tasks \(entry.tasksCompleted)/\(entry.tasksTotal)")
                .font(.system(.caption).weight(.semibold))
            Text("· 🔥\(entry.masterStreak)")
                .font(.system(.caption))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Widget

struct TasksWidget: Widget {
    let kind = "TasksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TasksProvider()) { entry in
            TasksWidgetEntryView(entry: entry)
                .environment(\.colorScheme, .light)
                .containerBackground(WColor.background, for: .widget)
                // Deep link — tapping opens Tasks tab
                .widgetURL(URL(string: "streak://tasks"))
        }
        .configurationDisplayName("Today's Tasks")
        .description("See your task list for today.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular
        ])
    }
}

struct TasksWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: TasksEntry

    var body: some View {
        switch family {
        case .systemSmall:          TasksWidgetSmall(entry: entry)
        case .systemMedium:         TasksWidgetMedium(entry: entry)
        case .systemLarge:          TasksWidgetLarge(entry: entry)
        case .accessoryRectangular: TasksLockRectangular(entry: entry)
        default:                    TasksWidgetSmall(entry: entry)
        }
    }
}
