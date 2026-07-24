// Application/UseCases/Gamification/AwardXPUseCase.swift

import Foundation

public struct AwardXPUseCase {
    let playerProfileRepository: any PlayerProfileRepository
    let xpTransactionRepository: any XPTransactionRepository
    let badgeRepository: any BadgeRepository
    let dayEntryRepository: any DayEntryRepository
    let taskRepository: any TaskRepository
    let goalRepository: any GoalRepository
    let habitRoutineRepository: any HabitRoutineRepository

    public func execute(amount: Int, reason: XPTransactionReason, note: String? = nil) throws -> Int {
        guard amount > 0 else { return 0 }
        
        var profile = try playerProfileRepository.fetchProfile()
        let now = Date()
        
        // Calculate boost multiplier if active
        var multiplier: Double = 1.0
        if let expiry = profile.activeBoostExpiry, expiry > now {
            multiplier *= 2.0
        }
        
        let finalAmount = Int(Double(amount) * multiplier)
        let oldLevel = profile.currentLevel
        
        profile.totalXP += finalAmount
        profile.lastUpdated = now
        
        try playerProfileRepository.saveProfile(profile)
        
        // Record transaction
        let transaction = XPTransaction(date: now, amount: finalAmount, reason: reason, note: note)
        try xpTransactionRepository.save(transaction)
        
        // Check and unlock any badges earned by this XP gain / level up
        let badgeUseCase = CheckAndAwardBadgesUseCase(
            playerProfileRepository: playerProfileRepository,
            badgeRepository: badgeRepository,
            dayEntryRepository: dayEntryRepository,
            taskRepository: taskRepository,
            goalRepository: goalRepository,
            habitRoutineRepository: habitRoutineRepository
        )
        try badgeUseCase.execute()
        
        return finalAmount
    }
}
