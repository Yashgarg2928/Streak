// App/HealthAppIntents.swift
// Shortcuts action that brings Apple Health data into Streak. A personal Shortcuts
// automation reads the Health app (no HealthKit entitlement needed in Streak) and
// passes the day's totals here. See HealthShortcutGuideSheet for the setup steps.

import AppIntents
import Foundation

/// A LiveActivityIntent so a Health sync from a Shortcuts automation can also (re)start
/// the day countdown without opening the app.
struct LogHealthDataIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Log Health Data in Streak"
    static let description = IntentDescription(
        "Sends today's steps, active energy, exercise minutes and workouts from the Health app to Streak. Habits linked to Apple Health are ticked automatically when you hit their target.",
        categoryName: "Health"
    )
    static let openAppWhenRun = false

    @Parameter(title: "Steps")
    var steps: Double?

    @Parameter(title: "Active Energy (kcal)")
    var activeEnergy: Double?

    @Parameter(title: "Exercise Minutes")
    var exerciseMinutes: Double?

    @Parameter(title: "Workouts", description: "Number of workouts today")
    var workouts: Double?

    @Parameter(title: "Workout Minutes")
    var workoutMinutes: Double?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$steps) steps to Streak") {
            \.$activeEnergy
            \.$exerciseMinutes
            \.$workouts
            \.$workoutMinutes
        }
    }

    @MainActor
    func perform() async throws -> some ProvidesDialog {
        let env = try AppEnvironment.currentOrStandalone()
        let today = ActiveDayResolver.resolveActiveDate(for: Date(), settings: env.settingsRepository)
        let outcome = try HealthSync.log(
            env: env,
            date: today,
            steps: steps.map { Int($0.rounded()) },
            activeEnergyKcal: activeEnergy.map { Int($0.rounded()) },
            exerciseMinutes: exerciseMinutes.map { Int($0.rounded()) },
            workoutCount: workouts.map { Int($0.rounded()) },
            workoutMinutes: workoutMinutes.map { Int($0.rounded()) }
        )

        var message = "Synced to Streak: \(outcome.snapshot.steps.formatted()) steps, \(outcome.snapshot.exerciseMinutes) exercise min."
        if !outcome.completedHabits.isEmpty {
            message += " Ticked: \(outcome.completedHabits.joined(separator: ", "))."
        }
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
