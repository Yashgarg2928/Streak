// Application/UseCases/Gamification/DeductXPUseCase.swift

import Foundation

struct DeductXPUseCase {
    let playerProfileRepository: any PlayerProfileRepository
    let xpTransactionRepository: any XPTransactionRepository

    @discardableResult
    func execute(penaltyAmount: Int, reason: XPTransactionReason, note: String? = nil) throws -> Int {
        guard penaltyAmount > 0 else { return 0 }
        
        var profile = try playerProfileRepository.fetchProfile()
        let now = Date()
        
        // Deduct penalty (XP cannot drop below 0)
        let actualDeduction = min(profile.totalXP, penaltyAmount)
        guard actualDeduction > 0 else { return 0 }
        
        profile.totalXP -= actualDeduction
        profile.lastUpdated = now
        
        try playerProfileRepository.saveProfile(profile)
        
        // Record negative XP transaction
        let transaction = XPTransaction(date: now, amount: -actualDeduction, reason: reason, note: note)
        try xpTransactionRepository.save(transaction)
        
        return actualDeduction
    }
}
