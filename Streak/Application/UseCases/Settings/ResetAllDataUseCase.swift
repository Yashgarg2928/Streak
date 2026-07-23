// Application/UseCases/Settings/ResetAllDataUseCase.swift

import Foundation
import SwiftData
import WidgetKit

final class ResetAllDataUseCase {
    private let context: ModelContext
    private let settingsRepository: any SettingsRepository

    init(context: ModelContext, settingsRepository: any SettingsRepository) {
        self.context = context
        self.settingsRepository = settingsRepository
    }

    func execute() throws {
        try context.delete(model: TaskModel.self)
        try context.delete(model: CategoryModel.self)
        try context.delete(model: DayEntryModel.self)
        try context.delete(model: GoalModel.self)
        try context.delete(model: GoalProgressEntryModel.self)
        try context.delete(model: ReflectionEntryModel.self)
        try context.save()

        // Clear shared widget data store & refresh widget timelines
        WidgetDataStore.clearAll()
        WidgetCenter.shared.reloadAllTimelines()

        // Reset settings
        settingsRepository.resetAll()
    }
}
