// Application/UseCases/Habits/CalculateStreakUseCase.swift
// Walks backward from today counting consecutive green days.

import Foundation

struct CalculateStreakUseCase {
    let dayEntryRepository: any DayEntryRepository

    func execute(categoryId: UUID?) throws -> Int {
        let entries = try dayEntryRepository.fetchAll(categoryId: categoryId)
        let cal = Calendar.current

        var statusByDay: [Date: DayStatus] = [:]
        for entry in entries {
            statusByDay[entry.date] = entry.status
        }

        var streak = 0
        var cursor = cal.startOfDay(for: Date())

        while true {
            let status = statusByDay[cursor]
            if status == .green {
                streak += 1
                cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
            } else {
                break
            }
        }

        return streak
    }
}
