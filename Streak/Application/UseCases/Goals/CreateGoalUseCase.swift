// Application/UseCases/Goals/CreateGoalUseCase.swift
// Handles goal creation, including title and target validation and initial progress syncing.

import Foundation

struct CreateGoalUseCase {
    let goalRepository: any GoalRepository
    let syncGoalProgress: SyncGoalProgressUseCase

    func execute(
        title: String,
        goalType: GoalType,
        categoryId: UUID?,
        targetValue: Double,
        unit: String,
        targetDate: Date?
    ) throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyTitle
        }
        guard targetValue > 0 else {
            throw ValidationError.invalidTarget
        }

        let goal = Goal(
            title: title,
            goalType: goalType,
            categoryId: categoryId,
            targetValue: targetValue,
            unit: unit,
            targetDate: targetDate
        )
        try goalRepository.save(goal)
        
        // Populate initial values from database metrics
        try syncGoalProgress.execute()
    }
    
    enum ValidationError: LocalizedError {
        case emptyTitle
        case invalidTarget
        
        var errorDescription: String? {
            switch self {
            case .emptyTitle: return "Goal title cannot be empty."
            case .invalidTarget: return "Target value must be greater than zero."
            }
        }
    }
}
