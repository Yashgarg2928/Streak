// Domain/Repositories/GoalRepository.swift
// Protocol only — no concrete implementation here

import Foundation

protocol GoalRepository {
    func fetchAll() throws -> [Goal]
    func fetchActive() throws -> [Goal]            // non-completed
    func fetch(id: UUID) throws -> Goal?
    func save(_ goal: Goal) throws
    func delete(id: UUID) throws
    func saveProgressEntry(_ entry: GoalProgressEntry) throws
    func fetchProgressEntries(goalId: UUID) throws -> [GoalProgressEntry]
    func fetchProgressEntry(goalId: UUID, date: Date) throws -> GoalProgressEntry?
}
