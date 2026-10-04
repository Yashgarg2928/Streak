// Domain/Entities/Friend.swift
// Pure Swift — no UIKit, SwiftUI, or SwiftData imports

import Foundation

public struct Friend: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
