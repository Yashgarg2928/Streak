// Domain/Entities/ReflectionEntry.swift
// Pure Swift — no UIKit, SwiftUI, or SwiftData imports

import Foundation

struct ReflectionEntry: Identifiable, Equatable {
    let id: UUID
    var date: Date              // midnight of the day (one per day)
    var accomplishments: String
    var missedItems: String
    var tomorrowPriorities: String
    var goalNotes: String
    var consistencyRating: Int  // 1–5
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        accomplishments: String = "",
        missedItems: String = "",
        tomorrowPriorities: String = "",
        goalNotes: String = "",
        consistencyRating: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.accomplishments = accomplishments
        self.missedItems = missedItems
        self.tomorrowPriorities = tomorrowPriorities
        self.goalNotes = goalNotes
        self.consistencyRating = max(0, min(5, consistencyRating))
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
