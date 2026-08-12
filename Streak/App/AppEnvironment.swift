// App/AppEnvironment.swift
// Dependency injection container. All concrete dependencies registered here.
// ViewModels receive AppEnvironment via SwiftUI environment.

import Foundation
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
    let coreHabitRepository: any CoreHabitRepository
    let dailyHabitLogRepository: any DailyHabitLogRepository
    let workoutRepository: any WorkoutRepository
    let nutritionRepository: any NutritionRepository

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
        coreHabitRepository: any CoreHabitRepository,
        dailyHabitLogRepository: any DailyHabitLogRepository,
        workoutRepository: any WorkoutRepository,
        nutritionRepository: any NutritionRepository
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
        self.coreHabitRepository = coreHabitRepository
        self.dailyHabitLogRepository = dailyHabitLogRepository
        self.workoutRepository = workoutRepository
        self.nutritionRepository = nutritionRepository
        self.themeMode = settingsRepository.themeMode
    }

    func syncWidgets() {
        let useCase = SyncWidgetDataUseCase(
            categoryRepository: categoryRepository,
            taskRepository: taskRepository,
            dayEntryRepository: dayEntryRepository,
            goalRepository: goalRepository,
            settingsRepository: settingsRepository,
            habitRoutineRepository: habitRoutineRepository,
            dailyHabitLogRepository: dailyHabitLogRepository
        )
        if let data = useCase.execute() {
            WidgetDataStore.save(data)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
