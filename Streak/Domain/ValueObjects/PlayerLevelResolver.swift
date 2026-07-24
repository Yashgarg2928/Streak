// Domain/ValueObjects/PlayerLevelResolver.swift

import Foundation

public struct PlayerLevelResolver {
    /// Calculate level from total XP using polynomial formula: XP = 100 * (Level ^ 1.8)
    public static func level(for totalXP: Int) -> Int {
        guard totalXP > 0 else { return 1 }
        let l = pow(Double(totalXP) / 100.0, 1.0 / 1.8)
        return max(1, Int(floor(l)))
    }
    
    /// XP required to reach a specific level from zero
    public static func totalXPRequired(for level: Int) -> Int {
        guard level > 1 else { return 0 }
        return Int(ceil(100.0 * pow(Double(level), 1.8)))
    }
    
    /// XP progress within the current level: (currentInLevel, totalForLevel, progressFraction)
    public static func levelProgress(totalXP: Int) -> (current: Int, required: Int, fraction: Double) {
        let currentLvl = level(for: totalXP)
        let baseXP = totalXPRequired(for: currentLvl)
        let nextXP = totalXPRequired(for: currentLvl + 1)
        
        let xpInLevel = max(0, totalXP - baseXP)
        let span = max(1, nextXP - baseXP)
        let fraction = min(1.0, max(0.0, Double(xpInLevel) / Double(span)))
        
        return (current: xpInLevel, required: span, fraction: fraction)
    }
}
