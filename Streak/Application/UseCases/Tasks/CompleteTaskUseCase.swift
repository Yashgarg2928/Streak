// Application/UseCases/Tasks/CompleteTaskUseCase.swift

import Foundation

struct CompleteTaskUseCase {
    let taskRepository: any TaskRepository
    let resolveDayStatus: ResolveDayStatusUseCase

    func execute(taskId: UUID, completed: Bool) throws {
        guard var task = try taskRepository.fetch(id: taskId) else {
            throw StreakError.taskNotFound
        }
        // Cannot complete a task that isn't for today or earlier
        let today = Calendar.current.startOfDay(for: Date())
        guard task.targetDate <= today else { return }
        task.isCompleted = completed
        task.completedAt = completed ? Date() : nil
        try taskRepository.save(task)

        try resolveDayStatus.execute(date: task.targetDate, categoryId: task.categoryId)
        try resolveDayStatus.execute(date: task.targetDate, categoryId: nil)
    }
}
