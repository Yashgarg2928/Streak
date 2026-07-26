// Domain/Repositories/CoreHabitRepository.swift

import Foundation

public protocol CoreHabitRepository {
    func fetchAllActive() throws -> [CoreHabit]
    func fetchAll() throws -> [CoreHabit]
    func save(_ habit: CoreHabit) throws
    func archive(id: UUID) throws
}
