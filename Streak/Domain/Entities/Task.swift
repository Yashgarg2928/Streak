// Domain/Entities/Task.swift
// Pure Swift — no UIKit, SwiftUI, or SwiftData imports

import Foundation

struct Task: Identifiable, Equatable {
    let id: UUID
    var title: String
    var categoryId: UUID?       // nil = uncategorized
    var targetDate: Date        // date only (time truncated to midnight)
    var isCompleted: Bool
    var completedAt: Date?
    let createdAt: Date
    var isDeleted: Bool

    init(
        id: UUID = UUID(),
        title: String,
        categoryId: UUID? = nil,
        targetDate: Date,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        isDeleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.categoryId = categoryId
        self.targetDate = Calendar.current.startOfDay(for: targetDate)
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.isDeleted = isDeleted
    }
}
