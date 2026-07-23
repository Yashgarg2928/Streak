// Application/UseCases/Tasks/GenerateRoutineTasksUseCase.swift

import Foundation

final class GenerateRoutineTasksUseCase {
    private let habitRoutineRepository: any HabitRoutineRepository
    private let taskRepository: any TaskRepository

    init(
        habitRoutineRepository: any HabitRoutineRepository,
        taskRepository: any TaskRepository
    ) {
        self.habitRoutineRepository = habitRoutineRepository
        self.taskRepository = taskRepository
    }

    @discardableResult
    func execute(for date: Date) throws -> [Task] {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        let activeRoutines = try habitRoutineRepository.fetchActive(for: normalizedDate)
        let existingTasks = try taskRepository.fetchAll(for: normalizedDate)

        var generatedAny = false

        for routine in activeRoutines {
            let alreadyExists = existingTasks.contains { task in
                task.routineId == routine.id && !task.isDeleted
            }

            if !alreadyExists {
                let newTask = Task(
                    title: routine.title,
                    categoryId: routine.categoryId,
                    targetDate: normalizedDate,
                    timeframe: .daily,
                    isCompleted: false,
                    routineId: routine.id,
                    isLocked: routine.isLocked
                )
                try taskRepository.save(newTask)
                generatedAny = true
            }
        }

        return try taskRepository.fetchAll(for: normalizedDate)
    }
}
