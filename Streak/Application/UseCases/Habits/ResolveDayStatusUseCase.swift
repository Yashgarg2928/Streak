// Application/UseCases/Habits/ResolveDayStatusUseCase.swift
// Recomputes and persists a DayEntry for a given (date, categoryId) pair.
// categoryId == nil means master (all tasks across all categories).

import Foundation

struct ResolveDayStatusUseCase {
    let taskRepository: any TaskRepository
    let categoryRepository: any CategoryRepository
    let dayEntryRepository: any DayEntryRepository
    let settingsRepository: any SettingsRepository
    let playerProfileRepository: (any PlayerProfileRepository)?
    let xpTransactionRepository: (any XPTransactionRepository)?

    init(
        taskRepository: any TaskRepository,
        categoryRepository: any CategoryRepository,
        dayEntryRepository: any DayEntryRepository,
        settingsRepository: any SettingsRepository,
        playerProfileRepository: (any PlayerProfileRepository)? = nil,
        xpTransactionRepository: (any XPTransactionRepository)? = nil
    ) {
        self.taskRepository = taskRepository
        self.categoryRepository = categoryRepository
        self.dayEntryRepository = dayEntryRepository
        self.settingsRepository = settingsRepository
        self.playerProfileRepository = playerProfileRepository
        self.xpTransactionRepository = xpTransactionRepository
    }

    func execute(date: Date, categoryId: UUID?) throws {
        let tasks: [Task]

        if let categoryId {
            tasks = try taskRepository.fetchAll(for: date, categoryId: categoryId)
        } else {
            tasks = try taskRepository.fetchAll(for: date)
        }
        
        let activeCategories = try categoryRepository.fetchActive()
        let activeCategoryIds = Set(activeCategories.map { $0.id })
        
        let activeTasks = tasks.filter { task in
            if task.isDeleted { return false }
            if task.timeframe != .daily { return false }
            if let catId = task.categoryId {
                return activeCategoryIds.contains(catId)
            }
            return true
        }
        
        let taskCount = activeTasks.count
        let completedCount = activeTasks.filter { $0.isCompleted }.count
        let now = Date()
        let activeDate = ActiveDayResolver.resolveActiveDate(for: now, settings: settingsRepository)
        let planningDeadline = ActiveDayResolver.planningDeadline(for: date, settings: settingsRepository)
        let isDeadlinePassed = now > planningDeadline

        var status = DayStatus.resolve(
            taskCount: taskCount,
            completedCount: completedCount,
            date: date,
            activeDate: activeDate,
            isPlanningDeadlinePassed: isDeadlinePassed
        )

        if status == .green {
            let hasLateTasks = activeTasks.contains { task in
                if task.routineId != nil { return false }
                return task.createdAt > planningDeadline
            }
            if hasLateTasks {
                status = .red
            }
        }

        let existingEntry = try dayEntryRepository.fetch(date: date, categoryId: categoryId)
        let previousStatus = existingEntry?.status

        let entry = DayEntry(
            date: date,
            categoryId: categoryId,
            status: status,
            taskCount: taskCount,
            completedCount: completedCount
        )
        try dayEntryRepository.save(entry)

        // Deduct XP penalty when a master day resolves to RED for the first time
        if categoryId == nil && status == .red && previousStatus != .red && date <= activeDate {
            let uncompletedCount = taskCount - completedCount
            if uncompletedCount > 0, let pRepo = playerProfileRepository, let txRepo = xpTransactionRepository {
                let deductUseCase = DeductXPUseCase(
                    playerProfileRepository: pRepo,
                    xpTransactionRepository: txRepo
                )
                try? deductUseCase.execute(
                    penaltyAmount: uncompletedCount * 10,
                    reason: .habitMissedDecay,
                    note: "Penalty for \(uncompletedCount) uncompleted task(s)"
                )
            } else if taskCount == 0 && isDeadlinePassed, let pRepo = playerProfileRepository, let txRepo = xpTransactionRepository {
                let deductUseCase = DeductXPUseCase(
                    playerProfileRepository: pRepo,
                    xpTransactionRepository: txRepo
                )
                try? deductUseCase.execute(
                    penaltyAmount: 25,
                    reason: .overallRedDayDecay,
                    note: "Planning cutoff passed with 0 tasks scheduled"
                )
            }
        }
    }
}
