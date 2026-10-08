// Presentation/Goals/GoalsViewModel.swift
// ViewModel driving the Goals List and Detail views.

import Foundation
import SwiftUI

@Observable
final class GoalsViewModel {
    private let env: AppEnvironment
    
    var goals: [Goal] = []
    var categories: [Category] = []
    
    // View state
    var isSaving = false
    var errorMessage: String? = nil
    
    init(env: AppEnvironment) {
        self.env = env
    }
    
    func load() {
        loadCategories()
        syncAndLoadGoals()
    }
    
    private func loadCategories() {
        do {
            categories = try env.categoryRepository.fetchActive()
        } catch {
            print("Failed to load active categories: \(error)")
        }
    }
    
    func syncAndLoadGoals() {
        do {
            // Run sync first to make sure auto-progress is accurate
            let syncUseCase = SyncGoalProgressUseCase(
                goalRepository: env.goalRepository,
                dayEntryRepository: env.dayEntryRepository,
                taskRepository: env.taskRepository,
                settingsRepository: env.settingsRepository
            )
            try syncUseCase.execute()
            
            // Fetch all goals
            goals = try env.goalRepository.fetchAll()
        } catch {
            print("Failed to sync/load goals: \(error)")
        }
    }
    
    func createGoal(
        title: String,
        goalType: GoalType,
        categoryId: UUID?,
        targetValue: Double,
        unit: String,
        targetDate: Date?
    ) -> Bool {
        isSaving = true
        errorMessage = nil
        do {
            let syncUseCase = SyncGoalProgressUseCase(
                goalRepository: env.goalRepository,
                dayEntryRepository: env.dayEntryRepository,
                taskRepository: env.taskRepository,
                settingsRepository: env.settingsRepository
            )
            let createUseCase = CreateGoalUseCase(
                goalRepository: env.goalRepository,
                syncGoalProgress: syncUseCase
            )
            try createUseCase.execute(
                title: title,
                goalType: goalType,
                categoryId: categoryId,
                targetValue: targetValue,
                unit: unit,
                targetDate: targetDate
            )
            
            // Reload list and widgets
            load()
            env.syncWidgets()
            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
            return false
        }
    }
}
