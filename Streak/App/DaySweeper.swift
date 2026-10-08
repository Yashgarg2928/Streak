// App/DaySweeper.swift
// Brings stored day statuses up to date. Runs on launch, whenever the app returns to
// the foreground, and from the background lockout task:
//   1. applies task completions queued by the interactive Tasks widget
//   2. generates today's habit-commitment tasks (so they exist even if Tasks is never opened)
//      and ticks any whose Apple Health target is already met
//   3. finalizes every day that ended since the last sweep (XP decay + automatic Streak Freeze)
//   4. re-resolves today (planning-deadline lockout, rest days)
//   5. syncs goal progress, widgets, notifications and the Live Activity

import Foundation

enum DaySweeper {
    private static let lastActiveDateKey = "lastActiveDateString"
    /// Upper bound on how many missed days one sweep finalizes.
    private static let maxDaysToFinalize = 90

    static func run(env: AppEnvironment) {
        let settings = env.settingsRepository
        let cal = Calendar.current
        let today = cal.startOfDay(for: ActiveDayResolver.resolveActiveDate(for: Date(), settings: settings))

        applyQueuedWidgetToggles(env: env)

        _ = try? GenerateRoutineTasksUseCase(
            habitRoutineRepository: env.habitRoutineRepository,
            taskRepository: env.taskRepository
        ).execute(for: today)

        // Habits created after today's Health sync still get ticked.
        if let snapshot = try? env.healthSnapshotRepository.fetch(date: today) {
            _ = try? HealthSync.applyHealthRules(env: env, snapshot: snapshot)
        }

        let resolver = ResolveDayStatusUseCase(
            taskRepository: env.taskRepository,
            categoryRepository: env.categoryRepository,
            dayEntryRepository: env.dayEntryRepository,
            settingsRepository: settings,
            playerProfileRepository: env.playerProfileRepository,
            xpTransactionRepository: env.xpTransactionRepository,
            shopItemRepository: env.shopItemRepository
        )
        let categories = (try? env.categoryRepository.fetchActive()) ?? []

        func resolve(_ date: Date, allowAutoFreeze: Bool) {
            do {
                try resolver.execute(date: date, categoryId: nil, allowAutoFreeze: allowAutoFreeze)
                for category in categories {
                    try resolver.execute(date: date, categoryId: category.id)
                }
            } catch {
                print("Day sweep failed for \(date): \(error)")
            }
        }

        let defaults = UserDefaults(suiteName: AppConfig.appGroupID) ?? .standard
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        if let lastString = defaults.string(forKey: lastActiveDateKey),
           let lastActive = formatter.date(from: lastString).map({ cal.startOfDay(for: $0) }),
           lastActive < today {
            let earliest = cal.date(byAdding: .day, value: -maxDaysToFinalize, to: today) ?? lastActive
            var day = max(lastActive, earliest)
            while day < today {
                resolve(day, allowAutoFreeze: true)
                guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
        }
        defaults.set(formatter.string(from: today), forKey: lastActiveDateKey)

        resolve(today, allowAutoFreeze: false)

        try? SyncGoalProgressUseCase(
            goalRepository: env.goalRepository,
            dayEntryRepository: env.dayEntryRepository,
            taskRepository: env.taskRepository,
            settingsRepository: settings
        ).execute()

        env.syncWidgets()
    }

    private static func applyQueuedWidgetToggles(env: AppEnvironment) {
        for toggle in WidgetTaskToggleQueue.drain() {
            guard let id = UUID(uuidString: toggle.taskId) else { continue }
            do {
                try env.setTaskCompleted(id, completed: toggle.completed, syncAfterwards: false)
            } catch {
                print("Failed to apply widget toggle for \(toggle.taskId): \(error)")
            }
        }
    }
}
