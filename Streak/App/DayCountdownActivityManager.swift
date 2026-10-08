// App/DayCountdownActivityManager.swift
// Keeps one Live Activity on the Lock Screen / Dynamic Island counting down to the end
// of the active day while planned tasks are still open. Refreshed from syncWidgets().
//
// iOS ends a Live Activity after ~8 hours and only lets an app start one while it's in
// the foreground (or from a LiveActivityIntent such as StartDayCountdownIntent), so the
// countdown is (re)started whenever the app opens or the Shortcuts action runs.

import Foundation
import ActivityKit

enum DayCountdownActivityManager {
    enum Outcome {
        case showing
        case dayComplete
        case nothingPlanned
        case disabledInSettings
        case notAllowedByIOS
        case couldNotStart
    }

    @discardableResult
    static func refresh(with data: WidgetData, settings: SettingsRepository) -> Outcome {
        let deadline = data.activeDayDeadline
        let isDone = data.masterStatusToday == DayStatus.green.rawValue
            || data.masterStatusToday == DayStatus.frozen.rawValue
            || data.masterStatusToday == DayStatus.rest.rawValue
        let state = DayCountdownAttributes.ContentState(
            completed: data.tasksToday.completed,
            total: data.tasksToday.total,
            streak: data.masterStreak,
            isDone: isDone
        )
        // Ended or dismissed activities (e.g. stopped by iOS after 8 hours) can't be updated.
        let live = Activity<DayCountdownAttributes>.activities.filter {
            $0.activityState == .active || $0.activityState == .stale
        }

        guard settings.isLiveActivityEnabled else {
            end(live, state: state, immediately: true)
            return .disabledInSettings
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return .notAllowedByIOS
        }
        guard data.tasksToday.total > 0, deadline > Date() else {
            end(live, state: state, immediately: true)
            return .nothingPlanned
        }

        // Day finished: show the win briefly, then dismiss.
        if isDone {
            end(live, state: state, immediately: false)
            return .dayComplete
        }

        if let activity = live.first(where: { $0.attributes.deadline == deadline }) {
            end(live.filter { $0.id != activity.id }, state: state, immediately: true)
            Swift.Task {
                await activity.update(ActivityContent(state: state, staleDate: deadline))
            }
            return .showing
        }

        end(live, state: state, immediately: true)
        do {
            _ = try Activity.request(
                attributes: DayCountdownAttributes(deadline: deadline),
                content: ActivityContent(state: state, staleDate: deadline),
                pushType: nil
            )
            return .showing
        } catch {
            // Expected while the app is in the background; the next foreground refresh retries.
            return .couldNotStart
        }
    }

    private static func end(
        _ activities: [Activity<DayCountdownAttributes>],
        state: DayCountdownAttributes.ContentState,
        immediately: Bool
    ) {
        for activity in activities {
            Swift.Task {
                await activity.end(
                    ActivityContent(state: state, staleDate: nil),
                    dismissalPolicy: immediately ? .immediate : .after(Date().addingTimeInterval(15 * 60))
                )
            }
        }
    }
}
