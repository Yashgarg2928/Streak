// Domain/Entities/GoalProgressEntry.swift
// Pure Swift — no UIKit, SwiftUI, or SwiftData imports

import Foundation

struct GoalProgressEntry: Identifiable, Equatable {
    let id: UUID
    var goalId: UUID
    var date: Date              // midnight of the day
    var value: Double           // absolute cumulative total, not delta
    var note: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        goalId: UUID,
        date: Date,
        value: Double,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.goalId = goalId
        self.date = Calendar.current.startOfDay(for: date)
        self.value = value
        self.note = note
        self.createdAt = createdAt
    }
}
