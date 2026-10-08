// Presentation/Home/HomeViewModel.swift

import Foundation

@Observable
final class HomeViewModel {
    private(set) var categories: [Category] = []
    private(set) var masterStreak: Int = 0
    private(set) var masterHighStreak: Int = 0
    private(set) var masterStreakHistory: [StreakRun] = []
    private(set) var masterEntries: [Date: DayStatus] = [:]
    private(set) var categoryStreaks: [UUID: Int] = [:]
    private(set) var categoryHighStreaks: [UUID: Int] = [:]
    private(set) var categoryStreakHistories: [UUID: [StreakRun]] = [:]
    private(set) var categoryEntries: [UUID: [Date: DayStatus]] = [:]

    // Today
    private(set) var today: Date = Calendar.current.startOfDay(for: Date())
    private(set) var todayTasks: [Task] = []
    private(set) var todayStatus: DayStatus = .future
    private(set) var planningDeadline: Date = Date()
    private(set) var isRestDay: Bool = false
    private(set) var streakFreezes: Int = 0

    // Habits (active commitments with their own streaks)
    private(set) var habits: [HabitRoutine] = []
    private(set) var habitProgress: [UUID: HabitProgress] = [:]

    // Goals
    private(set) var activeGoals: [Goal] = []

    // Backup reminder
    private(set) var daysSinceBackup: Int? = nil
    private(set) var needsBackup: Bool = false

    var errorMessage: String? = nil

    private let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    var plannedTasks: [Task] {
        todayTasks.filter { !$0.isAddedLate(planningDeadline: planningDeadline) }
    }

    var plannedDoneCount: Int { plannedTasks.filter(\.isCompleted).count }

    func isBonus(_ task: Task) -> Bool { task.isAddedLate(planningDeadline: planningDeadline) }

    func isHealthLinked(_ task: Task) -> Bool {
        guard let routineId = task.routineId else { return false }
        return habits.first { $0.id == routineId }?.healthRule != nil
    }

    func color(for categoryId: UUID?) -> Category? {
        categoryId.flatMap { id in categories.first { $0.id == id } }
    }

    func load() {
        do {
            let settings = env.settingsRepository
            categories = try env.categoryRepository.fetchActive()

            // Today
            today = Calendar.current.startOfDay(for: ActiveDayResolver.resolveActiveDate(for: Date(), settings: settings))
            planningDeadline = ActiveDayResolver.planningDeadline(for: today, settings: settings)
            isRestDay = ActiveDayResolver.isRestDay(today, settings: settings)
            todayTasks = try env.taskRepository.fetchAll(for: today)
                .filter { !$0.isDeleted && $0.timeframe == .daily }
                .sorted { ($0.sortOrder, $0.createdAt) < ($1.sortOrder, $1.createdAt) }
            todayStatus = try env.dayEntryRepository.fetch(date: today, categoryId: nil)?.status ?? .future
            streakFreezes = (try? env.playerProfileRepository.fetchProfile().streakFreezes) ?? 0

            // Master entries + streak + history
            let masterDayEntries = try env.dayEntryRepository.fetchAll(categoryId: nil)
            masterEntries = Dictionary(masterDayEntries.map { ($0.date, $0.status) }, uniquingKeysWith: { _, last in last })
            masterStreak = try CalculateStreakUseCase(dayEntryRepository: env.dayEntryRepository, settingsRepository: settings)
                .execute(categoryId: nil)
            let masterHistory = try CalculateStreakHistoryUseCase(dayEntryRepository: env.dayEntryRepository)
                .execute(categoryId: nil)
            masterHighStreak    = masterHistory.highStreak
            masterStreakHistory = masterHistory.runs

            // Per-category entries + streaks + histories
            for cat in categories {
                let entries = try env.dayEntryRepository.fetchAll(categoryId: cat.id)
                categoryEntries[cat.id] = Dictionary(entries.map { ($0.date, $0.status) }, uniquingKeysWith: { _, last in last })
                categoryStreaks[cat.id] = try CalculateStreakUseCase(dayEntryRepository: env.dayEntryRepository, settingsRepository: settings)
                    .execute(categoryId: cat.id)
                let catHistory = try CalculateStreakHistoryUseCase(dayEntryRepository: env.dayEntryRepository)
                    .execute(categoryId: cat.id)
                categoryHighStreaks[cat.id]      = catHistory.highStreak
                categoryStreakHistories[cat.id]  = catHistory.runs
            }

            // Habits
            habits = try env.habitRoutineRepository.fetchAll().filter { $0.isInDateRange(today) }
            let habitTasks = try env.taskRepository.fetchAll().filter { $0.routineId != nil && $0.timeframe == .daily }
            let protectedDays = Set(masterDayEntries.filter { $0.status.isStreakNeutral }.map { Calendar.current.startOfDay(for: $0.date) })
            let calculator = CalculateHabitStreakUseCase(settingsRepository: settings)
            habitProgress = Dictionary(uniqueKeysWithValues: habits.map {
                ($0.id, calculator.execute(routine: $0, tasks: habitTasks, protectedDays: protectedDays, recentDays: 7))
            })

            // Goals
            activeGoals = Array(try env.goalRepository.fetchAll().filter { !$0.isCompleted }.prefix(3))

            // Backup reminder: nudge after two weeks, or once there's a few days of history.
            if let last = settings.lastBackupDate {
                let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
                daysSinceBackup = days
                needsBackup = days >= 14
            } else {
                daysSinceBackup = nil
                needsBackup = masterDayEntries.count >= 3
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(_ task: Task) {
        do {
            try env.setTaskCompleted(task.id, completed: !task.isCompleted)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
