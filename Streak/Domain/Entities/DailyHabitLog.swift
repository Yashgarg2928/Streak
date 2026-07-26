// Domain/Entities/DailyHabitLog.swift

import Foundation

public enum HabitCheckStatus: String, Codable {
    case followed = "FOLLOWED"       // Tick ✅
    case failed = "FAILED"           // Cross ❌
    case pending = "PENDING"         // Not yet checked in
}

public struct DailyHabitLog: Identifiable, Equatable {
    public let id: UUID
    public var date: Date             // Start of day date
    public var habitId: UUID
    public var status: HabitCheckStatus
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        date: Date,
        habitId: UUID,
        status: HabitCheckStatus = .pending,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.habitId = habitId
        self.status = status
        self.updatedAt = updatedAt
    }
}
