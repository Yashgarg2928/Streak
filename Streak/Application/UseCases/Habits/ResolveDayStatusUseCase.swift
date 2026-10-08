// Application/UseCases/Habits/ResolveDayStatusUseCase.swift
// Recomputes and persists a DayEntry for a given (date, categoryId) pair.
// categoryId == nil means master (all tasks across all categories).
//
// Rules:
// - Only *planned* tasks count. Standalone tasks added after the planning deadline
//   are bonus work and never change the day's status.
// - Scheduled rest days resolve to `.rest` unless every task was completed.
// - A `.frozen` day stays frozen unless it later turns green.
// - When `allowAutoFreeze` is set (end-of-day sweep), a missed master day that would
//   break a running streak consumes a Streak Freeze from inventory instead.

import Foundation

struct ResolveDayStatusUseCase {
    let taskRepository: any TaskRepository
    let categoryRepository: any CategoryRepository
    let dayEntryRepository: any DayEntryRepository
    let settingsRepository: any SettingsRepository
    let playerProfileRepository: (any PlayerProfileRepository)?
    let xpTransactionRepository: (any XPTransactionRepository)?
    let shopItemRepository: (any ShopItemRepository)?

    init(
        taskRepository: any TaskRepository,
        categoryRepository: any CategoryRepository,
        dayEntryRepository: any DayEntryRepository,
        settingsRepository: any SettingsRepository,
        playerProfileRepository: (any PlayerProfileRepository)? = nil,
        xpTransactionRepository: (any XPTransactionRepository)? = nil,
        shopItemRepository: (any ShopItemRepository)? = nil
    ) {
        self.taskRepository = taskRepository
        self.categoryRepository = categoryRepository
        self.dayEntryRepository = dayEntryRepository
        self.settingsRepository = settingsRepository
        self.playerProfileRepository = playerProfileRepository
        self.xpTransactionRepository = xpTransactionRepository
        self.shopItemRepository = shopItemRepository
    }

    func execute(date: Date, categoryId: UUID?, allowAutoFreeze: Bool = false) throws {
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

        let now = Date()
        let activeDate = ActiveDayResolver.resolveActiveDate(for: now, settings: settingsRepository)
        let planningDeadline = ActiveDayResolver.planningDeadline(for: date, settings: settingsRepository)
        let isDeadlinePassed = now > planningDeadline

        let plannedTasks = activeTasks.filter { !$0.isAddedLate(planningDeadline: planningDeadline) }
        let taskCount = plannedTasks.count
        let completedCount = plannedTasks.filter { $0.isCompleted }.count

        var status = DayStatus.resolve(
            taskCount: taskCount,
            completedCount: completedCount,
            date: date,
            activeDate: activeDate,
            isPlanningDeadlinePassed: isDeadlinePassed,
            isRestDay: ActiveDayResolver.isRestDay(date, settings: settingsRepository)
        )

        let existingEntry = try dayEntryRepository.fetch(date: date, categoryId: categoryId)
        let previousStatus = existingEntry?.status

        // A protected day stays protected unless it was fully completed after all.
        if previousStatus == .frozen && status != .green {
            status = .frozen
        }

        let isPastDay = Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: activeDate)
        if allowAutoFreeze && categoryId == nil && status == .red && isPastDay,
           try consumeStreakFreezeIfUseful(for: date) {
            status = .frozen
        }

        let entry = DayEntry(
            id: existingEntry?.id ?? UUID(),
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
                _ = try? deductUseCase.execute(
                    penaltyAmount: uncompletedCount * 10,
                    reason: .habitMissedDecay,
                    note: "Penalty for \(uncompletedCount) uncompleted task(s)"
                )
            } else if taskCount == 0 && isDeadlinePassed, let pRepo = playerProfileRepository, let txRepo = xpTransactionRepository {
                let deductUseCase = DeductXPUseCase(
                    playerProfileRepository: pRepo,
                    xpTransactionRepository: txRepo
                )
                _ = try? deductUseCase.execute(
                    penaltyAmount: 25,
                    reason: .overallRedDayDecay,
                    note: "Planning cutoff passed with 0 tasks scheduled"
                )
            }
        }
    }

    /// Spends one Streak Freeze on a missed day if there's a streak worth protecting.
    /// Also protects every category that wasn't green that day.
    private func consumeStreakFreezeIfUseful(for date: Date) throws -> Bool {
        guard let profileRepo = playerProfileRepository else { return false }
        var profile = try profileRepo.fetchProfile()
        guard profile.streakFreezes > 0 else { return false }

        let cal = Calendar.current
        guard let dayBefore = cal.date(byAdding: .day, value: -1, to: date) else { return false }
        let streakBefore = try CalculateStreakUseCase(
            dayEntryRepository: dayEntryRepository,
            settingsRepository: settingsRepository
        ).execute(categoryId: nil, endingAt: dayBefore)
        guard streakBefore > 0 else { return false }

        profile.streakFreezes -= 1
        profile.lastUpdated = Date()
        try profileRepo.saveProfile(profile)

        if let shopRepo = shopItemRepository,
           var item = try shopRepo.fetchActive(type: .streakFreeze).min(by: { $0.purchasedAt < $1.purchasedAt }) {
            item.usedAt = Date()
            try shopRepo.save(item)
        }

        for category in try categoryRepository.fetchActive() {
            let existing = try dayEntryRepository.fetch(date: date, categoryId: category.id)
            guard existing?.status != .green else { continue }
            try dayEntryRepository.save(DayEntry(
                id: existing?.id ?? UUID(),
                date: date,
                categoryId: category.id,
                status: .frozen,
                taskCount: existing?.taskCount ?? 0,
                completedCount: existing?.completedCount ?? 0
            ))
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        try xpTransactionRepository?.save(XPTransaction(
            date: Date(),
            amount: 0,
            reason: .streakFreezeUsed,
            note: "Auto-used to protect your \(streakBefore)-day streak on \(formatter.string(from: date))"
        ))
        return true
    }
}
