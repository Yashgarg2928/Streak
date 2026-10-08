// Application/UseCases/Habits/CalculateStreakUseCase.swift
// Walks backward from the active day counting consecutive green days.
// Rest and frozen days are skipped (they neither extend nor break the streak),
// and an in-progress active day doesn't break it either.

import Foundation

struct CalculateStreakUseCase {
    let dayEntryRepository: any DayEntryRepository
    let settingsRepository: any SettingsRepository

    func execute(categoryId: UUID?) throws -> Int {
        let today = ActiveDayResolver.resolveActiveDate(for: Date(), settings: settingsRepository)
        return try execute(categoryId: categoryId, endingAt: today, treatEndAsInProgress: true)
    }

    /// Streak ending at `date`. When `treatEndAsInProgress` is true, a not-yet-resolved
    /// status on `date` is skipped instead of ending the count.
    func execute(categoryId: UUID?, endingAt date: Date, treatEndAsInProgress: Bool = false) throws -> Int {
        let entries = try dayEntryRepository.fetchAll(categoryId: categoryId)
        let cal = Calendar.current

        var statusByDay: [Date: DayStatus] = [:]
        for entry in entries {
            statusByDay[cal.startOfDay(for: entry.date)] = entry.status
        }

        let end = cal.startOfDay(for: date)
        var streak = 0
        var cursor = end

        while true {
            switch statusByDay[cursor] {
            case .green:
                streak += 1
            case .rest, .frozen:
                break
            case .red:
                return streak
            case .future, .none:
                guard treatEndAsInProgress && cursor == end else { return streak }
            }
            guard let previous = cal.date(byAdding: .day, value: -1, to: cursor) else { return streak }
            cursor = previous
        }
    }
}
