// Domain/Entities/CustomReward.swift

import Foundation

public struct CustomReward: Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var rewardDescription: String
    public var categoryId: UUID?            // nil = Overall / Category-free
    public var tier: CustomRewardTier
    public var xpCost: Int                  // Derived from tier.xpCost
    public var targetMonth: Date            // First day of month (e.g. 2026-07-01)
    public var isLocked: Bool               // True during active month, editable at month boundary
    public var redeemedAt: Date?            // Timestamp when redeemed with XP (nil = available)
    public var createdAt: Date

    public var isRedeemed: Bool {
        redeemedAt != nil
    }

    public init(
        id: UUID = UUID(),
        title: String,
        rewardDescription: String = "",
        categoryId: UUID? = nil,
        tier: CustomRewardTier,
        targetMonth: Date = Date(),
        isLocked: Bool = true,
        redeemedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.rewardDescription = rewardDescription
        self.categoryId = categoryId
        self.tier = tier
        self.xpCost = tier.xpCost
        
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: targetMonth)
        self.targetMonth = cal.date(from: comps) ?? targetMonth
        self.isLocked = isLocked
        self.redeemedAt = redeemedAt
        self.createdAt = createdAt
    }
}
