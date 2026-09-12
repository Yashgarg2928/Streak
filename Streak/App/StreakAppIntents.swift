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
        .daily: "Daily",
        .todo: "To-Do",
        .weekly: "Weekly",
        .monthly: "Monthly"
    ]
}

// MARK: - Primary Add Task Intent

struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task to Streak"
    static var description = IntentDescription("Adds a new task to your Daily checklist or To-Do backlog in Streak.")

    @Parameter(title: "Task Title", requestValueDialog: "What task would you like to add?")
    var title: String

    @Parameter(title: "List Type", default: .daily, requestValueDialog: "Should I add this to Daily or To-Do?")
    var listType: TaskListTypeAppEnum

    @Parameter(title: "Category", default: nil)
    var category: CategoryAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$title) to \(\.$listType)") {
            \.$category
        }
    }

    @MainActor
    func perform() async throws -> some ProvidesDialog & ShowsSnippetView {
        let container = try ModelContainerFactory.makeContainer()
        let ctx = container.mainContext
        let settingsRepo = UserDefaultsSettingsRepository()

        let activeToday = settingsRepo.isOnboardingCompleted
            ? ActiveDayResolver.resolveActiveDate(for: Date(), settings: settingsRepo)
            : Calendar.current.startOfDay(for: Date())

        let timeframe: TaskTimeframe
        let targetDate: Date
        switch listType {
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
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
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

        let destinationName = listType == .todo ? "To-Do list" : "\(listType.rawValue) tasks"
        let dialogText = "Added '\(title)' to your \(destinationName) in Streak!"

        return .result(
            dialog: IntentDialog(stringLiteral: dialogText),
            view: TaskAddedSiriSnippetView(
                taskTitle: title,
                listType: listType.rawValue,
                categoryName: category?.name,
                categoryColorHex: category?.colorHex
            )
        )
    }
}

// MARK: - Direct Add Daily Task Intent

struct AddDailyTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Daily Task to Streak"
    static var description = IntentDescription("Quickly adds a daily task to today's active checklist in Streak.")

    @Parameter(title: "Task Title", requestValueDialog: "What daily task would you like to add?")
    var title: String

    @Parameter(title: "Category", default: nil)
    var category: CategoryAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Add daily task \(\.$title)") {
            \.$category
        }
    }

    @MainActor
    func perform() async throws -> some ProvidesDialog & ShowsSnippetView {
        let taskIntent = AddTaskIntent()
        taskIntent.title = title
        taskIntent.listType = .daily
        taskIntent.category = category
        return try await taskIntent.perform()
    }
}

// MARK: - Direct Add To-Do Intent

struct AddTodoTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add To-Do to Streak"
    static var description = IntentDescription("Quickly adds an item to your To-Do list (backlog) in Streak.")

    @Parameter(title: "Task Title", requestValueDialog: "What would you like to add to your To-Do list?")
    var title: String

    @Parameter(title: "Category", default: nil)
    var category: CategoryAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Add to-do \(\.$title)") {
            \.$category
        }
    }

    @MainActor
    func perform() async throws -> some ProvidesDialog & ShowsSnippetView {
        let taskIntent = AddTaskIntent()
        taskIntent.title = title
        taskIntent.listType = .todo
        taskIntent.category = category
        return try await taskIntent.perform()
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
                "Add to do in \(.applicationName)"
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

    private var categoryColor: Color {
        if let hex = categoryColorHex {
            return Color(hex: hex)
        }
        return Color(hex: "#999999")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(Color(hex: "#2D7A2D"))

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
