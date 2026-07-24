// Application/UseCases/Gamification/DeductXPUseCase.swift

import Foundation

public struct DeductXPUseCase {
    let playerProfileRepository: any PlayerProfileRepository
    let xpTransactionRepository: any XPTransactionRepository

    public func execute(amount: Int, reason: XPTransactionReason, note: String? = nil) throws -> Int {
        guard amount > 0 else { return 0 }
        
        var profile = try playerProfileRepository.fetchProfile()
        let now = Date()
        
        // Anti-death spiral: XP cannot go below 0
        let actualDeduction = min(profile.totalXP, amount)
        guard actualDeduction > 0 else { return 0 }
        
        profile.totalXP -= actualDeduction
        profile.lastUpdated = now
        
        try playerProfileRepository.saveProfile(profile)
        
        // Record negative transaction
        let transaction = XPTransaction(date: now, amount: -actualDeduction, reason: reason, note: note)
        try xpTransactionRepository.save(transaction)
        
        return actualDeduction
    }
}
