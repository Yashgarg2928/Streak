// Application/UseCases/Notifications/SpicyNotificationScheduler.swift
// Schedules one-shot notifications for the current and next active day from live data.
// Called (debounced) after every data change via AppEnvironment.syncWidgets(), so the
// streak count and pending tasks in each message are always current, and the mid-day /
// cutoff warnings disappear once the day is done.

import Foundation
import UserNotifications

enum SpicyNotificationScheduler {
    private static let identifierPrefix = "streak."
    private static let aiCacheKey = "aiNotificationCache"
    private static var pendingRefresh: Swift.Task<Void, Never>?

    /// Coalesces bursts of data changes into a single reschedule.
    static func scheduleRefresh(env: AppEnvironment) {
        pendingRefresh?.cancel()
        pendingRefresh = Swift.Task { @MainActor in
            try? await Swift.Task.sleep(for: .seconds(1))
            guard !Swift.Task.isCancelled else { return }
            await reschedule(env: env)
        }
    }

    /// Rebuilds all Streak notifications. Pass `requestPermission` from user-initiated flows only.
    static func reschedule(env: AppEnvironment, requestPermission: Bool = false) async {
        let center = UNUserNotificationCenter.current()

        if requestPermission {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
        )

        let settings = env.settingsRepository
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: ActiveDayResolver.resolveActiveDate(for: now, settings: settings))
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!

        let profile = (try? env.playerProfileRepository.fetchProfile()) ?? PlayerProfile()
        let streak = (try? CalculateStreakUseCase(
            dayEntryRepository: env.dayEntryRepository,
            settingsRepository: settings
        ).execute(categoryId: nil)) ?? 0
        let habitTitles = (try? env.habitRoutineRepository.fetchActive(for: today))?.map(\.title) ?? []

        var requests: [UNNotificationRequest] = []

        for day in [today, tomorrow] {
            let isRestDay = ActiveDayResolver.isRestDay(day, settings: settings)
            let status = (try? env.dayEntryRepository.fetch(date: day, categoryId: nil))?.status
            let isSettled = status == .green || status == .frozen || status == .rest
            let deadline = ActiveDayResolver.planningDeadline(for: day, settings: settings)
            let pendingCount = ((try? env.taskRepository.fetchAll(for: day)) ?? [])
                .filter { !$0.isDeleted && $0.timeframe == .daily && !$0.isCompleted && !$0.isAddedLate(planningDeadline: deadline) }
                .count

            var touchpoints: [(NotificationTouchpoint, Date)] = []

            if settings.isMorningHypeEnabled && !isRestDay, let at = cal.date(bySettingHour: 8, minute: 0, second: 0, of: day) {
                touchpoints.append((.morningHype, at))
            }
            if settings.isMiddayNudgeEnabled && !isRestDay && !isSettled,
               let at = cal.date(bySettingHour: 15, minute: 0, second: 0, of: day) {
                touchpoints.append((.middayNudge, at))
            }
            if settings.isEmergencyCutoffEnabled && !isRestDay && !isSettled {
                let dayEnd = ActiveDayResolver.activeDayDeadline(for: day, settings: settings)
                touchpoints.append((.emergencyCutoff, dayEnd.addingTimeInterval(-3600)))
            }
            if settings.isPlanningAlertEnabled,
               let at = cal.date(bySettingHour: settings.planningReminderHour, minute: settings.planningReminderMinute, second: 0, of: day) {
                // Skip when the following day already has tasks planned.
                let nextDay = cal.date(byAdding: .day, value: 1, to: day)!
                let nextDayPlanned = ((try? env.taskRepository.fetchAll(for: nextDay)) ?? [])
                    .contains { !$0.isDeleted && $0.timeframe == .daily }
                if !nextDayPlanned || day == tomorrow {
                    touchpoints.append((.planningAlert, at))
                }
            }

            for (touchpoint, fireDate) in touchpoints where fireDate > now {
                let message = await message(
                    for: touchpoint, day: day, settings: settings, profile: profile,
                    streak: streak, pendingCount: pendingCount, habitTitles: habitTitles
                )
                let content = UNMutableNotificationContent()
                content.title = message.title
                content.body = message.body
                content.sound = .default

                let components = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                requests.append(UNNotificationRequest(
                    identifier: identifier(touchpoint, day: day),
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                ))
            }
        }

        for request in requests {
            try? await center.add(request)
        }
    }

    // MARK: - Messages

    private static func message(
        for touchpoint: NotificationTouchpoint,
        day: Date,
        settings: SettingsRepository,
        profile: PlayerProfile,
        streak: Int,
        pendingCount: Int,
        habitTitles: [String]
    ) async -> NotificationMessage {
        let persona = settings.notificationPersona
        let apiKey = settings.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        if settings.isAiNotificationsEnabled && !apiKey.isEmpty {
            // At most one AI call per touchpoint per day; the result is cached.
            let cacheKey = "\(identifier(touchpoint, day: day))|\(persona)"
            if let cached = cachedMessage(for: cacheKey) {
                return cached
            }
            if let generated = await GeminiNotificationService.shared.generateDynamicNotification(
                apiKey: apiKey,
                persona: persona,
                streak: streak,
                level: profile.currentLevel,
                title: profile.currentTitle.name,
                habitTitles: habitTitles,
                touchpoint: touchpoint
            ) {
                cache(generated, for: cacheKey)
                return generated
            }
        }

        return SpicyNotificationTemplates.message(
            for: touchpoint,
            persona: persona,
            streak: streak,
            level: profile.currentLevel,
            title: profile.currentTitle.name,
            pendingTasksCount: pendingCount
        )
    }

    private static func identifier(_ touchpoint: NotificationTouchpoint, day: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return "\(identifierPrefix)\(touchpoint).\(formatter.string(from: day))"
    }

    private static func cachedMessage(for key: String) -> NotificationMessage? {
        let cache = UserDefaults.standard.dictionary(forKey: aiCacheKey) as? [String: [String]] ?? [:]
        guard let pair = cache[key], pair.count == 2 else { return nil }
        return NotificationMessage(title: pair[0], body: pair[1])
    }

    private static func cache(_ message: NotificationMessage, for key: String) {
        var cache = UserDefaults.standard.dictionary(forKey: aiCacheKey) as? [String: [String]] ?? [:]
        cache[key] = [message.title, message.body]
        // Keep the cache small: only the most recent entries survive.
        if cache.count > 32 {
            let byDay = cache.keys.sorted { $0.split(separator: "|")[0].suffix(10) < $1.split(separator: "|")[0].suffix(10) }
            for staleKey in byDay.prefix(cache.count - 32) {
                cache.removeValue(forKey: staleKey)
            }
        }
        UserDefaults.standard.set(cache, forKey: aiCacheKey)
    }
}
