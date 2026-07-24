// Domain/ValueObjects/BadgeDefinition.swift

import Foundation

public enum BadgeCategory: String, Codable, CaseIterable {
    case streak = "Streak"
    case consistency = "Consistency"
    case goal = "Goals"
    case level = "Level"
    case shop = "Shop"
    case adversity = "Adversity"
}

public struct BadgeDefinition: Identifiable, Equatable {
    public var id: String { key }
    public let key: String
    public let title: String
    public let description: String
    public let iconName: String   // SF Symbol or Emoji
    public let isEmoji: Bool
    public let category: BadgeCategory
    public let isSecret: Bool
    
    public static let allBadges: [BadgeDefinition] = [
        // 🔥 Streak Badges
        BadgeDefinition(key: "first_flame", title: "First Flame", description: "Completed your first green day", iconName: "flame.fill", isEmoji: false, category: .streak, isSecret: false),
        BadgeDefinition(key: "week_warrior", title: "Week Warrior", description: "Maintained a 7-day streak", iconName: "bolt.shield.fill", isEmoji: false, category: .streak, isSecret: false),
        BadgeDefinition(key: "fortnight_fighter", title: "Fortnight Fighter", description: "Maintained a 14-day streak", iconName: "shield.fill", isEmoji: false, category: .streak, isSecret: false),
        BadgeDefinition(key: "month_master", title: "Month Master", description: "Maintained a 30-day streak", iconName: "crown.fill", isEmoji: false, category: .streak, isSecret: false),
        BadgeDefinition(key: "century_keeper", title: "Century Keeper", description: "Maintained a 100-day streak", iconName: "trophy.fill", isEmoji: false, category: .streak, isSecret: false),
        BadgeDefinition(key: "365_club", title: "365 Club", description: "Maintained a 365-day streak", iconName: "star.circle.fill", isEmoji: false, category: .streak, isSecret: false),
        BadgeDefinition(key: "comeback_king", title: "Comeback King", description: "Rebuilt a 7-day streak after a break", iconName: "arrow.triangle.2.circlepath", isEmoji: false, category: .streak, isSecret: false),

        // 🏗 Consistency Badges
        BadgeDefinition(key: "habit_starter", title: "Habit Starter", description: "Created your first daily habit commitment", iconName: "leaf.fill", isEmoji: false, category: .consistency, isSecret: false),
        BadgeDefinition(key: "habit_stack", title: "Habit Stack", description: "3 active habit commitments running simultaneously", iconName: "square.3.layers.3d.down.right", isEmoji: false, category: .consistency, isSecret: false),
        BadgeDefinition(key: "perfect_week", title: "Perfect Week", description: "Completed all scheduled tasks for 7 straight days", iconName: "checkmark.seal.fill", isEmoji: false, category: .consistency, isSecret: false),
        BadgeDefinition(key: "perfect_month", title: "Perfect Month", description: "Completed all scheduled tasks for a full calendar month", iconName: "calendar.badge.checkmark", isEmoji: false, category: .consistency, isSecret: false),
        BadgeDefinition(key: "century_tasks", title: "Century Tasks", description: "Completed 100 total tasks", iconName: "checklist.checked", isEmoji: false, category: .consistency, isSecret: false),
        BadgeDefinition(key: "task_titan", title: "Task Titan", description: "Completed 1,000 total tasks", iconName: "hammer.fill", isEmoji: false, category: .consistency, isSecret: false),

        // 🎯 Goal Badges
        BadgeDefinition(key: "goal_setter", title: "Goal Setter", description: "Created your first target goal", iconName: "target", isEmoji: false, category: .goal, isSecret: false),
        BadgeDefinition(key: "goal_crusher", title: "Goal Crusher", description: "Completed a goal to 100%", iconName: "flag.checkered", isEmoji: false, category: .goal, isSecret: false),
        BadgeDefinition(key: "overachiever", title: "Overachiever", description: "Completed 3 different goals", iconName: "medal.fill", isEmoji: false, category: .goal, isSecret: false),

        // 🏅 Level Badges
        BadgeDefinition(key: "lvl_rising", title: "Rising Star", description: "Reached Level 10", iconName: "sparkles", isEmoji: false, category: .level, isSecret: false),
        BadgeDefinition(key: "lvl_committed", title: "Dedicated Builder", description: "Reached Level 20", iconName: "chart.line.uptrend.xyaxis", isEmoji: false, category: .level, isSecret: false),
        BadgeDefinition(key: "lvl_elite", title: "Elite Master", description: "Reached Level 50", iconName: "seal.fill", isEmoji: false, category: .level, isSecret: false),

        // 🛒 Shop Badges
        BadgeDefinition(key: "first_purchase", title: "First Purchase", description: "Bought an item from the Reward Shop", iconName: "bag.fill", isEmoji: false, category: .shop, isSecret: false),
        BadgeDefinition(key: "self_aware", title: "Self-Aware", description: "Created a custom monthly reward", iconName: "heart.text.square.fill", isEmoji: false, category: .shop, isSecret: false),
        BadgeDefinition(key: "well_stocked", title: "Well-Stocked", description: "Own 2 Streak Freezes at once", iconName: "snow", isEmoji: false, category: .shop, isSecret: false),

        // 💀 Adversity Badges
        BadgeDefinition(key: "phoenix", title: "Phoenix", description: "Rebuilt your level back after an XP drop", iconName: "flame.circle.fill", isEmoji: false, category: .adversity, isSecret: true),
        BadgeDefinition(key: "unbreakable", title: "Unbreakable", description: "Used a Streak Freeze and completed 14 days following", iconName: "shield.checkered", isEmoji: false, category: .adversity, isSecret: true)
    ]
    
    public static func find(byKey key: String) -> BadgeDefinition? {
        allBadges.first(where: { $0.key == key })
    }
}
