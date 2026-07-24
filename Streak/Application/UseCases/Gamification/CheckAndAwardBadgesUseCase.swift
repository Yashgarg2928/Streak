// Application/UseCases/Gamification/CheckAndAwardBadgesUseCase.swift

import Foundation

public struct CheckAndAwardBadgesUseCase {
    let playerProfileRepository: any PlayerProfileRepository
    let badgeRepository: any BadgeRepository
    let dayEntryRepository: any DayEntryRepository
    let taskRepository: any TaskRepository
    let goalRepository: any GoalRepository
    let habitRoutineRepository: any HabitRoutineRepository

    public func execute() throws {
        let profile = try playerProfileRepository.fetchProfile()
        let existingBadges = Set(try badgeRepository.fetchAll().map(\.badgeKey))
        let level = profile.currentLevel
        
        let masterStreak = try CalculateStreakUseCase(dayEntryRepository: dayEntryRepository)
            .execute(categoryId: nil)
        let totalTasks = (try? taskRepository.fetchAll())?.filter { $0.isCompleted }.count ?? 0
        let routinesCount = (try? habitRoutineRepository.fetchAll())?.count ?? 0
        let completedGoalsCount = (try? goalRepository.fetchAll())?.filter { $0.isCompleted }.count ?? 0
        let totalGoalsCount = (try? goalRepository.fetchAll())?.count ?? 0

        func grant(_ key: String) throws {
            if !existingBadges.contains(key) {
                let badge = Badge(badgeKey: key, earnedAt: Date())
                try badgeRepository.save(badge)
            }
        }

        // 🔥 Streak Badges
        if masterStreak >= 1 { try grant("first_flame") }
        if masterStreak >= 7 { try grant("week_warrior") }
        if masterStreak >= 14 { try grant("fortnight_fighter") }
        if masterStreak >= 30 { try grant("month_master") }
        if masterStreak >= 100 { try grant("century_keeper") }
        if masterStreak >= 365 { try grant("365_club") }

        // 🏗 Consistency Badges
        if routinesCount >= 1 { try grant("habit_starter") }
        if routinesCount >= 3 { try grant("habit_stack") }
        if totalTasks >= 100 { try grant("century_tasks") }
        if totalTasks >= 1000 { try grant("task_titan") }

        // 🎯 Goal Badges
        if totalGoalsCount >= 1 { try grant("goal_setter") }
        if completedGoalsCount >= 1 { try grant("goal_crusher") }
        if completedGoalsCount >= 3 { try grant("overachiever") }

        // 🏅 Level Badges
        if level >= 10 { try grant("lvl_rising") }
        if level >= 20 { try grant("lvl_committed") }
        if level >= 50 { try grant("lvl_elite") }
    }
}
