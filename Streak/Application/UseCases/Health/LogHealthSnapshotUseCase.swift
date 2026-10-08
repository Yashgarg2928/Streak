// Application/UseCases/Health/LogHealthSnapshotUseCase.swift
// Stores a day's Health totals. Shortcuts may run several automations a day, each
// sending only some metrics, so a nil value keeps what's already stored.

import Foundation

struct LogHealthSnapshotUseCase {
    let repository: any HealthSnapshotRepository

    func execute(
        date: Date,
        steps: Int?,
        activeEnergyKcal: Int?,
        exerciseMinutes: Int?,
        workoutCount: Int?,
        workoutMinutes: Int?
    ) throws -> HealthSnapshot {
        var snapshot = try repository.fetch(date: date) ?? HealthSnapshot(date: date)
        if let steps { snapshot.steps = max(0, steps) }
        if let activeEnergyKcal { snapshot.activeEnergyKcal = max(0, activeEnergyKcal) }
        if let exerciseMinutes { snapshot.exerciseMinutes = max(0, exerciseMinutes) }
        if let workoutCount { snapshot.workoutCount = max(0, workoutCount) }
        if let workoutMinutes { snapshot.workoutMinutes = max(0, workoutMinutes) }
        snapshot.updatedAt = Date()
        try repository.save(snapshot)
        return snapshot
    }
}
