// Application/UseCases/Habits/CalculateStreakHistoryUseCase.swift
// Computes the full history of consecutive green-day streaks for a
// category (or master/overall when categoryId is nil).
// Rest and frozen days bridge a run without adding to its length.

import Foundation

/// A single unbroken run of consecutive green days.
struct StreakRun: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let length: Int          // number of green days
}

struct CalculateStreakHistoryUseCase {
    let dayEntryRepository: any DayEntryRepository

    /// Returns (runs sorted newest-first, allTimeHigh).
    func execute(categoryId: UUID?) throws -> (runs: [StreakRun], highStreak: Int) {
        let entries = try dayEntryRepository.fetchAll(categoryId: categoryId)
        let cal = Calendar.current

        var statusByDay: [Date: DayStatus] = [:]
        for entry in entries {
            statusByDay[cal.startOfDay(for: entry.date)] = entry.status
        }

        let sorted = statusByDay.filter { $0.value == .green }.keys.sorted()   // ascending
        guard let first = sorted.first else { return ([], 0) }

        // True when every day strictly between the two dates is a rest/frozen day.
        func isBridged(from prev: Date, to curr: Date) -> Bool {
            var day = cal.date(byAdding: .day, value: 1, to: prev)!
            while day < curr {
                guard statusByDay[day]?.isStreakNeutral == true else { return false }
                day = cal.date(byAdding: .day, value: 1, to: day)!
            }
            return true
        }

        var runs: [StreakRun] = []
        var runStart = first
        var runEnd   = first
        var runLen   = 1

        for curr in sorted.dropFirst() {
            if isBridged(from: runEnd, to: curr) {
                runEnd  = curr
                runLen += 1
            } else {
                runs.append(StreakRun(startDate: runStart, endDate: runEnd, length: runLen))
                runStart = curr
                runEnd   = curr
                runLen   = 1
            }
        }
        runs.append(StreakRun(startDate: runStart, endDate: runEnd, length: runLen))

        let highStreak = runs.map(\.length).max() ?? 0

        // Return newest-first
        return (runs.reversed(), highStreak)
    }
}
