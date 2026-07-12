// Domain/Repositories/TaskRepository.swift
// Protocol only — no concrete implementation here

import Foundation

protocol TaskRepository {
    func fetchAll(for date: Date) throws -> [Task]
    func fetchAll(for date: Date, categoryId: UUID) throws -> [Task]
    func fetch(id: UUID) throws -> Task?
    func save(_ task: Task) throws
    func delete(id: UUID) throws
    func fetchAll() throws -> [Task]               // for export
}
