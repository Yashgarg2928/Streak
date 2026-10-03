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
    private(set) var pastIncompleteTasks: [Task] = []
    private(set) var errorMessage: String? = nil
    private(set) var lateTaskWarningMessage: String? = nil
    private var lateTaskDismissTask: Swift.Task<Void, Never>? = nil

    func triggerLateTaskWarning(message: String) {
        lateTaskDismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.3)) {
            lateTaskWarningMessage = message
        }

        lateTaskDismissTask = Swift.Task { @MainActor in
            try? await Swift.Task.sleep(nanoseconds: 5_000_000_000)
            if !Swift.Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.lateTaskWarningMessage = nil
                }
            }
        }
    }

    func dismissLateTaskWarning() {
        lateTaskDismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            lateTaskWarningMessage = nil
        }
    }

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
                if t1.sortOrder != t2.sortOrder {
                    return t1.sortOrder < t2.sortOrder
                }
                return t1.createdAt < t2.createdAt
            }

            let activeToday = env.settingsRepository.isOnboardingCompleted
                ? ActiveDayResolver.resolveActiveDate(for: Date(), settings: env.settingsRepository)
                : Calendar.current.startOfDay(for: Date())
            pastIncompleteTasks = (try? env.taskRepository.fetchIncompletePastDailyTasks(before: activeToday)) ?? []
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

            if timeframe == .daily {
                let deadline = ActiveDayResolver.planningDeadline(for: date, settings: env.settingsRepository)
                if Date() > deadline {
                    let cutoffStr = ActiveDayResolver.formattedPlanningDeadline(settings: env.settingsRepository)
                    triggerLateTaskWarning(message: "Tasks added after the planning cutoff (\(cutoffStr)) are marked [ADDED LATE] and cannot turn today GREEN.")
                }
            }
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
                settingsRepository: env.settingsRepository,
                playerProfileRepository: env.playerProfileRepository,
                xpTransactionRepository: env.xpTransactionRepository
            )
            let useCase = CompleteTaskUseCase(
                taskRepository: env.taskRepository,
                resolveDayStatus: resolver,
                settingsRepository: env.settingsRepository,
                playerProfileRepository: env.playerProfileRepository,
                xpTransactionRepository: env.xpTransactionRepository,
                badgeRepository: env.badgeRepository,
                goalRepository: env.goalRepository,
                habitRoutineRepository: env.habitRoutineRepository,
                dayEntryRepository: env.dayEntryRepository
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
        if tab == .backlog {
            do {
                try env.taskRepository.deletePermanently(id: taskId)
                load(tab: .backlog, for: date)
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            errorMessage = "⚠️ Daily/Weekly/Monthly tasks cannot be deleted or edited once created."
        }
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

    // MARK: - Move Daily/Past Task to To-Do List (Backlog)

    func moveToBacklog(taskId: UUID, currentTab: TaskTab, for date: Date = Date()) {
        do {
            guard var task = try env.taskRepository.fetch(id: taskId) else { return }
            if task.isLocked {
                errorMessage = "Locked monthly commitments cannot be moved."
                return
            }
            let oldTargetDate = task.targetDate
            let oldTimeframe = task.timeframe

            let maxBacklogOrder = (try? env.taskRepository.maxSortOrder(for: date, timeframe: .backlog)) ?? -1
            task.timeframe = .backlog
            task.sortOrder = maxBacklogOrder + 1
            try env.taskRepository.save(task)

            if oldTimeframe == .daily {
                let resolver = ResolveDayStatusUseCase(
                    taskRepository: env.taskRepository,
                    categoryRepository: env.categoryRepository,
                    dayEntryRepository: env.dayEntryRepository,
                    settingsRepository: env.settingsRepository,
                    playerProfileRepository: env.playerProfileRepository,
                    xpTransactionRepository: env.xpTransactionRepository
                )
                try resolver.execute(date: oldTargetDate, categoryId: task.categoryId)
                try resolver.execute(date: oldTargetDate, categoryId: nil)
            }

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

    // MARK: - Past Tasks Actions

    /// Marks a past task as completed on its original targetDate without affecting current day's checklist
    func completePastTask(taskId: UUID, currentTab: TaskTab, for date: Date = Date()) {
        do {
            guard let task = try env.taskRepository.fetch(id: taskId) else { return }
            let resolver = ResolveDayStatusUseCase(
                taskRepository: env.taskRepository,
                categoryRepository: env.categoryRepository,
                dayEntryRepository: env.dayEntryRepository,
                settingsRepository: env.settingsRepository,
                playerProfileRepository: env.playerProfileRepository,
                xpTransactionRepository: env.xpTransactionRepository
            )
            let useCase = CompleteTaskUseCase(
                taskRepository: env.taskRepository,
                resolveDayStatus: resolver,
                settingsRepository: env.settingsRepository,
                playerProfileRepository: env.playerProfileRepository,
                xpTransactionRepository: env.xpTransactionRepository,
                badgeRepository: env.badgeRepository,
                goalRepository: env.goalRepository,
                habitRoutineRepository: env.habitRoutineRepository,
                dayEntryRepository: env.dayEntryRepository
            )
            try useCase.execute(taskId: taskId, completed: true)

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

    /// Moves a past task to the user's active Today list
    func movePastTaskToToday(taskId: UUID, currentTab: TaskTab, for date: Date = Date()) {
        do {
            guard var task = try env.taskRepository.fetch(id: taskId) else { return }
            let activeToday = env.settingsRepository.isOnboardingCompleted
                ? ActiveDayResolver.resolveActiveDate(for: Date(), settings: env.settingsRepository)
                : Calendar.current.startOfDay(for: Date())

            let oldTargetDate = task.targetDate
            let oldTimeframe = task.timeframe

            let maxDailyOrder = (try? env.taskRepository.maxSortOrder(for: activeToday, timeframe: .daily)) ?? -1
            task.targetDate = activeToday
            task.timeframe = .daily
            task.sortOrder = maxDailyOrder + 1
            try env.taskRepository.save(task)

            let resolver = ResolveDayStatusUseCase(
                taskRepository: env.taskRepository,
                categoryRepository: env.categoryRepository,
                dayEntryRepository: env.dayEntryRepository,
                settingsRepository: env.settingsRepository,
                playerProfileRepository: env.playerProfileRepository,
                xpTransactionRepository: env.xpTransactionRepository
            )
            if oldTimeframe == .daily {
                try resolver.execute(date: oldTargetDate, categoryId: task.categoryId)
                try resolver.execute(date: oldTargetDate, categoryId: nil)
            }
            try resolver.execute(date: activeToday, categoryId: task.categoryId)
            try resolver.execute(date: activeToday, categoryId: nil)

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

    // MARK: - Batch Multi-Task Operations

    func batchCompletePastTasks(taskIds: Set<UUID>, currentTab: TaskTab, for date: Date = Date()) {
        guard !taskIds.isEmpty else { return }
        do {
            let resolver = ResolveDayStatusUseCase(
                taskRepository: env.taskRepository,
                categoryRepository: env.categoryRepository,
                dayEntryRepository: env.dayEntryRepository,
                settingsRepository: env.settingsRepository,
                playerProfileRepository: env.playerProfileRepository,
                xpTransactionRepository: env.xpTransactionRepository
            )
            let useCase = CompleteTaskUseCase(
                taskRepository: env.taskRepository,
                resolveDayStatus: resolver,
                settingsRepository: env.settingsRepository,
                playerProfileRepository: env.playerProfileRepository,
                xpTransactionRepository: env.xpTransactionRepository,
                badgeRepository: env.badgeRepository,
                goalRepository: env.goalRepository,
                habitRoutineRepository: env.habitRoutineRepository,
                dayEntryRepository: env.dayEntryRepository
            )
            for id in taskIds {
                try useCase.execute(taskId: id, completed: true)
            }
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

    func batchMovePastTasksToBacklog(taskIds: Set<UUID>, currentTab: TaskTab, for date: Date = Date()) {
        guard !taskIds.isEmpty else { return }
        do {
            var affectedDates = Set<Date>()
            var maxBacklogOrder = (try? env.taskRepository.maxSortOrder(for: date, timeframe: .backlog)) ?? -1

            for id in taskIds {
                guard var task = try env.taskRepository.fetch(id: id) else { continue }
                if task.isLocked { continue }
                if task.timeframe == .daily {
                    affectedDates.insert(task.targetDate)
                }
                maxBacklogOrder += 1
                task.timeframe = .backlog
                task.sortOrder = maxBacklogOrder
                try env.taskRepository.save(task)
            }

            let resolver = ResolveDayStatusUseCase(
                taskRepository: env.taskRepository,
                categoryRepository: env.categoryRepository,
                dayEntryRepository: env.dayEntryRepository,
                settingsRepository: env.settingsRepository,
                playerProfileRepository: env.playerProfileRepository,
                xpTransactionRepository: env.xpTransactionRepository
            )
            for d in affectedDates {
                try resolver.execute(date: d, categoryId: nil)
            }

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

    func batchMovePastTasksToToday(taskIds: Set<UUID>, currentTab: TaskTab, for date: Date = Date()) {
        guard !taskIds.isEmpty else { return }
        do {
            let activeToday = env.settingsRepository.isOnboardingCompleted
                ? ActiveDayResolver.resolveActiveDate(for: Date(), settings: env.settingsRepository)
                : Calendar.current.startOfDay(for: Date())

            var affectedDates = Set<Date>()
            var maxDailyOrder = (try? env.taskRepository.maxSortOrder(for: activeToday, timeframe: .daily)) ?? -1

            for id in taskIds {
                guard var task = try env.taskRepository.fetch(id: id) else { continue }
                if task.isLocked { continue }
                if task.timeframe == .daily {
                    affectedDates.insert(task.targetDate)
                }
                maxDailyOrder += 1
                task.targetDate = activeToday
                task.timeframe = .daily
                task.sortOrder = maxDailyOrder
                try env.taskRepository.save(task)
            }

            let resolver = ResolveDayStatusUseCase(
                taskRepository: env.taskRepository,
                categoryRepository: env.categoryRepository,
                dayEntryRepository: env.dayEntryRepository,
                settingsRepository: env.settingsRepository,
                playerProfileRepository: env.playerProfileRepository,
                xpTransactionRepository: env.xpTransactionRepository
            )
            for d in affectedDates {
                try resolver.execute(date: d, categoryId: nil)
            }
            try resolver.execute(date: activeToday, categoryId: nil)

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

    // MARK: - Reordering

    enum MoveDirection {
        case up
        case down
        case toTop
        case toBottom
    }

    func moveTask(fromOffsets source: IndexSet, toOffset destination: Int, tab: TaskTab, for date: Date = Date()) {
        tasks.move(fromOffsets: source, toOffset: destination)
        let taskIds = tasks.map { $0.id }
        do {
            try env.taskRepository.updateOrder(taskIds: taskIds)
            for (idx, id) in taskIds.enumerated() {
                if let i = tasks.firstIndex(where: { $0.id == id }) {
                    tasks[i].sortOrder = idx
                }
            }
            env.syncWidgets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveTask(taskId: UUID, direction: MoveDirection, tab: TaskTab, for date: Date = Date()) {
        guard let currentIndex = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        let newIndex: Int
        switch direction {
        case .up:
            newIndex = max(0, currentIndex - 1)
        case .down:
            newIndex = min(tasks.count - 1, currentIndex + 1)
        case .toTop:
            newIndex = 0
        case .toBottom:
            newIndex = tasks.count - 1
        }
        guard newIndex != currentIndex else { return }

        let task = tasks.remove(at: currentIndex)
        tasks.insert(task, at: newIndex)

        let taskIds = tasks.map { $0.id }
        do {
            try env.taskRepository.updateOrder(taskIds: taskIds)
            for (idx, id) in taskIds.enumerated() {
                if let i = tasks.firstIndex(where: { $0.id == id }) {
                    tasks[i].sortOrder = idx
                }
            }
            env.syncWidgets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
