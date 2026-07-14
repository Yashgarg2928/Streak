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

    init(
        categoryRepository: any CategoryRepository,
        taskRepository: any TaskRepository,
        goalRepository: any GoalRepository,
        dayEntryRepository: any DayEntryRepository,
        reflectionRepository: any ReflectionRepository,
        settingsRepository: any SettingsRepository
    ) {
        self.categoryRepository = categoryRepository
        self.taskRepository = taskRepository
        self.goalRepository = goalRepository
        self.dayEntryRepository = dayEntryRepository
        self.reflectionRepository = reflectionRepository
        self.settingsRepository = settingsRepository
    }

    func syncWidgets() {
        let useCase = SyncWidgetDataUseCase(
            categoryRepository: categoryRepository,
            taskRepository: taskRepository,
            dayEntryRepository: dayEntryRepository,
            goalRepository: goalRepository,
            settingsRepository: settingsRepository
        )
        if let data = useCase.execute() {
            WidgetDataStore.save(data)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
