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
    var categories: [CategoryWidgetData]
    var goals: [GoalWidgetData]
    var lastUpdated: Date
    var activeDayDeadline: Date

    struct TaskSummary: Codable {
        var total: Int
        var completed: Int
    }

    struct TaskItem: Codable {
        var title: String
        var isCompleted: Bool
        var categoryColorHex: String?
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
}

// MARK: - App Group key + helpers

enum WidgetDataStore {
    static let appGroupID = "group.com.madhvan.streak"
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
}
