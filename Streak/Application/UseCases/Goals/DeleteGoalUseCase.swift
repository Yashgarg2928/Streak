// Application/UseCases/Goals/DeleteGoalUseCase.swift
// Standard deletion use case for Goal profiles.

import Foundation

struct DeleteGoalUseCase {
    let goalRepository: any GoalRepository

    func execute(id: UUID) throws {
        try goalRepository.delete(id: id)
    }
}
