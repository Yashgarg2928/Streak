// Domain/ValueObjects/DayStatus.swift
// Pure Swift — no UIKit, SwiftUI, or SwiftData imports

import Foundation

enum DayStatus: String, Codable, Equatable {
    case green      // all tasks completed
    case red        // tasks missed OR no tasks set for that day
    case future     // date is in the future

    // Business rule: resolve status from task counts and date
    static func resolve(taskCount: Int, completedCount: Int, date: Date) -> DayStatus {
        let today = Calendar.current.startOfDay(for: Date())
        let day = Calendar.current.startOfDay(for: date)
        if day > today { return .future }
        if taskCount == 0 { return .red }
        if completedCount == taskCount { return .green }
        return .red
    }
}
