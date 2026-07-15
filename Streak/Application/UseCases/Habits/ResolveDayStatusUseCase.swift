// Application/UseCases/Habits/ResolveDayStatusUseCase.swift
// Recomputes and persists a DayEntry for a given (date, categoryId) pair.
// categoryId == nil means master (all tasks across all categories).

import Foundation

struct ResolveDayStatusUseCase {
    let taskRepository: any TaskRepository
    let categoryRepository: any CategoryRepository
    let dayEntryRepository: any DayEntryRepository
    let settingsRepository: any SettingsRepository

    func execute(date: Date, categoryId: UUID?) throws {
        let tasks: [Task]

        if let categoryId {
            tasks = try taskRepository.fetchAll(for: date, categoryId: categoryId)
        } else {
            tasks = try taskRepository.fetchAll(for: date)
        }

        let taskCount = tasks.count
        let completedCount = tasks.filter { $0.isCompleted }.count
        let activeDate = ActiveDayResolver.resolveActiveDate(for: Date(), settings: settingsRepository)
        var status = DayStatus.resolve(taskCount: taskCount, completedCount: completedCount, date: date, activeDate: activeDate)

        if status == .green {
            let deadline = ActiveDayResolver.planningDeadline(for: date, settings: settingsRepository)
            let hasLateTasks = tasks.contains { $0.createdAt > deadline }
            if hasLateTasks {
                status = .red
            }
        }

        let entry = DayEntry(
            date: date,
            categoryId: categoryId,
            status: status,
            taskCount: taskCount,
            completedCount: completedCount
        )
        try dayEntryRepository.save(entry)
    }
}
