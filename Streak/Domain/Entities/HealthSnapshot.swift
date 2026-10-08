// Domain/Entities/HealthSnapshot.swift
// Pure Swift — no UIKit, SwiftUI, or SwiftData imports
//
// One day's activity totals, sent from the Health app through an Apple Shortcuts
// automation (the app itself can't use HealthKit with free Apple ID signing).

import Foundation

struct HealthSnapshot: Identifiable, Equatable {
    let id: UUID
    var date: Date              // start of the active day
    var steps: Int
    var activeEnergyKcal: Int
    var exerciseMinutes: Int
    var workoutCount: Int
    var workoutMinutes: Int
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        steps: Int = 0,
        activeEnergyKcal: Int = 0,
        exerciseMinutes: Int = 0,
        workoutCount: Int = 0,
        workoutMinutes: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.steps = steps
        self.activeEnergyKcal = activeEnergyKcal
        self.exerciseMinutes = exerciseMinutes
        self.workoutCount = workoutCount
        self.workoutMinutes = workoutMinutes
        self.updatedAt = updatedAt
    }
}

enum HealthMetric: String, CaseIterable, Codable, Identifiable {
    case steps
    case exerciseMinutes
    case activeEnergy
    case workouts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .steps:           return "Steps"
        case .exerciseMinutes: return "Exercise minutes"
        case .activeEnergy:    return "Active energy"
        case .workouts:        return "Workouts"
        }
    }

    var unit: String {
        switch self {
        case .steps:           return "steps"
        case .exerciseMinutes: return "min"
        case .activeEnergy:    return "kcal"
        case .workouts:        return "workout"
        }
    }

    var defaultTarget: Int {
        switch self {
        case .steps:           return 10_000
        case .exerciseMinutes: return 30
        case .activeEnergy:    return 500
        case .workouts:        return 1
        }
    }

    func value(in snapshot: HealthSnapshot) -> Int {
        switch self {
        case .steps:           return snapshot.steps
        case .exerciseMinutes: return snapshot.exerciseMinutes
        case .activeEnergy:    return snapshot.activeEnergyKcal
        case .workouts:        return snapshot.workoutCount
        }
    }
}

/// Auto-completes a habit commitment once a Health metric reaches its target.
struct HealthRule: Equatable {
    var metric: HealthMetric
    var target: Int

    func isMet(by snapshot: HealthSnapshot) -> Bool {
        target > 0 && metric.value(in: snapshot) >= target
    }

    /// e.g. "≥ 10,000 steps"
    var summary: String {
        "≥ \(target.formatted()) \(metric.unit)\(metric == .workouts && target > 1 ? "s" : "")"
    }

    /// Storage form: "steps:10000".
    var encoded: String { "\(metric.rawValue):\(target)" }

    init(metric: HealthMetric, target: Int) {
        self.metric = metric
        self.target = target
    }

    init?(encoded: String?) {
        guard let parts = encoded?.split(separator: ":"), parts.count == 2,
              let metric = HealthMetric(rawValue: String(parts[0])),
              let target = Int(parts[1]) else { return nil }
        self.init(metric: metric, target: target)
    }
}
