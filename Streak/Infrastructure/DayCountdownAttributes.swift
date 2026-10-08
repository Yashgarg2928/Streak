// Infrastructure/DayCountdownAttributes.swift
// Shared between the main app (starts/updates the activity) and the widget
// extension (renders it on the Lock Screen and in the Dynamic Island).

import Foundation
import ActivityKit

struct DayCountdownAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var completed: Int
        var total: Int
        var streak: Int
        var isDone: Bool
    }

    /// When the active day ends.
    var deadline: Date
}
