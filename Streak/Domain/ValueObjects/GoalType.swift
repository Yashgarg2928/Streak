// Domain/ValueObjects/GoalType.swift
// Pure Swift — no UIKit, SwiftUI, or SwiftData imports

import Foundation

enum GoalType: String, Codable, Equatable, CaseIterable {
    case consecutiveStreak
    case cumulativeDays
    case milestoneBased
    case taskCounter
}
