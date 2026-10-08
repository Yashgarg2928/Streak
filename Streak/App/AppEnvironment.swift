// App/AppEnvironment.swift
// Dependency injection container. All concrete dependencies registered here.
// ViewModels receive AppEnvironment via SwiftUI environment.

import Foundation
import SwiftData
import WidgetKit

@Observable
final class AppEnvironment {
    let categoryRepository: any CategoryRepository
    let taskRepository: any TaskRepository
    let goalRepository: any GoalRepository
    let dayEntryRepository: any DayEntryRepository
    let reflectionRepository: any ReflectionRepository
    let settingsRepository: any SettingsRepository
    let habitRoutineRepository: any HabitRoutineRepository
    let playerProfileRepository: any PlayerProfileRepository
    let badgeRepository: any BadgeRepository
    let xpTransactionRepository: any XPTransactionRepository
    let shopItemRepository: any ShopItemRepository
    let customRewardRepository: any CustomRewardRepository
    let dailyHabitLogRepository: any DailyHabitLogRepository
    let workoutRepository: any WorkoutRepository
    let nutritionRepository: any NutritionRepository
    let financeRepository: any FinanceRepository
    let healthSnapshotRepository: any HealthSnapshotRepository

    /// Bumped after every data change so screens can refresh (see syncWidgets()).
    private(set) var dataVersion = 0

    var themeMode: String {
        didSet {
            settingsRepository.themeMode = themeMode
            settingsRepository.saveAll()
        }
    }

    init(
        categoryRepository: any CategoryRepository,
        taskRepository: any TaskRepository,
        goalRepository: any GoalRepository,
        dayEntryRepository: any DayEntryRepository,
        reflectionRepository: any ReflectionRepository,
        settingsRepository: any SettingsRepository,
        habitRoutineRepository: any HabitRoutineRepository,
        playerProfileRepository: any PlayerProfileRepository,
        badgeRepository: any BadgeRepository,
        xpTransactionRepository: any XPTransactionRepository,
        shopItemRepository: any ShopItemRepository,
        customRewardRepository: any CustomRewardRepository,
        dailyHabitLogRepository: any DailyHabitLogRepository,
        workoutRepository: any WorkoutRepository,
        nutritionRepository: any NutritionRepository,
        financeRepository: any FinanceRepository,
        healthSnapshotRepository: any HealthSnapshotRepository
    ) {
        self.categoryRepository = categoryRepository
        self.taskRepository = taskRepository
        self.goalRepository = goalRepository
        self.dayEntryRepository = dayEntryRepository
        self.reflectionRepository = reflectionRepository
        self.settingsRepository = settingsRepository
        self.habitRoutineRepository = habitRoutineRepository
        self.playerProfileRepository = playerProfileRepository
        self.badgeRepository = badgeRepository
        self.xpTransactionRepository = xpTransactionRepository
        self.shopItemRepository = shopItemRepository
        self.customRewardRepository = customRewardRepository
        self.dailyHabitLogRepository = dailyHabitLogRepository
        self.workoutRepository = workoutRepository
        self.nutritionRepository = nutritionRepository
        self.financeRepository = financeRepository
        self.healthSnapshotRepository = healthSnapshotRepository
        self.themeMode = settingsRepository.themeMode
    }

    /// The environment of the running app. App Intents (Siri / Shortcuts) reuse it so they
    /// don't open a second copy of the database.
    static var current: AppEnvironment?
    private static var standaloneContainer: ModelContainer?

    static func live(context: ModelContext) -> AppEnvironment {
        AppEnvironment(
            categoryRepository:      SwiftDataCategoryRepository(context: context),
            taskRepository:          SwiftDataTaskRepository(context: context),
            goalRepository:          SwiftDataGoalRepository(context: context),
            dayEntryRepository:      SwiftDataDayEntryRepository(context: context),
            reflectionRepository:    SwiftDataReflectionRepository(context: context),
            settingsRepository:      UserDefaultsSettingsRepository(),
            habitRoutineRepository:  SwiftDataHabitRoutineRepository(context: context),
            playerProfileRepository: SwiftDataPlayerProfileRepository(context: context),
            badgeRepository:         SwiftDataBadgeRepository(context: context),
            xpTransactionRepository: SwiftDataXPTransactionRepository(context: context),
            shopItemRepository:      SwiftDataShopItemRepository(context: context),
            customRewardRepository:  SwiftDataCustomRewardRepository(context: context),
            dailyHabitLogRepository: SwiftDataDailyHabitLogRepository(context: context),
            workoutRepository:       SwiftDataWorkoutRepository(context: context),
            nutritionRepository:     SwiftDataNutritionRepository(context: context),
            financeRepository:       SwiftDataFinanceRepository(context: context),
            healthSnapshotRepository: SwiftDataHealthSnapshotRepository(context: context)
        )
    }

    /// The running app's environment, or a standalone one when an intent runs without the UI.
    static func currentOrStandalone() throws -> AppEnvironment {
        if let current { return current }
        let container = try ModelContainerFactory.makeContainer()
        let env = live(context: container.mainContext)
        standaloneContainer = container
        current = env
        return env
    }

    func syncWidgets() {
        let useCase = SyncWidgetDataUseCase(
            categoryRepository: categoryRepository,
            taskRepository: taskRepository,
            dayEntryRepository: dayEntryRepository,
            goalRepository: goalRepository,
            settingsRepository: settingsRepository,
            habitRoutineRepository: habitRoutineRepository,
            dailyHabitLogRepository: dailyHabitLogRepository,
            financeRepository: financeRepository
        )
        if let data = useCase.execute() {
            WidgetDataStore.save(data)
            WidgetCenter.shared.reloadAllTimelines()
            DayCountdownActivityManager.refresh(with: data, settings: settingsRepository)
        }
        SpicyNotificationScheduler.scheduleRefresh(env: self)
        dataVersion += 1
    }

    /// Ticks or unticks a task through the full flow: day status, XP, badges, goals and widgets.
    func setTaskCompleted(_ taskId: UUID, completed: Bool, syncAfterwards: Bool = true) throws {
        let resolver = ResolveDayStatusUseCase(
            taskRepository: taskRepository,
            categoryRepository: categoryRepository,
            dayEntryRepository: dayEntryRepository,
            settingsRepository: settingsRepository,
            playerProfileRepository: playerProfileRepository,
            xpTransactionRepository: xpTransactionRepository
        )
        try CompleteTaskUseCase(
            taskRepository: taskRepository,
            resolveDayStatus: resolver,
            settingsRepository: settingsRepository,
            playerProfileRepository: playerProfileRepository,
            xpTransactionRepository: xpTransactionRepository,
            badgeRepository: badgeRepository,
            goalRepository: goalRepository,
            habitRoutineRepository: habitRoutineRepository,
            dayEntryRepository: dayEntryRepository
        ).execute(taskId: taskId, completed: completed)

        guard syncAfterwards else { return }
        try SyncGoalProgressUseCase(
            goalRepository: goalRepository,
            dayEntryRepository: dayEntryRepository,
            taskRepository: taskRepository,
            settingsRepository: settingsRepository
        ).execute()
        syncWidgets()
    }
}
