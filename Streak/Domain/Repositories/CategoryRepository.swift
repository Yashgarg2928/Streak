// Domain/Repositories/CategoryRepository.swift
// Protocol only — no concrete implementation here

import Foundation

protocol CategoryRepository {
    func fetchAll() throws -> [Category]
    func fetchActive() throws -> [Category]        // non-archived, sorted by sortOrder
    func fetch(id: UUID) throws -> Category?
    func save(_ category: Category) throws
    func delete(id: UUID) throws                   // hard delete — internal use only
    func archive(id: UUID) throws
    func maxSortOrder() throws -> Int
}
