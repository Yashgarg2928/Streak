// Application/UseCases/Notifications/SpicyNotificationScheduler.swift

import Foundation
import UserNotifications

final class SpicyNotificationScheduler {
    static func reschedule(env: AppEnvironment) {
        let settings = env.settingsRepository
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            center.removeAllPendingNotificationRequests()

            let profile = (try? env.playerProfileRepository.fetchProfile()) ?? PlayerProfile()
            let streak = (try? CalculateStreakUseCase(dayEntryRepository: env.dayEntryRepository).execute(categoryId: nil)) ?? 0
            let today = ActiveDayResolver.resolveActiveDate(for: Date(), settings: settings)
            let tasks = (try? env.taskRepository.fetchAll(for: today)) ?? []
            let pendingTasks = tasks.filter { !$0.isCompleted }
            let habitTitles = (try? env.habitRoutineRepository.fetchAll())?.map(\.title) ?? []

            let persona = settings.notificationPersona
            let isAiEnabled = settings.isAiNotificationsEnabled
            let apiKey = settings.geminiApiKey

            Swift.Task {
                // 1. Morning Hype (8:00 AM)
                if settings.isMorningHypeEnabled {
                    await scheduleTouchpoint(
                        touchpoint: .morningHype,
                        hour: 8,
                        minute: 0,
                        id: "streak.morning-hype",
                        settings: settings,
                        profile: profile,
                        streak: streak,
                        pendingCount: pendingTasks.count,
                        habitTitles: habitTitles,
                        persona: persona,
                        isAiEnabled: isAiEnabled,
                        apiKey: apiKey
                    )
                }

                // 2. Midday Nudge (3:00 PM)
                if settings.isMiddayNudgeEnabled {
                    await scheduleTouchpoint(
                        touchpoint: .middayNudge,
                        hour: 15,
                        minute: 0,
                        id: "streak.midday-nudge",
                        settings: settings,
                        profile: profile,
                        streak: streak,
                        pendingCount: pendingTasks.count,
                        habitTitles: habitTitles,
                        persona: persona,
                        isAiEnabled: isAiEnabled,
                        apiKey: apiKey
                    )
                }

                // 3. Planning Alert (Configured Planning Hour/Min or 10:00 PM)
                if settings.isPlanningAlertEnabled {
                    let hour = settings.planningReminderHour
                    let min = settings.planningReminderMinute
                    await scheduleTouchpoint(
                        touchpoint: .planningAlert,
                        hour: hour,
                        minute: min,
                        id: "streak.planning-alert",
                        settings: settings,
                        profile: profile,
                        streak: streak,
                        pendingCount: pendingTasks.count,
                        habitTitles: habitTitles,
                        persona: persona,
                        isAiEnabled: isAiEnabled,
                        apiKey: apiKey
                    )
                }

                // 4. Emergency Cutoff (1 Hour Before Active Day End)
                if settings.isEmergencyCutoffEnabled {
                    let endHour = settings.activeDayEndHour
                    let cutoffHour = (endHour - 1 + 24) % 24
                    await scheduleTouchpoint(
                        touchpoint: .emergencyCutoff,
                        hour: cutoffHour,
                        minute: 0,
                        id: "streak.emergency-cutoff",
                        settings: settings,
                        profile: profile,
                        streak: streak,
                        pendingCount: pendingTasks.count,
                        habitTitles: habitTitles,
                        persona: persona,
                        isAiEnabled: isAiEnabled,
                        apiKey: apiKey
                    )
                }
            }
        }
    }

    private static func scheduleTouchpoint(
        touchpoint: NotificationTouchpoint,
        hour: Int,
        minute: Int,
        id: String,
        settings: SettingsRepository,
        profile: PlayerProfile,
        streak: Int,
        pendingCount: Int,
        habitTitles: [String],
        persona: String,
        isAiEnabled: Bool,
        apiKey: String
    ) async {
        var msg: NotificationMessage? = nil

        // Optional Gemini AI generation if enabled and key provided
        if isAiEnabled && !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            msg = await GeminiNotificationService.shared.generateDynamicNotification(
                apiKey: apiKey,
                persona: persona,
                streak: streak,
                level: profile.currentLevel,
                title: profile.currentTitle.name,
                habitTitles: habitTitles,
                touchpoint: touchpoint
            )
        }

        // Fallback to built-in spicy templates if AI is off or failed
        if msg == nil {
            msg = SpicyNotificationTemplates.message(
                for: touchpoint,
                persona: persona,
                streak: streak,
                level: profile.currentLevel,
                title: profile.currentTitle.name,
                pendingTasksCount: pendingCount
            )
        }

        guard let finalMsg = msg else { return }

        let content = UNMutableNotificationContent()
        content.title = finalMsg.title
        content.body = finalMsg.body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }
}
