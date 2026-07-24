// Application/UseCases/Gamification/ShopPurchaseUseCase.swift

import Foundation

public enum ShopPurchaseError: LocalizedError {
    case insufficientXP(required: Int, available: Int)
    case levelRequirementNotMet(requiredLevel: Int, currentLevel: Int)
    case inventoryLimitReached(maxAllowed: Int)
    case rewardAlreadyRedeemed
    
    public var errorDescription: String? {
        switch self {
        case .insufficientXP(let req, let avail):
            return "Insufficient XP: Need \(req) XP, but you have \(avail) XP."
        case .levelRequirementNotMet(let reqLvl, let curLvl):
            return "Level Locked: Requires Level \(reqLvl). Current Level is \(curLvl)."
        case .inventoryLimitReached(let max):
            return "Inventory Limit Reached: You can hold at most \(max) of this item."
        case .rewardAlreadyRedeemed:
            return "This custom reward has already been redeemed."
        }
    }
}

public struct ShopPurchaseUseCase {
    let playerProfileRepository: any PlayerProfileRepository
    let xpTransactionRepository: any XPTransactionRepository
    let shopItemRepository: any ShopItemRepository
    let customRewardRepository: any CustomRewardRepository
    let badgeRepository: any BadgeRepository

    public func purchaseFixedItem(_ type: FixedShopItemType) throws {
        var profile = try playerProfileRepository.fetchProfile()
        let currentLvl = profile.currentLevel
        
        // Level check
        guard currentLvl >= type.minLevel else {
            throw ShopPurchaseError.levelRequirementNotMet(requiredLevel: type.minLevel, currentLevel: currentLvl)
        }
        
        // XP check
        guard profile.totalXP >= type.xpCost else {
            throw ShopPurchaseError.insufficientXP(required: type.xpCost, available: profile.totalXP)
        }
        
        // Inventory limit check
        if type == .streakFreeze {
            guard profile.streakFreezes < 2 else {
                throw ShopPurchaseError.inventoryLimitReached(maxAllowed: 2)
            }
            profile.streakFreezes += 1
        }
        
        profile.totalXP -= type.xpCost
        profile.lastUpdated = Date()
        try playerProfileRepository.saveProfile(profile)
        
        // Save shop item
        let now = Date()
        let expiresAt: Date?
        if type == .xpBoost {
            expiresAt = Date(timeIntervalSinceNow: 24 * 3600)
            profile.activeBoostExpiry = expiresAt
            try playerProfileRepository.saveProfile(profile)
        } else {
            expiresAt = nil
        }
        
        let item = ShopItem(itemType: type, purchasedAt: now, expiresAt: expiresAt)
        try shopItemRepository.save(item)
        
        // Record XP transaction
        let tx = XPTransaction(date: now, amount: -type.xpCost, reason: .shopPurchase, note: "Bought \(type.title)")
        try xpTransactionRepository.save(tx)
        
        // Award shop badges
        try awardShopBadge("first_purchase")
        if profile.streakFreezes >= 2 {
            try awardShopBadge("well_stocked")
        }
    }

    public func redeemCustomReward(id: UUID) throws {
        guard var reward = try customRewardRepository.fetch(id: id) else { return }
        guard !reward.isRedeemed else { throw ShopPurchaseError.rewardAlreadyRedeemed }
        
        var profile = try playerProfileRepository.fetchProfile()
        guard profile.totalXP >= reward.xpCost else {
            throw ShopPurchaseError.insufficientXP(required: reward.xpCost, available: profile.totalXP)
        }
        
        let now = Date()
        profile.totalXP -= reward.xpCost
        profile.lastUpdated = now
        try playerProfileRepository.saveProfile(profile)
        
        reward.redeemedAt = now
        try customRewardRepository.save(reward)
        
        let tx = XPTransaction(date: now, amount: -reward.xpCost, reason: .customRewardRedemption, note: "Redeemed reward: \(reward.title)")
        try xpTransactionRepository.save(tx)
        
        try awardShopBadge("self_aware")
    }

    private func awardShopBadge(_ key: String) throws {
        if (try? badgeRepository.fetch(byKey: key)) == nil {
            try badgeRepository.save(Badge(badgeKey: key, earnedAt: Date()))
        }
    }
}
