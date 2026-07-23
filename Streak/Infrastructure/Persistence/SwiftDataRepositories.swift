// Infrastructure/Persistence/SwiftDataRepositories.swift
// Concrete implementations of all Domain repository protocols using SwiftData.

import Foundation
import SwiftData

// MARK: - Category

final class SwiftDataCategoryRepository: CategoryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Category] {
        let models = try context.fetch(FetchDescriptor<CategoryModel>())
        return models.map { $0.toDomain() }
    }

    func fetchActive() throws -> [Category] {
        let descriptor = FetchDescriptor<CategoryModel>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func fetch(id: UUID) throws -> Category? {
        let localId = id
        let models = try context.fetch(FetchDescriptor<CategoryModel>(
            predicate: #Predicate { $0.id == localId }
        ))
        return models.first?.toDomain()
    }

    func save(_ category: Category) throws {
        let localId = category.id
        let existing = try context.fetch(FetchDescriptor<CategoryModel>(
            predicate: #Predicate { $0.id == localId }
        )).first
        if let existing {
            existing.update(from: category)
        } else {
            context.insert(CategoryModel(from: category))
        }
        try context.save()
    }

    func delete(id: UUID) throws {
        let localId = id
        let models = try context.fetch(FetchDescriptor<CategoryModel>(
            predicate: #Predicate { $0.id == localId }
        ))
        models.forEach { context.delete($0) }
        try context.save()
    }

    func archive(id: UUID) throws {
        let localId = id
        let models = try context.fetch(FetchDescriptor<CategoryModel>(
            predicate: #Predicate { $0.id == localId }
        ))
        models.first?.isArchived = true
        try context.save()
    }

    func maxSortOrder() throws -> Int {
        let all = try context.fetch(FetchDescriptor<CategoryModel>())
        return all.map { $0.sortOrder }.max() ?? -1
    }
}

// MARK: - Task

final class SwiftDataTaskRepository: TaskRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(for date: Date) throws -> [Task] {
        let day = Calendar.current.startOfDay(for: date)
        let dailyRaw = TaskTimeframe.daily.rawValue
        let models = try context.fetch(FetchDescriptor<TaskModel>(
            predicate: #Predicate { $0.targetDate == day && $0.timeframeRaw == dailyRaw }
        ))
        return models.map { $0.toDomain() }
    }

    func fetchAll(for date: Date, categoryId: UUID) throws -> [Task] {
        let day = Calendar.current.startOfDay(for: date)
        let localCatId = categoryId
        let dailyRaw = TaskTimeframe.daily.rawValue
        let models = try context.fetch(FetchDescriptor<TaskModel>(
            predicate: #Predicate { $0.targetDate == day && $0.categoryId == localCatId && $0.timeframeRaw == dailyRaw }
        ))
        return models.map { $0.toDomain() }
    }

    func fetch(timeframe: TaskTimeframe) throws -> [Task] {
        let raw = timeframe.rawValue
        let models = try context.fetch(FetchDescriptor<TaskModel>(
            predicate: #Predicate { $0.timeframeRaw == raw }
        ))
        return models.map { $0.toDomain() }
    }

    func fetch(id: UUID) throws -> Task? {
        let localId = id
        let models = try context.fetch(FetchDescriptor<TaskModel>(
            predicate: #Predicate { $0.id == localId }
        ))
        return models.first?.toDomain()
    }

    func save(_ task: Task) throws {
        let localId = task.id
        let existing = try context.fetch(FetchDescriptor<TaskModel>(
            predicate: #Predicate { $0.id == localId }
        )).first
        if let existing {
            existing.update(from: task)
        } else {
            context.insert(TaskModel(from: task))
        }
        try context.save()
    }

    func delete(id: UUID) throws {
        let localId = id
        let models = try context.fetch(FetchDescriptor<TaskModel>(
            predicate: #Predicate { $0.id == localId }
        ))
        models.forEach { $0.isDeleted = true }
        try context.save()
    }

    func deletePermanently(id: UUID) throws {
        let localId = id
        let models = try context.fetch(FetchDescriptor<TaskModel>(
            predicate: #Predicate { $0.id == localId }
        ))
        models.forEach { context.delete($0) }
        try context.save()
    }

    func fetchAll() throws -> [Task] {
        let models = try context.fetch(FetchDescriptor<TaskModel>())
        return models.map { $0.toDomain() }
    }
}

// MARK: - DayEntry

final class SwiftDataDayEntryRepository: DayEntryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetch(date: Date, categoryId: UUID?) throws -> DayEntry? {
        let day = Calendar.current.startOfDay(for: date)
        let models: [DayEntryModel]
        if let categoryId {
            let localCatId = categoryId
            models = try context.fetch(FetchDescriptor<DayEntryModel>(
                predicate: #Predicate { $0.date == day && $0.categoryId == localCatId }
            ))
        } else {
            models = try context.fetch(FetchDescriptor<DayEntryModel>(
                predicate: #Predicate { $0.date == day && $0.categoryId == nil }
            ))
        }
        return models.first?.toDomain()
    }

    func save(_ entry: DayEntry) throws {
        let day = Calendar.current.startOfDay(for: entry.date)
        let existing: DayEntryModel?
        if let categoryId = entry.categoryId {
            let localCatId = categoryId
            existing = try context.fetch(FetchDescriptor<DayEntryModel>(
                predicate: #Predicate { $0.date == day && $0.categoryId == localCatId }
            )).first
        } else {
            existing = try context.fetch(FetchDescriptor<DayEntryModel>(
                predicate: #Predicate { $0.date == day && $0.categoryId == nil }
            )).first
        }
        if let existing {
            existing.update(from: entry)
        } else {
            context.insert(DayEntryModel(from: entry))
        }
        try context.save()
    }

    func fetchAll(categoryId: UUID?) throws -> [DayEntry] {
        let models: [DayEntryModel]
        if let categoryId {
            let localCatId = categoryId
            models = try context.fetch(FetchDescriptor<DayEntryModel>(
                predicate: #Predicate { $0.categoryId == localCatId }
            ))
        } else {
            models = try context.fetch(FetchDescriptor<DayEntryModel>(
                predicate: #Predicate { $0.categoryId == nil }
            ))
        }
        return models.map { $0.toDomain() }
    }
}

// MARK: - Goal

final class SwiftDataGoalRepository: GoalRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Goal] {
        let models = try context.fetch(FetchDescriptor<GoalModel>())
        return models.map { $0.toDomain() }
    }

    func fetchActive() throws -> [Goal] {
        let models = try context.fetch(FetchDescriptor<GoalModel>(
            predicate: #Predicate { !$0.isCompleted }
        ))
        return models.map { $0.toDomain() }
    }

    func fetch(id: UUID) throws -> Goal? {
        let localId = id
        let models = try context.fetch(FetchDescriptor<GoalModel>(
            predicate: #Predicate { $0.id == localId }
        ))
        return models.first?.toDomain()
    }

    func save(_ goal: Goal) throws {
        let localId = goal.id
        let existing = try context.fetch(FetchDescriptor<GoalModel>(
            predicate: #Predicate { $0.id == localId }
        )).first
        if let existing {
            existing.update(from: goal)
        } else {
            context.insert(GoalModel(from: goal))
        }
        try context.save()
    }

    func delete(id: UUID) throws {
        let localId = id
        let models = try context.fetch(FetchDescriptor<GoalModel>(
            predicate: #Predicate { $0.id == localId }
        ))
        models.forEach { context.delete($0) }
        try context.save()
    }

    func saveProgressEntry(_ entry: GoalProgressEntry) throws {
        let day = Calendar.current.startOfDay(for: entry.date)
        let localGoalId = entry.goalId
        let existing = try context.fetch(FetchDescriptor<GoalProgressEntryModel>(
            predicate: #Predicate { $0.goalId == localGoalId && $0.date == day }
        )).first
        if let existing {
            existing.update(from: entry)
        } else {
            context.insert(GoalProgressEntryModel(from: entry))
        }
        try context.save()
    }

    func fetchProgressEntries(goalId: UUID) throws -> [GoalProgressEntry] {
        let localGoalId = goalId
        let models = try context.fetch(FetchDescriptor<GoalProgressEntryModel>(
            predicate: #Predicate { $0.goalId == localGoalId },
            sortBy: [SortDescriptor(\.date)]
        ))
        return models.map { $0.toDomain() }
    }

    func fetchProgressEntry(goalId: UUID, date: Date) throws -> GoalProgressEntry? {
        let day = Calendar.current.startOfDay(for: date)
        let localGoalId = goalId
        let models = try context.fetch(FetchDescriptor<GoalProgressEntryModel>(
            predicate: #Predicate { $0.goalId == localGoalId && $0.date == day }
        ))
        return models.first?.toDomain()
    }
}

// MARK: - Reflection

final class SwiftDataReflectionRepository: ReflectionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetch(date: Date) throws -> ReflectionEntry? {
        let day = Calendar.current.startOfDay(for: date)
        let models = try context.fetch(FetchDescriptor<ReflectionEntryModel>(
            predicate: #Predicate { $0.date == day }
        ))
        return models.first?.toDomain()
    }

    func save(_ entry: ReflectionEntry) throws {
        let day = Calendar.current.startOfDay(for: entry.date)
        let existing = try context.fetch(FetchDescriptor<ReflectionEntryModel>(
            predicate: #Predicate { $0.date == day }
        )).first
        if let existing {
            existing.update(from: entry)
        } else {
            context.insert(ReflectionEntryModel(from: entry))
        }
        try context.save()
    }

    func fetchAll() throws -> [ReflectionEntry] {
        let models = try context.fetch(FetchDescriptor<ReflectionEntryModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        ))
        return models.map { $0.toDomain() }
    }
}
