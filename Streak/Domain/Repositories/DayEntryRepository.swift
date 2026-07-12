// Domain/Repositories/DayEntryRepository.swift
// Protocol only — no concrete implementation here

import Foundation

protocol DayEntryRepository {
    func fetch(date: Date, categoryId: UUID?) throws -> DayEntry?
    func save(_ entry: DayEntry) throws
    func fetchAll(categoryId: UUID?) throws -> [DayEntry]   // all history, for streak calc + export
}
