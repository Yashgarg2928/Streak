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

// MARK: - HabitRoutine

final class SwiftDataHabitRoutineRepository: HabitRoutineRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [HabitRoutine] {
        let models = try context.fetch(FetchDescriptor<HabitRoutineModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        ))
        return models.map { $0.toDomain() }
    }

    func fetchActive(for date: Date) throws -> [HabitRoutine] {
        let target = Calendar.current.startOfDay(for: date)
        let models = try context.fetch(FetchDescriptor<HabitRoutineModel>())
        return models
            .map { $0.toDomain() }
            .filter { routine in
                let start = Calendar.current.startOfDay(for: routine.startDate)
                let end = Calendar.current.startOfDay(for: routine.endDate)
                return target >= start && target <= end
            }
    }

    func fetch(id: UUID) throws -> HabitRoutine? {
        let localId = id
        let models = try context.fetch(FetchDescriptor<HabitRoutineModel>(
            predicate: #Predicate { $0.id == localId }
        ))
        return models.first?.toDomain()
    }

    func save(_ routine: HabitRoutine) throws {
        let localId = routine.id
        let existing = try context.fetch(FetchDescriptor<HabitRoutineModel>(
            predicate: #Predicate { $0.id == localId }
        )).first
        if let existing {
            existing.update(from: routine)
        } else {
            context.insert(HabitRoutineModel(from: routine))
        }
        try context.save()
    }

    func delete(id: UUID) throws {
        let localId = id
        let models = try context.fetch(FetchDescriptor<HabitRoutineModel>(
            predicate: #Predicate { $0.id == localId }
        ))
        guard let existing = models.first else { return }
        
        // Locked monthly commitments cannot be deleted
        if existing.isLocked {
            return
        }
        
        context.delete(existing)
        try context.save()
    }
}

// MARK: - Gamification Repositories

final class SwiftDataPlayerProfileRepository: PlayerProfileRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchProfile() throws -> PlayerProfile {
        let models = try context.fetch(FetchDescriptor<PlayerProfileModel>())
        if let first = models.first {
            return first.toDomain()
        }
        // Initialize default profile if none exists
        let defaultProfile = PlayerProfile(totalXP: 0, streakFreezes: 0)
        context.insert(PlayerProfileModel(from: defaultProfile))
        try context.save()
        return defaultProfile
    }

    func saveProfile(_ profile: PlayerProfile) throws {
        let localId = profile.id
        let models = try context.fetch(FetchDescriptor<PlayerProfileModel>(
            predicate: #Predicate { $0.id == localId }
        ))
        if let existing = models.first {
            existing.update(from: profile)
        } else {
            context.insert(PlayerProfileModel(from: profile))
        }
        try context.save()
    }
}

final class SwiftDataBadgeRepository: BadgeRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Badge] {
        let models = try context.fetch(FetchDescriptor<BadgeModel>(
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]
        ))
        return models.map { $0.toDomain() }
    }

    func fetch(byKey badgeKey: String) throws -> Badge? {
        let localKey = badgeKey
        let models = try context.fetch(FetchDescriptor<BadgeModel>(
            predicate: #Predicate { $0.badgeKey == localKey }
        ))
        return models.first?.toDomain()
    }

    func save(_ badge: Badge) throws {
        let localKey = badge.badgeKey
        let existing = try context.fetch(FetchDescriptor<BadgeModel>(
            predicate: #Predicate { $0.badgeKey == localKey }
        )).first
        if existing == nil {
            context.insert(BadgeModel(from: badge))
            try context.save()
        }
    }
}

final class SwiftDataXPTransactionRepository: XPTransactionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [XPTransaction] {
        let models = try context.fetch(FetchDescriptor<XPTransactionModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        ))
        return models.map { $0.toDomain() }
    }

    func fetchRecent(limit: Int) throws -> [XPTransaction] {
        var descriptor = FetchDescriptor<XPTransactionModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let models = try context.fetch(descriptor)
        return models.map { $0.toDomain() }
    }

    func save(_ transaction: XPTransaction) throws {
        context.insert(XPTransactionModel(from: transaction))
        try context.save()
    }
}

final class SwiftDataShopItemRepository: ShopItemRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [ShopItem] {
        let models = try context.fetch(FetchDescriptor<ShopItemModel>(
            sortBy: [SortDescriptor(\.purchasedAt, order: .reverse)]
        ))
        return models.map { $0.toDomain() }
    }

    func fetchActive(type: FixedShopItemType) throws -> [ShopItem] {
        let localType = type.rawValue
        let models = try context.fetch(FetchDescriptor<ShopItemModel>(
            predicate: #Predicate { $0.itemTypeRaw == localType && $0.usedAt == nil }
        ))
        return models.map { $0.toDomain() }
    }

    func save(_ item: ShopItem) throws {
        let localId = item.id
        let existing = try context.fetch(FetchDescriptor<ShopItemModel>(
            predicate: #Predicate { $0.id == localId }
        )).first
        if let existing {
            existing.update(from: item)
        } else {
            context.insert(ShopItemModel(from: item))
        }
        try context.save()
    }
}

final class SwiftDataCustomRewardRepository: CustomRewardRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [CustomReward] {
        let models = try context.fetch(FetchDescriptor<CustomRewardModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        ))
        return models.map { $0.toDomain() }
    }

    func fetchAll(categoryId: UUID?) throws -> [CustomReward] {
        let models: [CustomRewardModel]
        if let categoryId {
            let localCatId = categoryId
            models = try context.fetch(FetchDescriptor<CustomRewardModel>(
                predicate: #Predicate { $0.categoryId == localCatId },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            ))
        } else {
            models = try context.fetch(FetchDescriptor<CustomRewardModel>(
                predicate: #Predicate { $0.categoryId == nil },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            ))
        }
        return models.map { $0.toDomain() }
    }

    func fetch(id: UUID) throws -> CustomReward? {
        let localId = id
        let models = try context.fetch(FetchDescriptor<CustomRewardModel>(
            predicate: #Predicate { $0.id == localId }
        ))
        return models.first?.toDomain()
    }

    func save(_ reward: CustomReward) throws {
        let localId = reward.id
        let existing = try context.fetch(FetchDescriptor<CustomRewardModel>(
            predicate: #Predicate { $0.id == localId }
        )).first
        if let existing {
            existing.update(from: reward)
        } else {
            context.insert(CustomRewardModel(from: reward))
        }
        try context.save()
    }

    func delete(id: UUID) throws {
        let localId = id
        let models = try context.fetch(FetchDescriptor<CustomRewardModel>(
            predicate: #Predicate { $0.id == localId }
        ))
        guard let existing = models.first else { return }
        
        // Locked rewards for active month cannot be deleted mid-month
        if existing.isLocked {
            let cal = Calendar.current
            let now = Date()
            let isCurrentMonth = cal.isDate(existing.targetMonth, equalTo: now, toGranularity: .month)
            if isCurrentMonth {
                return
            }
        }
        
        context.delete(existing)
        try context.save()
    }
}

