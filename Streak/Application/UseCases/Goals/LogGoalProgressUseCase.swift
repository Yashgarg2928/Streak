// Application/UseCases/Goals/LogGoalProgressUseCase.swift
// Logs manual numeric progress increments for Milestone-based goals.

import Foundation

struct LogGoalProgressUseCase {
    let goalRepository: any GoalRepository
    let syncGoalProgress: SyncGoalProgressUseCase

    func execute(goalId: UUID, value: Double, note: String?, date: Date = Date()) throws {
        guard let goal = try goalRepository.fetch(id: goalId) else { return }
        guard goal.goalType == .milestoneBased else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        
        // Upsert daily progress entry
        let entry: GoalProgressEntry
        if let existing = try goalRepository.fetchProgressEntry(goalId: goalId, date: startOfDay) {
            entry = GoalProgressEntry(
                goalId: goalId,
                date: startOfDay,
                value: existing.value + value, // accumulate values logged on the same day
                note: note ?? existing.note
            )
        } else {
            entry = GoalProgressEntry(
                goalId: goalId,
                date: startOfDay,
                value: value,
                note: note
            )
        }
        
        try goalRepository.saveProgressEntry(entry)
        
        // Sync values immediately
        try syncGoalProgress.execute()
    }
}
