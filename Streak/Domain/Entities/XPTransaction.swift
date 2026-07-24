// Domain/Entities/XPTransaction.swift

import Foundation

public enum XPTransactionReason: String, Codable {
    case taskCompleted = "Task Completed"
    case habitCompleted = "Habit Completed"
    case overallGreenDay = "Overall Green Day"
    case categoryGreenDay = "Category Completed"
    case perfectWeekBonus = "Perfect Week Bonus"
    case streakMilestoneBonus = "Streak Milestone Bonus"
    case weeklyTaskCompleted = "Weekly Task Completed"
    case monthlyTaskCompleted = "Monthly Task Completed"
    case backlogTaskCompleted = "To-Do Task Completed"
    
    // Loss / Decay
    case overallRedDayDecay = "Missed Overall Day"
    case categoryRedDayDecay = "Missed Category Day"
    case habitMissedDecay = "Missed Habit"
    case streakBreakPenalty = "Streak Reset Penalty"
    
    // Purchases / Redemption
    case shopPurchase = "Shop Purchase"
    case customRewardRedemption = "Custom Reward Redeemed"
}

public struct XPTransaction: Identifiable, Equatable {
    public let id: UUID
    public let date: Date
    public let amount: Int           // Positive = earn, Negative = spend/decay
    public let reason: XPTransactionReason
    public let note: String?

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Int,
        reason: XPTransactionReason,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.reason = reason
        self.note = note
    }
}
