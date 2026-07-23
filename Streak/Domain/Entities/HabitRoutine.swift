// Domain/Entities/HabitRoutine.swift
// Pure Swift — no UIKit, SwiftUI, or SwiftData imports

import Foundation

enum HabitRoutineType: String, Codable, CaseIterable {
    case monthlyFixed = "MONTHLY_LOCKED" // Everyday for current month — immutable & un-deletable
    case customRange  = "CUSTOM_SPRINT"  // Everyday for specific date range (e.g. 7-day sprint)
}

struct HabitRoutine: Identifiable, Equatable {
    let id: UUID
    var title: String
    var categoryId: UUID?
    var type: HabitRoutineType
    var startDate: Date
    var endDate: Date
    var isLocked: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        categoryId: UUID? = nil,
        type: HabitRoutineType = .monthlyFixed,
        startDate: Date = Date(),
        endDate: Date = Date(),
        isLocked: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.categoryId = categoryId
        self.type = type
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.endDate = Calendar.current.startOfDay(for: endDate)
        self.isLocked = (type == .monthlyFixed) ? true : isLocked
        self.createdAt = createdAt
    }
}
