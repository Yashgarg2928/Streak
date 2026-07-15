// Domain/ValueObjects/DayStatus.swift
// Pure Swift — no UIKit, SwiftUI, or SwiftData imports

import Foundation

enum DayStatus: String, Codable, Equatable {
    case green      // all tasks completed
    case red        // tasks missed OR no tasks set for that day
    case future     // date is in the future

    // Business rule: resolve status from task counts and date
    static func resolve(taskCount: Int, completedCount: Int, date: Date, activeDate: Date) -> DayStatus {
        let day = Calendar.current.startOfDay(for: date)
        let active = Calendar.current.startOfDay(for: activeDate)
        if day > active { return .future }
        if taskCount == 0 { return .red }
        if completedCount == taskCount { return .green }
        return .red
    }
}
