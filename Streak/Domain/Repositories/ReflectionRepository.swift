// Domain/Repositories/ReflectionRepository.swift
// Protocol only — no concrete implementation here

import Foundation

protocol ReflectionRepository {
    func fetch(date: Date) throws -> ReflectionEntry?
    func save(_ entry: ReflectionEntry) throws
    func fetchAll() throws -> [ReflectionEntry]    // for export + log view
}
