// Shared between main app and widget extension.
// Written by the main app to App Group UserDefaults.
// Read by widgets via the same App Group.

import Foundation

struct WidgetData: Codable {
    var masterStreak: Int
    var masterStatusToday: String
    var masterRecentDays: [String: String]
    var tasksToday: TaskSummary
    var taskItems: [TaskItem]                  // actual task list for today
    var habitSummary: HabitCommitmentSummary
    var habitCommitments: [HabitCommitmentItem]
    var categories: [CategoryWidgetData]
    var goals: [GoalWidgetData]
    var lastUpdated: Date
    var activeDayDeadline: Date
    var monthlyExpense: MonthlyExpenseWidgetData? = nil

    struct TaskSummary: Codable {
        var total: Int
        var completed: Int
    }

    struct TaskItem: Codable {
        var id: String? = nil                  // task UUID string (nil in data written by older builds)
        var title: String
        var isCompleted: Bool
        var categoryColorHex: String?
    }

    struct HabitCommitmentSummary: Codable {
        var total: Int
        var followed: Int
        var failed: Int
        var pending: Int
    }

    struct HabitCommitmentItem: Codable, Identifiable {
        var id: String
        var title: String
        var categoryColorHex: String?
        var status: String                     // "FOLLOWED" | "FAILED" | "PENDING"
    }

    struct CategoryWidgetData: Codable, Identifiable {
        var id: String                     // UUID string
        var name: String
        var colorHex: String
        var streak: Int
        var statusToday: String            // "green" | "red" | "future"
        var recentDays: [String: String]
    }

    struct GoalWidgetData: Codable, Identifiable {
        var id: String                     // UUID string
        var title: String
        var categoryId: String?            // UUID string
        var categoryColorHex: String?
        var currentValue: Double
        var targetValue: Double
        var unit: String
        var progressFraction: Double
        var isCompleted: Bool
        var targetDate: Date?
    }

    struct MonthlyExpenseWidgetData: Codable {
        var totalSpentThisMonth: Double
        var currencySymbol: String
        var monthName: String
        var year: Int
    }
}

// MARK: - App Group key + helpers

enum WidgetDataStore {
    static var appGroupID: String {
        ProcessInfo.processInfo.environment["APP_GROUP_ID"] ?? "group.com.yashgarg29.Streak"
    }
    static let key = "widgetData"

    static func save(_ data: WidgetData) {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let encoded = try? JSONEncoder().encode(data) else { return }
        defaults.set(encoded, forKey: key)
    }

    static func load() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) else { return nil }
        return decoded
    }

    static func clearAll() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.removeObject(forKey: key)
        defaults.synchronize()
    }
}

// MARK: - Interactive widget queue
// Widgets can't open the SwiftData store, so a tap on a widget checkbox updates the
// cached WidgetData optimistically and queues the change here. The app applies the
// queue through the normal task-completion flow the next time it runs.

enum WidgetTaskToggleQueue {
    struct Toggle: Codable {
        var taskId: String
        var completed: Bool
        var toggledAt: Date
    }

    static let key = "pendingWidgetTaskToggles"

    static func enqueue(taskId: String, completed: Bool) {
        guard let defaults = UserDefaults(suiteName: WidgetDataStore.appGroupID) else { return }
        var toggles = load(from: defaults).filter { $0.taskId != taskId }
        toggles.append(Toggle(taskId: taskId, completed: completed, toggledAt: Date()))
        if let encoded = try? JSONEncoder().encode(toggles) {
            defaults.set(encoded, forKey: key)
        }
    }

    /// Returns every queued toggle and clears the queue.
    static func drain() -> [Toggle] {
        guard let defaults = UserDefaults(suiteName: WidgetDataStore.appGroupID) else { return [] }
        let toggles = load(from: defaults)
        defaults.removeObject(forKey: key)
        return toggles
    }

    private static func load(from defaults: UserDefaults) -> [Toggle] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Toggle].self, from: data)) ?? []
    }
}
