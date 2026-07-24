// Domain/Repositories/SettingsRepository.swift

import Foundation

public protocol SettingsRepository: AnyObject {
    var activeDayStartHour: Int { get set }
    var activeDayStartMinute: Int { get set }
    var activeDayEndHour: Int { get set }
    var activeDayEndMinute: Int { get set }
    
    var planningReminderHour: Int { get set }
    var planningReminderMinute: Int { get set }
    
    var dailyAssistHour: Int { get set }
    var dailyAssistMinute: Int { get set }
    
    var isInterCalendarEnabled: Bool { get set }
    var planningWindowMode: String { get set }
    var planningDeadlineHour: Int { get set }
    var planningDeadlineMinute: Int { get set }
    
    var isOnboardingCompleted: Bool { get set }
    
    var lastKnownTimeZone: String? { get set }
    var timezoneGraceExtension: Double { get set }
    var themeMode: String { get set }
    
    // Spicy & Gemini AI Notifications
    var isAiNotificationsEnabled: Bool { get set }
    var geminiApiKey: String { get set }
    var notificationPersona: String { get set }
    var spicinessLevel: String { get set }
    var isMorningHypeEnabled: Bool { get set }
    var isMiddayNudgeEnabled: Bool { get set }
    var isPlanningAlertEnabled: Bool { get set }
    var isEmergencyCutoffEnabled: Bool { get set }

    func saveAll()
    func resetAll()
}
