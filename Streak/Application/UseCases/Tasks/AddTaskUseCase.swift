// Application/UseCases/Tasks/AddTaskUseCase.swift

import Foundation

struct AddTaskUseCase {
    let taskRepository: any TaskRepository
    let categoryRepository: any CategoryRepository
    let resolveDayStatus: ResolveDayStatusUseCase
    let settingsRepository: any SettingsRepository

    func execute(title: String, categoryId: UUID?, targetDate: Date) throws -> Task {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw StreakError.emptyTitle }
        try validateTargetDate(targetDate)

        if let categoryId {
            guard let category = try categoryRepository.fetch(id: categoryId),
                  !category.isArchived else {
                throw StreakError.categoryNotFound
            }
        }

        let task = Task(title: trimmed, categoryId: categoryId, targetDate: targetDate)
        try taskRepository.save(task)
        try resolveDayStatus.execute(date: targetDate, categoryId: categoryId)
        try resolveDayStatus.execute(date: targetDate, categoryId: nil)
        return task
    }

    // v1: tasks only for today or tomorrow
    private func validateTargetDate(_ date: Date) throws {
        let cal = Calendar.current
        let today = ActiveDayResolver.resolveActiveDate(for: Date(), settings: settingsRepository)
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
        let day = cal.startOfDay(for: date)
        guard day == today || day == tomorrow else {
            throw StreakError.invalidTargetDate
        }
    }
}
