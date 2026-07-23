// Presentation/Tasks/TaskViewModel.swift

import Foundation
import SwiftUI

enum TaskTab: String, CaseIterable, Identifiable {
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case backlog = "TO-DO LIST"

    var id: String { rawValue }
}

@Observable
final class TaskViewModel {
    private(set) var tasks: [Task] = []
    private(set) var categories: [Category] = []
    private(set) var errorMessage: String? = nil

    private let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    func load(tab: TaskTab = .daily, for date: Date = Date()) {
        do {
            categories = try env.categoryRepository.fetchActive()
            let fetched: [Task]
            switch tab {
            case .daily:
                fetched = try env.taskRepository.fetchAll(for: date).filter { $0.timeframe == .daily }
            case .weekly:
                fetched = try env.taskRepository.fetch(timeframe: .weekly)
            case .monthly:
                fetched = try env.taskRepository.fetch(timeframe: .monthly)
            case .backlog:
                fetched = try env.taskRepository.fetch(timeframe: .backlog)
            }
            
            tasks = fetched.sorted { t1, t2 in
                if t1.isDeleted != t2.isDeleted {
                    return !t1.isDeleted && t2.isDeleted
                }
                return !t1.isCompleted && t2.isCompleted
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addTask(title: String, categoryId: UUID?, timeframe: TaskTimeframe = .daily, for date: Date = Date()) {
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
            _ = try useCase.execute(title: title, categoryId: categoryId, targetDate: date, timeframe: timeframe)
            
            let syncGoals = SyncGoalProgressUseCase(
                goalRepository: env.goalRepository,
                dayEntryRepository: env.dayEntryRepository,
                taskRepository: env.taskRepository
            )
            try syncGoals.execute()
            
            env.syncWidgets()
            
            let tab: TaskTab
            switch timeframe {
            case .daily: tab = .daily
            case .weekly: tab = .weekly
            case .monthly: tab = .monthly
            case .backlog: tab = .backlog
            }
            load(tab: tab, for: date)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(taskId: UUID, tab: TaskTab = .daily, for date: Date = Date()) {
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
            load(tab: tab, for: date)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(taskId: UUID, tab: TaskTab = .daily, for date: Date = Date()) {
        do {
            guard let task = try env.taskRepository.fetch(id: taskId) else { return }
            if task.isDeleted {
                try env.taskRepository.deletePermanently(id: taskId)
            } else {
                try env.taskRepository.delete(id: taskId)
            }
            
            if task.timeframe == .daily {
                let resolver = ResolveDayStatusUseCase(
                    taskRepository: env.taskRepository,
                    categoryRepository: env.categoryRepository,
                    dayEntryRepository: env.dayEntryRepository,
                    settingsRepository: env.settingsRepository
                )
                try resolver.execute(date: task.targetDate, categoryId: task.categoryId)
                try resolver.execute(date: task.targetDate, categoryId: nil)
            }
            
            let syncGoals = SyncGoalProgressUseCase(
                goalRepository: env.goalRepository,
                dayEntryRepository: env.dayEntryRepository,
                taskRepository: env.taskRepository
            )
            try syncGoals.execute()
            
            env.syncWidgets()
            load(tab: tab, for: date)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func scheduleTask(taskId: UUID, to targetDate: Date, timeframe: TaskTimeframe, tab: TaskTab = .daily, for date: Date = Date()) {
        do {
            guard var task = try env.taskRepository.fetch(id: taskId) else { return }
            let oldDate = task.targetDate
            let oldCategory = task.categoryId
            let oldTimeframe = task.timeframe
            
            task.timeframe = timeframe
            task.targetDate = Calendar.current.startOfDay(for: targetDate)
            try env.taskRepository.save(task)
            
            let resolver = ResolveDayStatusUseCase(
                taskRepository: env.taskRepository,
                categoryRepository: env.categoryRepository,
                dayEntryRepository: env.dayEntryRepository,
                settingsRepository: env.settingsRepository
            )
            if timeframe == .daily {
                try resolver.execute(date: task.targetDate, categoryId: task.categoryId)
                try resolver.execute(date: task.targetDate, categoryId: nil)
            }
            if oldTimeframe == .daily {
                try resolver.execute(date: oldDate, categoryId: oldCategory)
                try resolver.execute(date: oldDate, categoryId: nil)
            }
            
            let syncGoals = SyncGoalProgressUseCase(
                goalRepository: env.goalRepository,
                dayEntryRepository: env.dayEntryRepository,
                taskRepository: env.taskRepository
            )
            try syncGoals.execute()
            
            env.syncWidgets()
            load(tab: tab, for: date)
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
