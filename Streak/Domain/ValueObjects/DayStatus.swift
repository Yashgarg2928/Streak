// Domain/ValueObjects/DayStatus.swift
// Pure Swift — no UIKit, SwiftUI, or SwiftData imports

import Foundation

enum DayStatus: String, Codable, Equatable {
    case green      // all tasks completed for category / master day
    case red        // planning deadline passed with 0 tasks OR day has ended with incomplete tasks
    case future     // blank / in-progress active day or future day
    case rest       // scheduled rest day — neither extends nor breaks a streak
    case frozen     // missed day protected by a Streak Freeze — neither extends nor breaks a streak

    /// Rest and frozen days are skipped over when counting streaks.
    var isStreakNeutral: Bool { self == .rest || self == .frozen }

    // Business rule: resolve status from task counts, date, and planning deadline status.
    // `taskCount` / `completedCount` are the *required* tasks (late additions excluded).
    static func resolve(
        taskCount: Int,
        completedCount: Int,
        date: Date,
        activeDate: Date,
        isPlanningDeadlinePassed: Bool = false,
        isRestDay: Bool = false
    ) -> DayStatus {
        let day = Calendar.current.startOfDay(for: date)
        let active = Calendar.current.startOfDay(for: activeDate)

        // 1. Turning GREEN: All tasks scheduled for the day are completed
        if taskCount > 0 && completedCount == taskCount {
            return .green
        }

        // 2. Rest days can never turn red
        if isRestDay {
            return .rest
        }

        // 3. Turning RED (Checked at two specific times):
        // Time 1: Planning deadline has passed AND user forgot to create tasks for the active day
        if isPlanningDeadlinePassed && taskCount == 0 && day >= active {
            return .red
        }

        // Time 2: The active day has ended (past day) and tasks were incomplete or missing
        if day < active {
            return .red
        }

        // 4. Otherwise: Day stays BLANK (in-progress active day with pending tasks or before deadline)
        return .future
    }
}
