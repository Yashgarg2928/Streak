// Domain/Entities/CoreHabit.swift

import Foundation

public struct CoreHabit: Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var categoryId: UUID?
    public var isArchived: Bool
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        categoryId: UUID? = nil,
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.categoryId = categoryId
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
}
