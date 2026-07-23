// Infrastructure/Persistence/ModelContainerFactory.swift
// Creates the SwiftData ModelContainer with all registered models.
// One place to change if we add iCloud sync or new models.

import Foundation
import SwiftData

enum ModelContainerFactory {

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            CategoryModel.self,
            TaskModel.self,
            DayEntryModel.self,
            GoalModel.self,
            GoalProgressEntryModel.self,
            ReflectionEntryModel.self,
            HabitRoutineModel.self,
        ])

        let config: ModelConfiguration
        if inMemory {
            // ponytail: in-memory config used in tests/previews — no disk I/O
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        return try ModelContainer(for: schema, configurations: config)
    }
}
