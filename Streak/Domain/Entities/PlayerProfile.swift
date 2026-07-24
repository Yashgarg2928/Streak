// Domain/Entities/PlayerProfile.swift

import Foundation

public struct PlayerProfile: Identifiable, Equatable {
    public let id: UUID
    public var totalXP: Int
    public var streakFreezes: Int
    public var activeBoostExpiry: Date?
    public var lastUpdated: Date

    public var currentLevel: Int {
        PlayerLevelResolver.level(for: totalXP)
    }

    public var currentTitle: PlayerTitle {
        PlayerTitle.title(for: currentLevel)
    }

    public init(
        id: UUID = UUID(),
        totalXP: Int = 0,
        streakFreezes: Int = 0,
        activeBoostExpiry: Date? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.totalXP = max(0, totalXP)
        self.streakFreezes = min(2, max(0, streakFreezes))
        self.activeBoostExpiry = activeBoostExpiry
        self.lastUpdated = lastUpdated
    }
}
