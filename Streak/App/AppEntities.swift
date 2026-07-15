// App/AppEntities.swift
// Registers AppEntity definitions for the main app target so AppIntents can resolve widget selection data.

import Foundation
import AppIntents

// MARK: - Category App Entity

struct CategoryAppEntity: AppEntity {
    let id: String
    let name: String
    let colorHex: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static var defaultQuery = CategoryEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct CategoryEntityQuery: EntityQuery {
    static var cache: [CategoryAppEntity] = []

    func entities(for identifiers: [String]) async throws -> [CategoryAppEntity] {
        let all = allEntities()
        if !all.isEmpty {
            Self.cache = all
        }
        let resolvedAll = all.isEmpty ? Self.cache : all
        guard !identifiers.isEmpty else { return resolvedAll }
        let lowercasedIds = identifiers.map { $0.lowercased() }
        return resolvedAll.filter { lowercasedIds.contains($0.id.lowercased()) }
    }

    func suggestedEntities() async throws -> [CategoryAppEntity] {
        let all = allEntities()
        if !all.isEmpty {
            Self.cache = all
        }
        return all
    }

    func defaultResult() async -> CategoryAppEntity? {
        let all = allEntities()
        if !all.isEmpty {
            Self.cache = all
        }
        return all.first
    }

    private func allEntities() -> [CategoryAppEntity] {
        guard let data = WidgetDataStore.load() else { return [] }
        return data.categories.map {
            CategoryAppEntity(id: $0.id, name: $0.name, colorHex: $0.colorHex)
        }
    }
}

// MARK: - Goal App Entity

struct GoalAppEntity: AppEntity {
    let id: String
    let title: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Goal"
    static var defaultQuery = GoalEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct GoalEntityQuery: EntityQuery {
    static var cache: [GoalAppEntity] = []

    func entities(for identifiers: [String]) async throws -> [GoalAppEntity] {
        let all = allEntities()
        if !all.isEmpty {
            Self.cache = all
        }
        let resolvedAll = all.isEmpty ? Self.cache : all
        guard !identifiers.isEmpty else { return resolvedAll }
        let lowercasedIds = identifiers.map { $0.lowercased() }
        return resolvedAll.filter { lowercasedIds.contains($0.id.lowercased()) }
    }

    func suggestedEntities() async throws -> [GoalAppEntity] {
        let all = allEntities()
        if !all.isEmpty {
            Self.cache = all
        }
        return all
    }

    func defaultResult() async -> GoalAppEntity? {
        let all = allEntities()
        if !all.isEmpty {
            Self.cache = all
        }
        return all.first
    }

    private func allEntities() -> [GoalAppEntity] {
        guard let data = WidgetDataStore.load() else { return [] }
        return data.goals.map {
            GoalAppEntity(id: $0.id, title: $0.title)
        }
    }
}
