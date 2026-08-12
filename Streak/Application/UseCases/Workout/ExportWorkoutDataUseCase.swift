// Application/UseCases/Workout/ExportWorkoutDataUseCase.swift

import Foundation

public struct ExportedFitnessData: Codable {
    public let exportDate: Date
    public let startDate: Date
    public let endDate: Date
    public let activeWorkoutPlanTitle: String?
    public let macroGoals: MacroGoals
    public let dailyWorkoutLogs: [DailyWorkoutLog]
    public let dailyMealLogs: [MealLog]

    public init(
        exportDate: Date = Date(),
        startDate: Date,
        endDate: Date,
        activeWorkoutPlanTitle: String?,
        macroGoals: MacroGoals,
        dailyWorkoutLogs: [DailyWorkoutLog],
        dailyMealLogs: [MealLog]
    ) {
        self.exportDate = exportDate
        self.startDate = startDate
        self.endDate = endDate
        self.activeWorkoutPlanTitle = activeWorkoutPlanTitle
        self.macroGoals = macroGoals
        self.dailyWorkoutLogs = dailyWorkoutLogs
        self.dailyMealLogs = dailyMealLogs
    }
}

public struct ExportWorkoutDataUseCase {
    let workoutRepository: any WorkoutRepository
    let nutritionRepository: any NutritionRepository

    public init(
        workoutRepository: any WorkoutRepository,
        nutritionRepository: any NutritionRepository
    ) {
        self.workoutRepository = workoutRepository
        self.nutritionRepository = nutritionRepository
    }

    public func execute(startDate: Date, endDate: Date) throws -> String {
        let plan = try workoutRepository.fetchActivePlan()
        let macroGoals = try nutritionRepository.fetchMacroGoals()
        let workoutLogs = try workoutRepository.fetchLogs(startDate: startDate, endDate: endDate)
        let mealLogs = try nutritionRepository.fetchMealLogs(startDate: startDate, endDate: endDate)

        // Strip photoData bytes for clean export text
        let sanitizedMealLogs = mealLogs.map { meal in
            MealLog(
                id: meal.id,
                date: meal.date,
                mealType: meal.mealType,
                title: meal.title,
                details: meal.details,
                calories: meal.calories,
                proteinGrams: meal.proteinGrams,
                carbGrams: meal.carbGrams,
                fatGrams: meal.fatGrams,
                photoData: nil
            )
        }

        let exported = ExportedFitnessData(
            startDate: startDate,
            endDate: endDate,
            activeWorkoutPlanTitle: plan?.title,
            macroGoals: macroGoals,
            dailyWorkoutLogs: workoutLogs,
            dailyMealLogs: sanitizedMealLogs
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(exported)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
