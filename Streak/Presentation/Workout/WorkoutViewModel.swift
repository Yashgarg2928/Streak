// Presentation/Workout/WorkoutViewModel.swift

import Foundation
import SwiftUI

@Observable
final class WorkoutViewModel {
    private(set) var selectedDate: Date = Date()
    private(set) var activePlan: WorkoutPlan? = nil
    private(set) var dailyWorkoutLog: DailyWorkoutLog = DailyWorkoutLog(date: Date())
    private(set) var dailyMealLogs: [MealLog] = []
    private(set) var macroGoals: MacroGoals = MacroGoals()

    private(set) var historicalWorkoutLogs: [DailyWorkoutLog] = []
    private(set) var historicalMealLogs: [MealLog] = []

    var errorMessage: String? = nil
    var successMessage: String? = nil

    private let env: AppEnvironment
    private var workoutRepo: any WorkoutRepository
    private var nutritionRepo: any NutritionRepository

    init(env: AppEnvironment) {
        self.env = env
        self.workoutRepo = env.workoutRepository
        self.nutritionRepo = env.nutritionRepository
    }

    func load(date: Date = Date()) {
        self.selectedDate = Calendar.current.startOfDay(for: date)
        do {
            activePlan = try workoutRepo.fetchActivePlan()
            macroGoals = try nutritionRepo.fetchMacroGoals()
            dailyMealLogs = try nutritionRepo.fetchMealLogs(for: selectedDate)

            let startOf30Days = Calendar.current.date(byAdding: .day, value: -30, to: selectedDate) ?? selectedDate
            historicalWorkoutLogs = try workoutRepo.fetchLogs(startDate: startOf30Days, endDate: selectedDate)
            historicalMealLogs = try nutritionRepo.fetchMealLogs(startDate: startOf30Days, endDate: selectedDate)

            // Fetch or auto-populate daily workout log from active plan
            if let existingLog = try workoutRepo.fetchDailyLog(date: selectedDate) {
                dailyWorkoutLog = existingLog
            } else {
                dailyWorkoutLog = createDailyLogFromPlan(for: selectedDate)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createDailyLogFromPlan(for date: Date) -> DailyWorkoutLog {
        let cal = Calendar.current
        let dayOfWeek = cal.component(.weekday, from: date)
        let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let currentDayName = dayNames[max(0, min(6, dayOfWeek - 1))]

        var initialExercises: [ExerciseLog] = []

        if let plan = activePlan,
           let dayPlan = plan.days.first(where: { $0.dayOfWeek == dayOfWeek || $0.dayName.lowercased() == currentDayName.lowercased() }) {
            initialExercises = dayPlan.exercises.map { exPlan in
                let defaultSets = (1...max(1, exPlan.targetSets)).map { setNum in
                    WorkoutSetLog(setNumber: setNum, weight: 0.0, reps: 10, isCompleted: false)
                }
                return ExerciseLog(
                    exerciseName: exPlan.name,
                    category: exPlan.category,
                    sets: defaultSets,
                    stepCount: exPlan.category.lowercased().contains("cardio") || exPlan.name.lowercased().contains("walk") ? 0 : nil,
                    youtubeUrl: exPlan.youtubeUrl,
                    notes: exPlan.notes
                )
            }
        }

        let newLog = DailyWorkoutLog(date: date, dayName: currentDayName, exercises: initialExercises, notes: nil)
        try? workoutRepo.saveDailyLog(newLog)
        return newLog
    }

    // MARK: - Workout Actions

    func addSet(to exerciseId: UUID) {
        guard let exIndex = dailyWorkoutLog.exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        var exercise = dailyWorkoutLog.exercises[exIndex]
        let lastSet = exercise.sets.last
        let newSetNumber = exercise.sets.count + 1
        let newSet = WorkoutSetLog(
            setNumber: newSetNumber,
            weight: lastSet?.weight ?? 0.0,
            reps: lastSet?.reps ?? 10,
            isCompleted: false
        )
        exercise.sets.append(newSet)
        dailyWorkoutLog.exercises[exIndex] = exercise
        persistDailyLog()
    }

    func removeSet(from exerciseId: UUID) {
        guard let exIndex = dailyWorkoutLog.exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        var exercise = dailyWorkoutLog.exercises[exIndex]
        guard !exercise.sets.isEmpty else { return }
        exercise.sets.removeLast()
        dailyWorkoutLog.exercises[exIndex] = exercise
        persistDailyLog()
    }

    func updateSet(exerciseId: UUID, setIndex: Int, weight: Double? = nil, reps: Int? = nil, isCompleted: Bool? = nil) {
        guard let exIndex = dailyWorkoutLog.exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        var exercise = dailyWorkoutLog.exercises[exIndex]
        guard setIndex >= 0 && setIndex < exercise.sets.count else { return }

        if let weight { exercise.sets[setIndex].weight = weight }
        if let reps { exercise.sets[setIndex].reps = reps }
        if let isCompleted { exercise.sets[setIndex].isCompleted = isCompleted }

        dailyWorkoutLog.exercises[exIndex] = exercise
        persistDailyLog()
    }

    func updateStepCount(exerciseId: UUID, steps: Int) {
        guard let exIndex = dailyWorkoutLog.exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        dailyWorkoutLog.exercises[exIndex].stepCount = steps
        persistDailyLog()
    }

    func addCustomExercise(name: String, category: String = "General") {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newSets = [
            WorkoutSetLog(setNumber: 1, weight: 0.0, reps: 10, isCompleted: false),
            WorkoutSetLog(setNumber: 2, weight: 0.0, reps: 10, isCompleted: false),
            WorkoutSetLog(setNumber: 3, weight: 0.0, reps: 10, isCompleted: false)
        ]
        let newEx = ExerciseLog(exerciseName: name.trimmingCharacters(in: .whitespaces), category: category, sets: newSets)
        dailyWorkoutLog.exercises.append(newEx)
        persistDailyLog()
    }

    func deleteExercise(id: UUID) {
        dailyWorkoutLog.exercises.removeAll(where: { $0.id == id })
        persistDailyLog()
    }

    private func persistDailyLog() {
        do {
            try workoutRepo.saveDailyLog(dailyWorkoutLog)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - JSON Plan Import

    func importWorkoutPlanJSON(_ jsonString: String) {
        do {
            let useCase = ImportWorkoutPlanJSONUseCase(workoutRepository: workoutRepo)
            let plan = try useCase.execute(jsonString: jsonString)
            activePlan = plan
            successMessage = "Successfully imported workout plan: '\(plan.title)'!"
            load(date: selectedDate)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Nutrition Actions

    func saveMealLog(_ meal: MealLog) {
        do {
            try nutritionRepo.saveMealLog(meal)
            load(date: selectedDate)
            successMessage = "Saved meal: \(meal.title)!"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMealLog(id: UUID) {
        do {
            try nutritionRepo.deleteMealLog(id: id)
            load(date: selectedDate)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func importMealMacroJSON(_ jsonString: String) {
        do {
            let useCase = ImportMealMacroJSONUseCase(nutritionRepository: nutritionRepo)
            let imported = try useCase.execute(jsonString: jsonString, for: selectedDate)
            successMessage = "Successfully imported \(imported.count) meal(s)!"
            load(date: selectedDate)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveMacroGoals(_ goals: MacroGoals) {
        do {
            try nutritionRepo.saveMacroGoals(goals)
            macroGoals = goals
            load(date: selectedDate)
            successMessage = "Updated daily macro targets!"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Nutrition Calculations

    var totalDailyCalories: Int {
        dailyMealLogs.reduce(0) { $0 + $1.calories }
    }

    var totalDailyProtein: Double {
        dailyMealLogs.reduce(0.0) { $0 + $1.proteinGrams }
    }

    var totalDailyCarbs: Double {
        dailyMealLogs.reduce(0.0) { $0 + $1.carbGrams }
    }

    var totalDailyFat: Double {
        dailyMealLogs.reduce(0.0) { $0 + $1.fatGrams }
    }
}
