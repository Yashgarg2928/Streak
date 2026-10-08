// App/HealthSync.swift
// Applies Health data sent from Apple Shortcuts: stores the day's totals, then ticks
// every habit commitment whose Health rule is met (through the normal completion flow,
// so day status, XP, goals and widgets all update).

import Foundation

enum HealthSync {
    struct Outcome {
        let snapshot: HealthSnapshot
        let completedHabits: [String]
    }

    static func log(
        env: AppEnvironment,
        date: Date,
        steps: Int?,
        activeEnergyKcal: Int?,
        exerciseMinutes: Int?,
        workoutCount: Int?,
        workoutMinutes: Int?
    ) throws -> Outcome {
        let snapshot = try LogHealthSnapshotUseCase(repository: env.healthSnapshotRepository).execute(
            date: date,
            steps: steps,
            activeEnergyKcal: activeEnergyKcal,
            exerciseMinutes: exerciseMinutes,
            workoutCount: workoutCount,
            workoutMinutes: workoutMinutes
        )
        let completed = try applyHealthRules(env: env, snapshot: snapshot)
        try SyncGoalProgressUseCase(
            goalRepository: env.goalRepository,
            dayEntryRepository: env.dayEntryRepository,
            taskRepository: env.taskRepository,
            settingsRepository: env.settingsRepository
        ).execute()
        env.syncWidgets()
        return Outcome(snapshot: snapshot, completedHabits: completed)
    }

    /// Ticks habit tasks on the snapshot's day whose Health target is met. Returns their titles.
    @discardableResult
    static func applyHealthRules(env: AppEnvironment, snapshot: HealthSnapshot) throws -> [String] {
        let routines = try env.habitRoutineRepository.fetchActive(for: snapshot.date)
            .filter { $0.healthRule?.isMet(by: snapshot) == true }
        guard !routines.isEmpty else { return [] }

        let tasks = try GenerateRoutineTasksUseCase(
            habitRoutineRepository: env.habitRoutineRepository,
            taskRepository: env.taskRepository
        ).execute(for: snapshot.date)

        var completed: [String] = []
        for routine in routines {
            guard let task = tasks.first(where: { $0.routineId == routine.id && !$0.isDeleted }),
                  !task.isCompleted else { continue }
            try env.setTaskCompleted(task.id, completed: true, syncAfterwards: false)
            completed.append(routine.title)
        }
        return completed
    }
}
