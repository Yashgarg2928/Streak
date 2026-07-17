// Presentation/Categories/CategoryViewModel.swift

import Foundation

@Observable
final class CategoryViewModel {
    private(set) var category: Category? = nil
    private(set) var streak: Int = 0
    private(set) var entries: [Date: DayStatus] = [:]
    private(set) var linkedGoals: [Goal] = []
    private(set) var taskHistory: [Date: [Task]] = [:]   // date → tasks, sorted newest first
    private(set) var historyDates: [Date] = []            // sorted descending
    private(set) var errorMessage: String? = nil

    private let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    func load(categoryId: UUID) {
        do {
            category = try env.categoryRepository.fetch(id: categoryId)

            let dayEntries = try env.dayEntryRepository.fetchAll(categoryId: categoryId)
            entries = Dictionary(uniqueKeysWithValues: dayEntries.map { ($0.date, $0.status) })

            streak = try CalculateStreakUseCase(dayEntryRepository: env.dayEntryRepository)
                .execute(categoryId: categoryId)

            let syncUseCase = SyncGoalProgressUseCase(
                goalRepository: env.goalRepository,
                dayEntryRepository: env.dayEntryRepository,
                taskRepository: env.taskRepository
            )
            try syncUseCase.execute()

            linkedGoals = try env.goalRepository.fetchAll()
                .filter { $0.categoryId == categoryId }

            // All tasks for this category, grouped by date, past only, newest first
            let allTasks = try env.taskRepository.fetchAll()
                .filter { $0.categoryId == categoryId }
            let today = ActiveDayResolver.resolveActiveDate(for: Date(), settings: env.settingsRepository)
            let pastTasks = allTasks.filter { $0.targetDate <= today }

            var grouped: [Date: [Task]] = [:]
            for task in pastTasks {
                grouped[task.targetDate, default: []].append(task)
            }
            taskHistory = grouped
            historyDates = grouped.keys.sorted(by: >)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func archive() {
        guard let id = category?.id else { return }
        do {
            try env.categoryRepository.archive(id: id)
            
            // Re-resolve today's master status (using the new logic which ignores archived categories)
            let today = ActiveDayResolver.resolveActiveDate(for: Date(), settings: env.settingsRepository)
            let resolver = ResolveDayStatusUseCase(
                taskRepository: env.taskRepository,
                categoryRepository: env.categoryRepository,
                dayEntryRepository: env.dayEntryRepository,
                settingsRepository: env.settingsRepository
            )
            try resolver.execute(date: today, categoryId: nil)
            
            // Recalculate goal values
            let syncGoals = SyncGoalProgressUseCase(
                goalRepository: env.goalRepository,
                dayEntryRepository: env.dayEntryRepository,
                taskRepository: env.taskRepository
            )
            try syncGoals.execute()
            
            env.syncWidgets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
