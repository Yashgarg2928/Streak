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
    /// Calendar weekdays (1 = Sunday … 7 = Saturday) the habit runs on. Empty = every day.
    var weekdays: Set<Int>
    /// When set, the habit's task is ticked automatically once synced Health data meets the target.
    var healthRule: HealthRule?

    init(
        id: UUID = UUID(),
        title: String,
        categoryId: UUID? = nil,
        type: HabitRoutineType = .monthlyFixed,
        startDate: Date = Date(),
        endDate: Date = Date(),
        isLocked: Bool = false,
        createdAt: Date = Date(),
        weekdays: Set<Int> = [],
        healthRule: HealthRule? = nil
    ) {
        self.id = id
        self.title = title
        self.categoryId = categoryId
        self.type = type
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.endDate = Calendar.current.startOfDay(for: endDate)
        self.isLocked = (type == .monthlyFixed) ? true : isLocked
        self.createdAt = createdAt
        self.weekdays = weekdays.count == 7 ? [] : weekdays
        self.healthRule = healthRule
    }

    /// Whether `date` falls inside the habit's start/end range (monthly commitments run on indefinitely).
    func isInDateRange(_ date: Date) -> Bool {
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        guard day >= cal.startOfDay(for: startDate) else { return false }
        return type == .monthlyFixed || day <= cal.startOfDay(for: endDate)
    }

    /// Whether the habit generates a task on `date` (ignores the start/end range).
    func isScheduled(on date: Date) -> Bool {
        weekdays.isEmpty || weekdays.contains(Calendar.current.component(.weekday, from: date))
    }
}
