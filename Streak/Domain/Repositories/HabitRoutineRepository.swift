// Domain/Repositories/HabitRoutineRepository.swift

import Foundation

protocol HabitRoutineRepository {
    func fetchAll() throws -> [HabitRoutine]
    func fetchActive(for date: Date) throws -> [HabitRoutine]
    func fetch(id: UUID) throws -> HabitRoutine?
    func save(_ routine: HabitRoutine) throws
    func delete(id: UUID) throws
}
