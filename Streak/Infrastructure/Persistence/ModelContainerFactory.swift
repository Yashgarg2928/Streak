// Infrastructure/Persistence/ModelContainerFactory.swift
// Creates the SwiftData ModelContainer with all registered models.
// One place to change if we add iCloud sync or new models.

import Foundation
import SwiftData

enum ModelContainerFactory {

    static let schema = Schema([
        CategoryModel.self,
        TaskModel.self,
        DayEntryModel.self,
        GoalModel.self,
        GoalProgressEntryModel.self,
        ReflectionEntryModel.self,
        HabitRoutineModel.self,
        PlayerProfileModel.self,
        BadgeModel.self,
        XPTransactionModel.self,
        ShopItemModel.self,
        CustomRewardModel.self,
        CoreHabitModel.self,
        DailyHabitLogModel.self,
        WorkoutPlanModel.self,
        DailyWorkoutLogModel.self,
        MealLogModel.self,
        MacroGoalsModel.self,
        FinanceTransactionModel.self,
        SplitShareModel.self,
        HealthSnapshotModel.self,
    ])

    /// On-disk location of the SQLite store (used by backup/restore).
    static var storeURL: URL {
        ModelConfiguration(schema: schema, isStoredInMemoryOnly: false).url
    }

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        // ponytail: in-memory config used in tests/previews — no disk I/O
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: config)
    }
}
