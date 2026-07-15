// Application/UseCases/DataPortability/SyncWidgetDataUseCase.swift

import Foundation

struct SyncWidgetDataUseCase {
    let categoryRepository: any CategoryRepository
    let taskRepository: any TaskRepository
    let dayEntryRepository: any DayEntryRepository
    let goalRepository: any GoalRepository

    func execute() -> WidgetData? {
        try? buildWidgetData()
    }

    private func buildWidgetData() throws -> WidgetData {
        let today = Calendar.current.startOfDay(for: Date())
        let categories = try categoryRepository.fetchActive()
        let todayTasks = try taskRepository.fetchAll(for: today)
        let goals = try goalRepository.fetchAll()

        let masterEntry = try dayEntryRepository.fetch(date: today, categoryId: nil)
        let masterStreak = try CalculateStreakUseCase(dayEntryRepository: dayEntryRepository)
            .execute(categoryId: nil)

        // Master recent days
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let masterEntries = try dayEntryRepository.fetchAll(categoryId: nil)
        var masterRecentDays: [String: String] = [:]
        for entry in masterEntries {
            masterRecentDays[fmt.string(from: entry.date)] = entry.status.rawValue
        }

        var catData: [WidgetData.CategoryWidgetData] = []
        for cat in categories {
            let streak = try CalculateStreakUseCase(dayEntryRepository: dayEntryRepository)
                .execute(categoryId: cat.id)
            let todayEntry = try dayEntryRepository.fetch(date: today, categoryId: cat.id)
            let allEntries = try dayEntryRepository.fetchAll(categoryId: cat.id)

            var recentDays: [String: String] = [:]
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            fmt.locale = Locale(identifier: "en_US_POSIX")
            for entry in allEntries {
                recentDays[fmt.string(from: entry.date)] = entry.status.rawValue
            }

            catData.append(WidgetData.CategoryWidgetData(
                id: cat.id.uuidString,
                name: cat.name,
                colorHex: cat.colorHex,
                streak: streak,
                statusToday: todayEntry?.status.rawValue ?? "future",
                recentDays: recentDays
            ))
        }

        // Build task items for widget list
        let catColorMap: [UUID: String] = Dictionary(
            uniqueKeysWithValues: categories.map { ($0.id, $0.colorHex) }
        )
        let taskItems = todayTasks.map { task in
            WidgetData.TaskItem(
                title: task.title,
                isCompleted: task.isCompleted,
                categoryColorHex: task.categoryId.flatMap { catColorMap[$0] }
            )
        }

        // Build goals widget data
        let goalData = goals.map { goal in
            let cat = categories.first { $0.id == goal.categoryId }
            return WidgetData.GoalWidgetData(
                id: goal.id.uuidString,
                title: goal.title,
                categoryId: goal.categoryId?.uuidString,
                categoryColorHex: cat?.colorHex,
                currentValue: goal.currentValue,
                targetValue: goal.targetValue,
                unit: goal.unit,
                progressFraction: goal.progressFraction,
                isCompleted: goal.isCompleted,
                targetDate: goal.targetDate
            )
        }

        return WidgetData(
            masterStreak: masterStreak,
            masterStatusToday: masterEntry?.status.rawValue ?? "future",
            masterRecentDays: masterRecentDays,
            tasksToday: WidgetData.TaskSummary(
                total: todayTasks.count,
                completed: todayTasks.filter { $0.isCompleted }.count
            ),
            taskItems: taskItems,
            categories: catData,
            goals: goalData,
            lastUpdated: Date()
        )
    }
}
