// StreakWidgets/ToggleWidgetTaskIntent.swift
// Checkbox tap in the Tasks widget. The widget can't open the app's database, so it
// updates its cached copy right away and queues the change; the app applies it through
// the normal completion flow (status, XP, goals) the next time it runs.

import AppIntents
import WidgetKit

struct ToggleWidgetTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Task"
    static let isDiscoverable = false

    @Parameter(title: "Task ID") var taskId: String
    @Parameter(title: "Completed") var completed: Bool

    init() {}

    init(taskId: String, completed: Bool) {
        self.taskId = taskId
        self.completed = completed
    }

    func perform() async throws -> some IntentResult {
        WidgetTaskToggleQueue.enqueue(taskId: taskId, completed: completed)
        if var data = WidgetDataStore.load(),
           let index = data.taskItems.firstIndex(where: { $0.id == taskId }) {
            data.taskItems[index].isCompleted = completed
            data.tasksToday.completed = data.taskItems.filter(\.isCompleted).count
            WidgetDataStore.save(data)
        }
        return .result()
    }
}
