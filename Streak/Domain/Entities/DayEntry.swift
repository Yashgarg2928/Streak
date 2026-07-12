// Domain/Entities/DayEntry.swift
// Pure Swift — no UIKit, SwiftUI, or SwiftData imports

import Foundation

struct DayEntry: Identifiable, Equatable {
    let id: UUID
    var date: Date              // midnight of the day
    var categoryId: UUID?       // nil = master entry
    var status: DayStatus
    var taskCount: Int
    var completedCount: Int
    var lastUpdated: Date

    init(
        id: UUID = UUID(),
        date: Date,
        categoryId: UUID? = nil,
        status: DayStatus,
        taskCount: Int,
        completedCount: Int,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.categoryId = categoryId
        self.status = status
        self.taskCount = taskCount
        self.completedCount = completedCount
        self.lastUpdated = lastUpdated
    }
}
