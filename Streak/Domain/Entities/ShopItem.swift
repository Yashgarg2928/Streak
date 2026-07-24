// Domain/Entities/ShopItem.swift

import Foundation

public enum FixedShopItemType: String, Codable, CaseIterable, Identifiable {
    case streakFreeze = "streak_freeze"
    case xpBoost = "xp_boost"
    case doubleHabitDay = "double_habit_day"
    case weekendShield = "weekend_shield"
    case bingeNightPass = "binge_night_pass"
    case restDayPass = "rest_day_pass"
    case xpMultiplierWeek = "xp_multiplier_week"
    case prestigeBadgeSlot = "prestige_badge_slot"
    case legendaryStreakArmor = "legendary_streak_armor"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .streakFreeze: return "Streak Freeze"
        case .xpBoost: return "24h XP Boost"
        case .doubleHabitDay: return "Double Habit Day"
        case .weekendShield: return "Weekend Shield"
        case .bingeNightPass: return "Binge Night Pass"
        case .restDayPass: return "Rest Day Pass"
        case .xpMultiplierWeek: return "1-Week XP Multiplier"
        case .prestigeBadgeSlot: return "Prestige Badge Slot"
        case .legendaryStreakArmor: return "Legendary Streak Armor"
        }
    }

    public var emoji: String {
        switch self {
        case .streakFreeze: return "⛄"
        case .xpBoost: return "⚡"
        case .doubleHabitDay: return "🔄"
        case .weekendShield: return "📅"
        case .bingeNightPass: return "🌙"
        case .restDayPass: return "💤"
        case .xpMultiplierWeek: return "🎯"
        case .prestigeBadgeSlot: return "🏆"
        case .legendaryStreakArmor: return "☄️"
        }
    }

    public var xpCost: Int {
        switch self {
        case .streakFreeze: return 500
        case .xpBoost: return 750
        case .doubleHabitDay: return 1000
        case .weekendShield: return 1250
        case .bingeNightPass: return 1500
        case .restDayPass: return 1000
        case .xpMultiplierWeek: return 3500
        case .prestigeBadgeSlot: return 5000
        case .legendaryStreakArmor: return 12000
        }
    }

    public var minLevel: Int {
        switch self {
        case .streakFreeze: return 3
        case .xpBoost: return 5
        case .doubleHabitDay: return 8
        case .weekendShield: return 10
        case .restDayPass: return 12
        case .bingeNightPass: return 15
        case .xpMultiplierWeek: return 25
        case .prestigeBadgeSlot: return 30
        case .legendaryStreakArmor: return 50
        }
    }

    public var effectDescription: String {
        switch self {
        case .streakFreeze: return "Protects your streak for 1 missed day."
        case .xpBoost: return "All XP earned in the next 24h is doubled."
        case .doubleHabitDay: return "Triple XP for all completed habits for 1 day."
        case .weekendShield: return "Protects streak across Sat & Sun."
        case .bingeNightPass: return "One guilt-free evening off without breaking streak."
        case .restDayPass: return "Covers a full calendar day of rest."
        case .xpMultiplierWeek: return "1.5× XP multiplier for 7 full days."
        case .prestigeBadgeSlot: return "Unlocks a custom profile badge slot."
        case .legendaryStreakArmor: return "Protects 30+ day streak for up to 3 missed days in a month."
        }
    }
}

public struct ShopItem: Identifiable, Equatable {
    public let id: UUID
    public let itemType: FixedShopItemType
    public let purchasedAt: Date
    public var usedAt: Date?
    public var expiresAt: Date?

    public init(
        id: UUID = UUID(),
        itemType: FixedShopItemType,
        purchasedAt: Date = Date(),
        usedAt: Date? = nil,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.itemType = itemType
        self.purchasedAt = purchasedAt
        self.usedAt = usedAt
        self.expiresAt = expiresAt
    }
}
