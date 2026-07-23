// Application/UseCases/Habits/CalculateStreakHistoryUseCase.swift
// Computes the full history of consecutive green-day streaks for a
// category (or master/overall when categoryId is nil).

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

        // Build a set of all green dates
        let greenDates: Set<Date> = Set(
            entries
                .filter { $0.status == .green }
                .map { cal.startOfDay(for: $0.date) }
        )

        guard !greenDates.isEmpty else { return ([], 0) }

        let sorted = greenDates.sorted()          // ascending

        var runs: [StreakRun] = []
        var runStart = sorted[0]
        var runEnd   = sorted[0]
        var runLen   = 1

        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let curr = sorted[i]
            let daysBetween = cal.dateComponents([.day], from: prev, to: curr).day ?? 0

            if daysBetween == 1 {
                // Consecutive — extend current run
                runEnd  = curr
                runLen += 1
            } else {
                // Gap — close the current run and start a new one
                runs.append(StreakRun(startDate: runStart, endDate: runEnd, length: runLen))
                runStart = curr
                runEnd   = curr
                runLen   = 1
            }
        }
        // Close final run
        runs.append(StreakRun(startDate: runStart, endDate: runEnd, length: runLen))

        let highStreak = runs.map(\.length).max() ?? 0

        // Return newest-first
        return (runs.reversed(), highStreak)
    }
}
