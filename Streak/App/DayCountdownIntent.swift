// App/DayCountdownIntent.swift
// "Show Day Countdown" Shortcuts / Siri action. As a LiveActivityIntent it may start the
// Lock Screen / Dynamic Island countdown without opening Streak, so a morning Shortcuts
// automation can turn it on every day.

import AppIntents
import Foundation

struct StartDayCountdownIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Show Day Countdown"
    static let description = IntentDescription(
        "Shows today's tasks and the time left in your day on the Lock Screen and in the Dynamic Island. Add it to a morning automation so it starts without opening Streak."
    )
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some ProvidesDialog {
        let env = try AppEnvironment.currentOrStandalone()
        // Brings today up to date (habit tasks, status) and refreshes widgets + the countdown.
        DaySweeper.run(env: env)

        guard let data = WidgetDataStore.load() else {
            return .result(dialog: "Open Streak once, then try again.")
        }
        let message: String
        switch DayCountdownActivityManager.refresh(with: data, settings: env.settingsRepository) {
        case .showing:
            message = "Day countdown is on: \(data.tasksToday.completed)/\(data.tasksToday.total) done."
        case .dayComplete:
            message = "Today's already done. Nice work."
        case .nothingPlanned:
            message = "Nothing planned for today yet. Add a task and the countdown will start."
        case .disabledInSettings:
            message = "The Lock Screen countdown is off. Turn it on in Streak → Settings."
        case .notAllowedByIOS:
            message = "Live Activities are off for Streak. Turn them on in iPhone Settings → Streak."
        case .couldNotStart:
            message = "iOS didn't allow the countdown to start right now. Open Streak to start it."
        }
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
