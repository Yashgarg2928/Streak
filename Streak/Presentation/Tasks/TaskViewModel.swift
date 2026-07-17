// Presentation/Tasks/TaskViewModel.swift

import Foundation
import SwiftUI

@Observable
final class TaskViewModel {
    private(set) var tasks: [Task] = []
    private(set) var categories: [Category] = []
    private(set) var errorMessage: String? = nil

    private let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    func load(for date: Date = Date()) {
        do {
            tasks = try env.taskRepository.fetchAll(for: date)
                .sorted { t1, t2 in
                    if t1.isDeleted != t2.isDeleted {
                        return !t1.isDeleted && t2.isDeleted
                    }
                    return !t1.isCompleted && t2.isCompleted
                }
            categories = try env.categoryRepository.fetchActive()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addTask(title: String, categoryId: UUID?, for date: Date = Date()) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            let resolver = ResolveDayStatusUseCase(
                taskRepository: env.taskRepository,
                categoryRepository: env.categoryRepository,
                dayEntryRepository: env.dayEntryRepository,
                settingsRepository: env.settingsRepository
            )
            let useCase = AddTaskUseCase(
                taskRepository: env.taskRepository,
                categoryRepository: env.categoryRepository,
                resolveDayStatus: resolver,
                settingsRepository: env.settingsRepository
            )
            _ = try useCase.execute(title: title, categoryId: categoryId, targetDate: date)
            
            let syncGoals = SyncGoalProgressUseCase(
                goalRepository: env.goalRepository,
                dayEntryRepository: env.dayEntryRepository,
                taskRepository: env.taskRepository
            )
            try syncGoals.execute()
            
            env.syncWidgets()
            load(for: date)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(taskId: UUID, for date: Date = Date()) {
        do {
            guard let task = tasks.first(where: { $0.id == taskId }) else { return }
            let resolver = ResolveDayStatusUseCase(
                taskRepository: env.taskRepository,
                categoryRepository: env.categoryRepository,
                dayEntryRepository: env.dayEntryRepository,
                settingsRepository: env.settingsRepository
            )
            let useCase = CompleteTaskUseCase(
                taskRepository: env.taskRepository,
                resolveDayStatus: resolver,
                settingsRepository: env.settingsRepository
            )
            try useCase.execute(taskId: taskId, completed: !task.isCompleted)
            
            let syncGoals = SyncGoalProgressUseCase(
                goalRepository: env.goalRepository,
                dayEntryRepository: env.dayEntryRepository,
                taskRepository: env.taskRepository
            )
            try syncGoals.execute()
            
            env.syncWidgets()
            load(for: date)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(taskId: UUID, for date: Date = Date()) {
        do {
            guard let task = try env.taskRepository.fetch(id: taskId) else { return }
            if task.isDeleted {
                try env.taskRepository.deletePermanently(id: taskId)
            } else {
                try env.taskRepository.delete(id: taskId)
            }
            
            let resolver = ResolveDayStatusUseCase(
                taskRepository: env.taskRepository,
                categoryRepository: env.categoryRepository,
                dayEntryRepository: env.dayEntryRepository,
                settingsRepository: env.settingsRepository
            )
            try resolver.execute(date: task.targetDate, categoryId: task.categoryId)
            try resolver.execute(date: task.targetDate, categoryId: nil)
            
            let syncGoals = SyncGoalProgressUseCase(
                goalRepository: env.goalRepository,
                dayEntryRepository: env.dayEntryRepository,
                taskRepository: env.taskRepository
            )
            try syncGoals.execute()
            
            env.syncWidgets()
            load(for: date)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func color(for task: Task) -> Color? {
        guard let catId = task.categoryId,
              let cat = categories.first(where: { $0.id == catId }) else { return nil }
        return cat.color
    }
}
