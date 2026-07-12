// Domain/Entities/Goal.swift
// Pure Swift — no UIKit, SwiftUI, or SwiftData imports

import Foundation

struct Goal: Identifiable, Equatable {
    let id: UUID
    var title: String
    var goalType: GoalType
    var categoryId: UUID?
    var targetValue: Double
    var currentValue: Double
    var unit: String
    var startDate: Date
    var targetDate: Date?
    var isCompleted: Bool
    var dailyNotificationTime: Date?
    let createdAt: Date

    var progressFraction: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }

    init(
        id: UUID = UUID(),
        title: String,
        goalType: GoalType,
        categoryId: UUID? = nil,
        targetValue: Double,
        currentValue: Double = 0,
        unit: String,
        startDate: Date = Date(),
        targetDate: Date? = nil,
        isCompleted: Bool = false,
        dailyNotificationTime: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.goalType = goalType
        self.categoryId = categoryId
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = unit
        self.startDate = startDate
        self.targetDate = targetDate
        self.isCompleted = isCompleted
        self.dailyNotificationTime = dailyNotificationTime
        self.createdAt = createdAt
    }
}
