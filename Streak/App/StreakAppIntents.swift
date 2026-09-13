// App/StreakAppIntents.swift
// Siri & Shortcuts integration using modern AppIntents framework.

import Foundation
import AppIntents
import SwiftUI
import SwiftData

// MARK: - App Enum for List Types

enum TaskListTypeAppEnum: String, AppEnum {
    case daily = "Daily"
    case todo = "To-Do"
    case weekly = "Weekly"
    case monthly = "Monthly"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "List Type"
    static var caseDisplayRepresentations: [TaskListTypeAppEnum: DisplayRepresentation] = [
        .daily: DisplayRepresentation(
            title: "Daily",
            synonyms: ["daily", "today", "daily list", "daily task", "today's list", "day"]
        ),
        .todo: DisplayRepresentation(
            title: "To-Do",
            synonyms: [
                "to-do",
                "todo",
                "to do",
                "to-do list",
                "todo list",
                "to do list",
                "the to-do list",
                "the to do list",
                "backlog",
                "reminders",
                "ideas"
            ]
        ),
        .weekly: DisplayRepresentation(
            title: "Weekly",
            synonyms: ["weekly", "this week", "weekly list", "week"]
        ),
        .monthly: DisplayRepresentation(
            title: "Monthly",
            synonyms: ["monthly", "this month", "monthly list", "month"]
        )
    ]
}

// MARK: - Shared Intent Service

enum StreakTaskIntentService {
    @MainActor
    static func executeAddTask(
        rawTitle: String,
        suggestedListType: TaskListTypeAppEnum,
        category: CategoryAppEntity?
    ) throws -> (dialog: String, snippet: TaskAddedSiriSnippetView) {
        let container = try ModelContainerFactory.makeContainer()
        let ctx = container.mainContext
        let settingsRepo = UserDefaultsSettingsRepository()

        let activeToday = settingsRepo.isOnboardingCompleted
            ? ActiveDayResolver.resolveActiveDate(for: Date(), settings: settingsRepo)
            : Calendar.current.startOfDay(for: Date())

        var title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        var resolvedListType = suggestedListType

        // Check if user spoke the destination inside the task title itself
        let todoSuffixes = [
            " to my to-do list", " to the to-do list", " to to-do list", " to to-do",
            " to my todo list", " to the todo list", " to todo list", " to todo",
            " to my to do list", " to the to do list", " to to do list", " to to do",
            " in my to-do list", " in the to-do list", " in to-do list", " in to-do",
            " in my todo list", " in the todo list", " in todo list", " in todo",
            " in my to do list", " in the to do list", " in to do list", " in to do",
            " on my to-do list", " on the to-do list", " on to-do list", " on to-do",
            " on my todo list", " on the todo list", " on todo list", " on todo",
            " on my to do list", " on the to do list", " on to do list", " on to do"
        ]

        for suffix in todoSuffixes {
            if title.lowercased().hasSuffix(suffix) {
                resolvedListType = .todo
                let endIndex = title.index(title.endIndex, offsetBy: -suffix.count)
                title = String(title[..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }

        let dailySuffixes = [
            " to my daily list", " to the daily list", " to daily list", " to daily tasks", " to daily task", " to daily",
            " in my daily list", " in the daily list", " in daily list", " in daily tasks", " in daily task", " in daily",
            " on my daily list", " on the daily list", " on daily list", " on daily tasks", " on daily task", " on daily"
        ]

        for suffix in dailySuffixes {
            if title.lowercased().hasSuffix(suffix) {
                resolvedListType = .daily
                let endIndex = title.index(title.endIndex, offsetBy: -suffix.count)
                title = String(title[..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }

        let finalTitle = title.isEmpty ? rawTitle : title
        let timeframe: TaskTimeframe
        let targetDate: Date
        switch resolvedListType {
        case .daily:
            timeframe = .daily
            targetDate = activeToday
        case .todo:
            timeframe = .backlog
            targetDate = activeToday
        case .weekly:
            timeframe = .weekly
            targetDate = activeToday
        case .monthly:
            timeframe = .monthly
            targetDate = activeToday
        }

        let catId: UUID? = category != nil ? UUID(uuidString: category!.id) : nil

        let newTask = Task(
            title: finalTitle,
            categoryId: catId,
            targetDate: targetDate,
            timeframe: timeframe
        )

        let model = TaskModel(from: newTask)
        ctx.insert(model)
        try ctx.save()

        // Sync widget data immediately so widgets reflect the new task
        let taskRepo = SwiftDataTaskRepository(context: ctx)
        let dayEntryRepo = SwiftDataDayEntryRepository(context: ctx)
        let catRepo = SwiftDataCategoryRepository(context: ctx)
        let goalRepo = SwiftDataGoalRepository(context: ctx)
        let routineRepo = SwiftDataHabitRoutineRepository(context: ctx)
        let syncUseCase = SyncWidgetDataUseCase(
            categoryRepository: catRepo,
            taskRepository: taskRepo,
            dayEntryRepository: dayEntryRepo,
            goalRepository: goalRepo,
            settingsRepository: settingsRepo,
            habitRoutineRepository: routineRepo
        )
        _ = syncUseCase.execute()

        let destinationName = resolvedListType == .todo ? "To-Do list" : "\(resolvedListType.rawValue) tasks"
        let dialogText = "Added '\(finalTitle)' to your \(destinationName) in Streak!"

        let snippet = TaskAddedSiriSnippetView(
            taskTitle: finalTitle,
            listType: resolvedListType.rawValue,
            categoryName: category?.name,
            categoryColorHex: category?.colorHex
        )

        return (dialogText, snippet)
    }
}

// MARK: - Primary Add Task Intent

struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task to Streak"
    static var description = IntentDescription("Adds a new task to your Daily checklist or To-Do backlog in Streak.")

    @Parameter(title: "Task Title", requestValueDialog: "What task would you like to add?")
    var title: String

    @Parameter(title: "List Type", default: .daily, requestValueDialog: "Should I add this to Daily or To-Do?")
    var listType: TaskListTypeAppEnum

    @Parameter(title: "Category", requestValueDialog: "Which category should this go in?")
    var category: CategoryAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$title) to \(\.$listType)") {
            \.$category
        }
    }

    @MainActor
    func perform() async throws -> some ProvidesDialog & ShowsSnippetView {
        // Step 1: If no category was provided, ask the user to pick one
        let resolvedCategory: CategoryAppEntity?
        if category == nil {
            let available = try await CategoryEntityQuery().suggestedEntities()
            if !available.isEmpty {
                resolvedCategory = try await $category.requestDisambiguation(
                    among: available,
                    dialog: IntentDialog("Which category should this task go in?")
                )
            } else {
                resolvedCategory = nil
            }
        } else {
            resolvedCategory = category
        }

        // Step 2: Confirmation — Siri reads back what it captured
        let listName = listType == .todo ? "To-Do list" : "\(listType.rawValue) tasks"
        let catLabel = resolvedCategory?.name ?? "No Category"
        let confirmDialog = "I'll add \"\(title)\" to your \(listName) under \(catLabel). Sound good?"

        try await requestConfirmation(
            result: .result(
                dialog: IntentDialog(stringLiteral: confirmDialog),
                view: TaskAddedSiriSnippetView(
                    taskTitle: title,
                    listType: listType.rawValue,
                    categoryName: resolvedCategory?.name,
                    categoryColorHex: resolvedCategory?.colorHex,
                    isPreview: true
                )
            )
        )

        // Step 3: Execute the task creation
        let result = try StreakTaskIntentService.executeAddTask(
            rawTitle: title,
            suggestedListType: listType,
            category: resolvedCategory
        )
        return .result(
            dialog: IntentDialog(stringLiteral: result.dialog),
            view: result.snippet
        )
    }
}

// MARK: - Direct Add Daily Task Intent

struct AddDailyTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Daily Task to Streak"
    static var description = IntentDescription("Quickly adds a daily task to today's active checklist in Streak.")

    @Parameter(title: "Task Title", requestValueDialog: "What daily task would you like to add?")
    var title: String

    @Parameter(title: "Category", requestValueDialog: "Which category should this go in?")
    var category: CategoryAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Add daily task \(\.$title)") {
            \.$category
        }
    }

    @MainActor
    func perform() async throws -> some ProvidesDialog & ShowsSnippetView {
        // Ask for category if not provided
        let resolvedCategory: CategoryAppEntity?
        if category == nil {
            let available = try await CategoryEntityQuery().suggestedEntities()
            if !available.isEmpty {
                resolvedCategory = try await $category.requestDisambiguation(
                    among: available,
                    dialog: IntentDialog("Which category for this daily task?")
                )
            } else {
                resolvedCategory = nil
            }
        } else {
            resolvedCategory = category
        }

        // Confirmation
        let catLabel = resolvedCategory?.name ?? "No Category"
        let confirmDialog = "I'll add \"\(title)\" to your Daily tasks under \(catLabel). Sound good?"

        try await requestConfirmation(
            result: .result(
                dialog: IntentDialog(stringLiteral: confirmDialog),
                view: TaskAddedSiriSnippetView(
                    taskTitle: title,
                    listType: "Daily",
                    categoryName: resolvedCategory?.name,
                    categoryColorHex: resolvedCategory?.colorHex,
                    isPreview: true
                )
            )
        )

        let result = try StreakTaskIntentService.executeAddTask(
            rawTitle: title,
            suggestedListType: .daily,
            category: resolvedCategory
        )
        return .result(
            dialog: IntentDialog(stringLiteral: result.dialog),
            view: result.snippet
        )
    }
}

// MARK: - Direct Add To-Do Intent

struct AddTodoTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add To-Do to Streak"
    static var description = IntentDescription("Quickly adds an item to your To-Do list (backlog) in Streak.")

    @Parameter(title: "Task Title", requestValueDialog: "What would you like to add to your To-Do list?")
    var title: String

    @Parameter(title: "Category", requestValueDialog: "Which category should this go in?")
    var category: CategoryAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Add to-do \(\.$title)") {
            \.$category
        }
    }

    @MainActor
    func perform() async throws -> some ProvidesDialog & ShowsSnippetView {
        // Ask for category if not provided
        let resolvedCategory: CategoryAppEntity?
        if category == nil {
            let available = try await CategoryEntityQuery().suggestedEntities()
            if !available.isEmpty {
                resolvedCategory = try await $category.requestDisambiguation(
                    among: available,
                    dialog: IntentDialog("Which category for this to-do?")
                )
            } else {
                resolvedCategory = nil
            }
        } else {
            resolvedCategory = category
        }

        // Confirmation
        let catLabel = resolvedCategory?.name ?? "No Category"
        let confirmDialog = "I'll add \"\(title)\" to your To-Do list under \(catLabel). Sound good?"

        try await requestConfirmation(
            result: .result(
                dialog: IntentDialog(stringLiteral: confirmDialog),
                view: TaskAddedSiriSnippetView(
                    taskTitle: title,
                    listType: "To-Do",
                    categoryName: resolvedCategory?.name,
                    categoryColorHex: resolvedCategory?.colorHex,
                    isPreview: true
                )
            )
        )

        let result = try StreakTaskIntentService.executeAddTask(
            rawTitle: title,
            suggestedListType: .todo,
            category: resolvedCategory
        )
        return .result(
            dialog: IntentDialog(stringLiteral: result.dialog),
            view: result.snippet
        )
    }
}

// MARK: - App Shortcuts Provider for Siri & Shortcuts App

struct StreakAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Add task to \(.applicationName)",
                "Add task in \(.applicationName)",
                "Add a task to \(.applicationName)",
                "Add a task in \(.applicationName)",
                "Add to \(\.$listType) in \(.applicationName)",
                "Add task to \(\.$listType) in \(.applicationName)"
            ],
            shortTitle: "Add Task",
            systemImageName: "checkmark.circle.fill"
        )

        AppShortcut(
            intent: AddDailyTaskIntent(),
            phrases: [
                "Add daily task to \(.applicationName)",
                "Add daily task in \(.applicationName)",
                "Add a daily task to \(.applicationName)",
                "Add a daily task in \(.applicationName)"
            ],
            shortTitle: "Add Daily Task",
            systemImageName: "sun.max.fill"
        )

        AppShortcut(
            intent: AddTodoTaskIntent(),
            phrases: [
                "Add to-do to \(.applicationName)",
                "Add to-do in \(.applicationName)",
                "Add a to-do to \(.applicationName)",
                "Add a to-do in \(.applicationName)",
                "Add to do to \(.applicationName)",
                "Add to do in \(.applicationName)",
                "Add to-do list in \(.applicationName)",
                "Add to-do list to \(.applicationName)",
                "Add to the to-do list in \(.applicationName)",
                "Add to the to-do list to \(.applicationName)",
                "Add to the to do list in \(.applicationName)",
                "Add to the to do list to \(.applicationName)",
                "Add to do list in \(.applicationName)",
                "Add to do list to \(.applicationName)"
            ],
            shortTitle: "Add To-Do",
            systemImageName: "list.bullet"
        )
    }
}

// MARK: - Visual Snippet View shown in Siri UI

struct TaskAddedSiriSnippetView: View {
    let taskTitle: String
    let listType: String
    var categoryName: String? = nil
    var categoryColorHex: String? = nil
    var isPreview: Bool = false

    private var categoryColor: Color {
        if let hex = categoryColorHex {
            return Color(hex: hex)
        }
        return Color(hex: "#999999")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isPreview ? "questionmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(Color(hex: isPreview ? "#E6A817" : "#2D7A2D"))

            VStack(alignment: .leading, spacing: 4) {
                Text(taskTitle)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#1A1A1A"))
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(listType.uppercased())
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#1A1A1A"))
                        .foregroundStyle(Color(hex: "#F5F0E8"))
                        .clipShape(RoundedRectangle(cornerRadius: 3))

                    if let categoryName {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(categoryColor)
                                .frame(width: 8, height: 8)
                            Text(categoryName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "#4A4A4A"))
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color(hex: "#F5F0E8"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "#1A1A1A"), lineWidth: 2)
        )
        .padding(6)
    }
}
