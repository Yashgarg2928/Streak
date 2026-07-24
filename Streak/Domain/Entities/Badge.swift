// Domain/Entities/Badge.swift

import Foundation

public struct Badge: Identifiable, Equatable {
    public let id: UUID
    public let badgeKey: String
    public let earnedAt: Date

    public var definition: BadgeDefinition? {
        BadgeDefinition.find(byKey: badgeKey)
    }

    public init(
        id: UUID = UUID(),
        badgeKey: String,
        earnedAt: Date = Date()
    ) {
        self.id = id
        self.badgeKey = badgeKey
        self.earnedAt = earnedAt
    }
}
