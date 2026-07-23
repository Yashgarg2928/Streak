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
    private(set) var routines: [HabitRoutine] = []
    private(set) var categories: [Category] = []
    private(set) var errorMessage: String? = nil

    private let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    func load(tab: TaskTab = .daily, for date: Date = Date()) {
        do {
            categories = try env.categoryRepository.fetchActive()
            routines = try env.habitRoutineRepository.fetchAll()
            
            let fetched: [Task]
            switch tab {
            case .daily:
                let generator = GenerateRoutineTasksUseCase(
                    habitRoutineRepository: env.habitRoutineRepository,
                    taskRepository: env.taskRepository
                )
                _ = try generator.execute(for: date)
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

    func addHabitRoutine(
        title: String,
        categoryId: UUID?,
        type: HabitRoutineType,
        startDate: Date = Date(),
        endDate: Date = Date(),
        for currentDate: Date = Date()
    ) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            let cal = Calendar.current
            let start: Date
            let end: Date
            let isLocked: Bool
            
            switch type {
            case .monthlyFixed:
                // Full current month range
                let comps = cal.dateComponents([.year, .month], from: currentDate)
                start = cal.date(from: comps) ?? currentDate
                let range = cal.range(of: .day, in: .month, for: currentDate)?.count ?? 30
                end = cal.date(byAdding: .day, value: range - 1, to: start) ?? currentDate
                isLocked = true
            case .customRange:
                start = cal.startOfDay(for: startDate)
                end = cal.startOfDay(for: endDate)
                isLocked = false
            }
            
            let routine = HabitRoutine(
                title: title,
                categoryId: categoryId,
                type: type,
                startDate: start,
                endDate: end,
                isLocked: isLocked
            )
            try env.habitRoutineRepository.save(routine)
            
            // Auto-generate daily task for current active date
            let generator = GenerateRoutineTasksUseCase(
                habitRoutineRepository: env.habitRoutineRepository,
                taskRepository: env.taskRepository
            )
            _ = try generator.execute(for: currentDate)
            
            load(tab: .daily, for: currentDate)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteHabitRoutine(id: UUID, for date: Date = Date()) {
        do {
            guard let routine = try env.habitRoutineRepository.fetch(id: id) else { return }
            if routine.isLocked {
                errorMessage = "Locked monthly commitments cannot be deleted."
                return
            }
            try env.habitRoutineRepository.delete(id: id)
            load(tab: .daily, for: date)
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
        errorMessage = "⚠️ Tasks cannot be deleted or edited once created."
    }

    func scheduleTask(taskId: UUID, to targetDate: Date, timeframe: TaskTimeframe, tab: TaskTab = .daily, for date: Date = Date()) {
        errorMessage = "⚠️ Tasks cannot be edited or rescheduled once created."
    }

    /// Creates a new daily task from a backlog/weekly/monthly item for today or tomorrow.
    /// Does NOT modify the original task — the original remains in the backlog.
    func promoteToDaily(taskId: UUID, targetDate: Date, currentTab: TaskTab, for date: Date = Date()) {
        do {
            guard let original = tasks.first(where: { $0.id == taskId }) else { return }
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
            _ = try useCase.execute(
                title: original.title,
                categoryId: original.categoryId,
                targetDate: targetDate,
                timeframe: .daily
            )
            
            let syncGoals = SyncGoalProgressUseCase(
                goalRepository: env.goalRepository,
                dayEntryRepository: env.dayEntryRepository,
                taskRepository: env.taskRepository
            )
            try syncGoals.execute()
            
            env.syncWidgets()
            load(tab: currentTab, for: date)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func color(for task: Task) -> Color? {
        guard let catId = task.categoryId,
              let cat = categories.first(where: { $0.id == catId }) else { return nil }
        return cat.color
    }

    func color(for routine: HabitRoutine) -> Color? {
        guard let catId = routine.categoryId,
              let cat = categories.first(where: { $0.id == catId }) else { return nil }
        return cat.color
    }
}
