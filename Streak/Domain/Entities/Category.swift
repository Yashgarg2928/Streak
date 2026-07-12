// Domain/Entities/Category.swift
// Pure Swift — no UIKit, SwiftUI, or SwiftData imports

import Foundation

struct Category: Identifiable, Equatable {
    let id: UUID
    var name: String
    var colorHex: String
    var sortOrder: Int
    var isArchived: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        sortOrder: Int = 0,
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
}
