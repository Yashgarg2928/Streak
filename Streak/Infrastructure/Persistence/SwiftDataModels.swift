// Infrastructure/Persistence/SwiftDataModels.swift
// @Model classes mirror the Domain entities for SwiftData persistence.
// These live in Infrastructure — the Domain structs remain pure Swift.

import Foundation
import SwiftData

@Model
final class CategoryModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var sortOrder: Int
    var isArchived: Bool
    var createdAt: Date

    init(from entity: Category) {
        self.id = entity.id
        self.name = entity.name
        self.colorHex = entity.colorHex
        self.sortOrder = entity.sortOrder
        self.isArchived = entity.isArchived
        self.createdAt = entity.createdAt
    }

    func toDomain() -> Category {
        Category(id: id, name: name, colorHex: colorHex,
                 sortOrder: sortOrder, isArchived: isArchived, createdAt: createdAt)
    }

    func update(from entity: Category) {
        name = entity.name
        colorHex = entity.colorHex
        sortOrder = entity.sortOrder
        isArchived = entity.isArchived
    }
}

@Model
final class TaskModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var categoryId: UUID?
    var targetDate: Date
    var timeframeRaw: String = TaskTimeframe.daily.rawValue
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date
    var isDeleted: Bool = false
    var routineId: UUID? = nil
    var isLocked: Bool = false

    var timeframe: TaskTimeframe {
        get { TaskTimeframe(rawValue: timeframeRaw) ?? .daily }
        set { timeframeRaw = newValue.rawValue }
    }

    init(from entity: Task) {
        self.id = entity.id
        self.title = entity.title
        self.categoryId = entity.categoryId
        self.targetDate = entity.targetDate
        self.timeframeRaw = entity.timeframe.rawValue
        self.isCompleted = entity.isCompleted
        self.completedAt = entity.completedAt
        self.createdAt = entity.createdAt
        self.isDeleted = entity.isDeleted
        self.routineId = entity.routineId
        self.isLocked = entity.isLocked
    }

    func toDomain() -> Task {
        Task(id: id, title: title, categoryId: categoryId,
             targetDate: targetDate, timeframe: timeframe,
             isCompleted: isCompleted, completedAt: completedAt,
             createdAt: createdAt, isDeleted: isDeleted,
             routineId: routineId, isLocked: isLocked)
    }

    func update(from entity: Task) {
        title = entity.title
        categoryId = entity.categoryId
        targetDate = entity.targetDate
        timeframeRaw = entity.timeframe.rawValue
        isCompleted = entity.isCompleted
        completedAt = entity.completedAt
        isDeleted = entity.isDeleted
        routineId = entity.routineId
        isLocked = entity.isLocked
    }
}

@Model
final class HabitRoutineModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var categoryId: UUID?
    var typeRaw: String
    var startDate: Date
    var endDate: Date
    var isLocked: Bool
    var createdAt: Date

    var type: HabitRoutineType {
        get { HabitRoutineType(rawValue: typeRaw) ?? .monthlyFixed }
        set { typeRaw = newValue.rawValue }
    }

    init(from entity: HabitRoutine) {
        self.id = entity.id
        self.title = entity.title
        self.categoryId = entity.categoryId
        self.typeRaw = entity.type.rawValue
        self.startDate = entity.startDate
        self.endDate = entity.endDate
        self.isLocked = entity.isLocked
        self.createdAt = entity.createdAt
    }

    func toDomain() -> HabitRoutine {
        HabitRoutine(
            id: id,
            title: title,
            categoryId: categoryId,
            type: type,
            startDate: startDate,
            endDate: endDate,
            isLocked: isLocked,
            createdAt: createdAt
        )
    }

    func update(from entity: HabitRoutine) {
        title = entity.title
        categoryId = entity.categoryId
        typeRaw = entity.type.rawValue
        startDate = entity.startDate
        endDate = entity.endDate
        isLocked = entity.isLocked
    }
}

@Model
final class DayEntryModel {
    @Attribute(.unique) var id: UUID
    var date: Date
    var categoryId: UUID?
    var statusRaw: String
    var taskCount: Int
    var completedCount: Int
    var lastUpdated: Date

    var status: DayStatus {
        get { DayStatus(rawValue: statusRaw) ?? .red }
        set { statusRaw = newValue.rawValue }
    }

    init(from entity: DayEntry) {
        self.id = entity.id
        self.date = entity.date
        self.categoryId = entity.categoryId
        self.statusRaw = entity.status.rawValue
        self.taskCount = entity.taskCount
        self.completedCount = entity.completedCount
        self.lastUpdated = entity.lastUpdated
    }

    func toDomain() -> DayEntry {
        DayEntry(id: id, date: date, categoryId: categoryId,
                 status: status, taskCount: taskCount,
                 completedCount: completedCount, lastUpdated: lastUpdated)
    }

    func update(from entity: DayEntry) {
        date = entity.date
        categoryId = entity.categoryId
        statusRaw = entity.status.rawValue
        taskCount = entity.taskCount
        completedCount = entity.completedCount
        lastUpdated = entity.lastUpdated
    }
}

@Model
final class GoalModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var goalTypeRaw: String
    var categoryId: UUID?
    var targetValue: Double
    var currentValue: Double
    var unit: String
    var startDate: Date
    var targetDate: Date?
    var isCompleted: Bool
    var dailyNotificationTime: Date?
    var createdAt: Date

    var goalType: GoalType {
        get { GoalType(rawValue: goalTypeRaw) ?? .milestoneBased }
        set { goalTypeRaw = newValue.rawValue }
    }

    init(from entity: Goal) {
        self.id = entity.id
        self.title = entity.title
        self.goalTypeRaw = entity.goalType.rawValue
        self.categoryId = entity.categoryId
        self.targetValue = entity.targetValue
        self.currentValue = entity.currentValue
        self.unit = entity.unit
        self.startDate = entity.startDate
        self.targetDate = entity.targetDate
        self.isCompleted = entity.isCompleted
        self.dailyNotificationTime = entity.dailyNotificationTime
        self.createdAt = entity.createdAt
    }

    func toDomain() -> Goal {
        Goal(id: id, title: title, goalType: goalType,
             categoryId: categoryId, targetValue: targetValue,
             currentValue: currentValue, unit: unit, startDate: startDate,
             targetDate: targetDate, isCompleted: isCompleted,
             dailyNotificationTime: dailyNotificationTime, createdAt: createdAt)
    }

    func update(from entity: Goal) {
        title = entity.title
        goalTypeRaw = entity.goalType.rawValue
        categoryId = entity.categoryId
        targetValue = entity.targetValue
        currentValue = entity.currentValue
        unit = entity.unit
        startDate = entity.startDate
        targetDate = entity.targetDate
        isCompleted = entity.isCompleted
        dailyNotificationTime = entity.dailyNotificationTime
    }
}

@Model
final class GoalProgressEntryModel {
    @Attribute(.unique) var id: UUID
    var goalId: UUID
    var date: Date
    var value: Double
    var note: String?
    var createdAt: Date

    init(from entity: GoalProgressEntry) {
        self.id = entity.id
        self.goalId = entity.goalId
        self.date = entity.date
        self.value = entity.value
        self.note = entity.note
        self.createdAt = entity.createdAt
    }

    func toDomain() -> GoalProgressEntry {
        GoalProgressEntry(id: id, goalId: goalId, date: date,
                          value: value, note: note, createdAt: createdAt)
    }

    func update(from entity: GoalProgressEntry) {
        value = entity.value
        note = entity.note
    }
}

@Model
final class ReflectionEntryModel {
    @Attribute(.unique) var id: UUID
    var date: Date
    var accomplishments: String
    var missedItems: String
    var tomorrowPriorities: String
    var goalNotes: String
    var consistencyRating: Int
    var createdAt: Date
    var updatedAt: Date

    init(from entity: ReflectionEntry) {
        self.id = entity.id
        self.date = entity.date
        self.accomplishments = entity.accomplishments
        self.missedItems = entity.missedItems
        self.tomorrowPriorities = entity.tomorrowPriorities
        self.goalNotes = entity.goalNotes
        self.consistencyRating = entity.consistencyRating
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }

    func toDomain() -> ReflectionEntry {
        ReflectionEntry(id: id, date: date, accomplishments: accomplishments,
                        missedItems: missedItems, tomorrowPriorities: tomorrowPriorities,
                        goalNotes: goalNotes, consistencyRating: consistencyRating,
                        createdAt: createdAt, updatedAt: updatedAt)
    }

    func update(from entity: ReflectionEntry) {
        accomplishments = entity.accomplishments
        missedItems = entity.missedItems
        tomorrowPriorities = entity.tomorrowPriorities
        goalNotes = entity.goalNotes
        consistencyRating = entity.consistencyRating
        updatedAt = entity.updatedAt
    }
}
