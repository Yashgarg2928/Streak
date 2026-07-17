// Application/UseCases/Goals/SyncGoalProgressUseCase.swift
// Evaluates and updates goals progress based on their respective tracking types.

import Foundation

struct SyncGoalProgressUseCase {
    let goalRepository: any GoalRepository
    let dayEntryRepository: any DayEntryRepository
    let taskRepository: any TaskRepository

    func execute() throws {
        let goals = try goalRepository.fetchAll()
        for var goal in goals {
            guard !goal.isCompleted else { continue }
            
            switch goal.goalType {
            case .consecutiveStreak:
                if let categoryId = goal.categoryId {
                    let streak = try CalculateStreakUseCase(dayEntryRepository: dayEntryRepository)
                        .execute(categoryId: categoryId)
                    goal.currentValue = Double(streak)
                }
            case .cumulativeDays:
                if let categoryId = goal.categoryId {
                    let entries = try dayEntryRepository.fetchAll(categoryId: categoryId)
                    let count = entries.filter { 
                        $0.status == .green && 
                        $0.date >= Calendar.current.startOfDay(for: goal.startDate) 
                    }.count
                    goal.currentValue = Double(count)
                }
            case .taskCounter:
                if let categoryId = goal.categoryId {
                    let tasks = try taskRepository.fetchAll()
                    let count = tasks.filter { 
                        !$0.isDeleted &&
                        $0.categoryId == categoryId && 
                        $0.isCompleted && 
                        $0.targetDate >= Calendar.current.startOfDay(for: goal.startDate) 
                    }.count
                    goal.currentValue = Double(count)
                }
            case .milestoneBased:
                let entries = try goalRepository.fetchProgressEntries(goalId: goal.id)
                let sum = entries.map { $0.value }.reduce(0, +)
                goal.currentValue = sum
            }
            
            // Mark completed if target threshold reached
            if goal.currentValue >= goal.targetValue {
                goal.isCompleted = true
            } else {
                goal.isCompleted = false
            }
            
            try goalRepository.save(goal)
        }
    }
}
