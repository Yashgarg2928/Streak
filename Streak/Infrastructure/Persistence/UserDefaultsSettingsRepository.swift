// Infrastructure/Persistence/UserDefaultsSettingsRepository.swift

import Foundation

public final class UserDefaultsSettingsRepository: SettingsRepository {
    private let defaults: UserDefaults
    
    private enum Keys {
        static let activeDayStartHour = "activeDayStartHour"
        static let activeDayStartMinute = "activeDayStartMinute"
        static let activeDayEndHour = "activeDayEndHour"
        static let activeDayEndMinute = "activeDayEndMinute"
        
        static let planningReminderHour = "planningReminderHour"
        static let planningReminderMinute = "planningReminderMinute"
        
        static let dailyAssistHour = "dailyAssistHour"
        static let dailyAssistMinute = "dailyAssistMinute"
        
        static let isInterCalendarEnabled = "isInterCalendarEnabled"
        static let planningWindowMode = "planningWindowMode"
        static let planningDeadlineHour = "planningDeadlineHour"
        static let planningDeadlineMinute = "planningDeadlineMinute"
        
        static let isOnboardingCompleted = "isOnboardingCompleted"
        
        static let lastKnownTimeZone = "lastKnownTimeZone"
        static let timezoneGraceExtension = "timezoneGraceExtension"
        static let themeMode = "themeMode"
        
        static let isAiNotificationsEnabled = "isAiNotificationsEnabled"
        static let geminiApiKey = "geminiApiKey"
        static let notificationPersona = "notificationPersona"
        static let spicinessLevel = "spicinessLevel"
        static let isMorningHypeEnabled = "isMorningHypeEnabled"
        static let isMiddayNudgeEnabled = "isMiddayNudgeEnabled"
        static let isPlanningAlertEnabled = "isPlanningAlertEnabled"
        static let isEmergencyCutoffEnabled = "isEmergencyCutoffEnabled"
    }
    
    public init() {
        let appGroupID = "group.com.madhvan.streak"
        self.defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        
        // Register default values
        defaults.register(defaults: [
            Keys.activeDayStartHour: 7,
            Keys.activeDayStartMinute: 0,
            Keys.activeDayEndHour: 23,
            Keys.activeDayEndMinute: 30,
            Keys.planningReminderHour: 22,
            Keys.planningReminderMinute: 0,
            Keys.dailyAssistHour: 22,
            Keys.dailyAssistMinute: 30,
            Keys.isInterCalendarEnabled: true,
            Keys.planningWindowMode: "currentDay",
            Keys.planningDeadlineHour: 10,
            Keys.planningDeadlineMinute: 0,
            Keys.isOnboardingCompleted: false,
            Keys.timezoneGraceExtension: 0.0,
            Keys.themeMode: "system",
            Keys.isAiNotificationsEnabled: false,
            Keys.geminiApiKey: "",
            Keys.notificationPersona: "savage",
            Keys.spicinessLevel: "spicy",
            Keys.isMorningHypeEnabled: true,
            Keys.isMiddayNudgeEnabled: true,
            Keys.isPlanningAlertEnabled: true,
            Keys.isEmergencyCutoffEnabled: true
        ])
    }
    
    public var activeDayStartHour: Int {
        get { defaults.integer(forKey: Keys.activeDayStartHour) }
        set { defaults.set(newValue, forKey: Keys.activeDayStartHour) }
    }
    
    public var activeDayStartMinute: Int {
        get { defaults.integer(forKey: Keys.activeDayStartMinute) }
        set { defaults.set(newValue, forKey: Keys.activeDayStartMinute) }
    }
    
    public var activeDayEndHour: Int {
        get { defaults.integer(forKey: Keys.activeDayEndHour) }
        set { defaults.set(newValue, forKey: Keys.activeDayEndHour) }
    }
    
    public var activeDayEndMinute: Int {
        get { defaults.integer(forKey: Keys.activeDayEndMinute) }
        set { defaults.set(newValue, forKey: Keys.activeDayEndMinute) }
    }
    
    public var planningReminderHour: Int {
        get { defaults.integer(forKey: Keys.planningReminderHour) }
        set { defaults.set(newValue, forKey: Keys.planningReminderHour) }
    }
    
    public var planningReminderMinute: Int {
        get { defaults.integer(forKey: Keys.planningReminderMinute) }
        set { defaults.set(newValue, forKey: Keys.planningReminderMinute) }
    }
    
    public var dailyAssistHour: Int {
        get { defaults.integer(forKey: Keys.dailyAssistHour) }
        set { defaults.set(newValue, forKey: Keys.dailyAssistHour) }
    }
    
    public var dailyAssistMinute: Int {
        get { defaults.integer(forKey: Keys.dailyAssistMinute) }
        set { defaults.set(newValue, forKey: Keys.dailyAssistMinute) }
    }
    
    public var isInterCalendarEnabled: Bool {
        get { defaults.bool(forKey: Keys.isInterCalendarEnabled) }
        set { defaults.set(newValue, forKey: Keys.isInterCalendarEnabled) }
    }
    
    public var planningWindowMode: String {
        get { defaults.string(forKey: Keys.planningWindowMode) ?? "currentDay" }
        set { defaults.set(newValue, forKey: Keys.planningWindowMode) }
    }
    
    public var planningDeadlineHour: Int {
        get { defaults.integer(forKey: Keys.planningDeadlineHour) }
        set { defaults.set(newValue, forKey: Keys.planningDeadlineHour) }
    }
    
    public var planningDeadlineMinute: Int {
        get { defaults.integer(forKey: Keys.planningDeadlineMinute) }
        set { defaults.set(newValue, forKey: Keys.planningDeadlineMinute) }
    }
    
    public var isOnboardingCompleted: Bool {
        get { defaults.bool(forKey: Keys.isOnboardingCompleted) }
        set { defaults.set(newValue, forKey: Keys.isOnboardingCompleted) }
    }
    
    public var lastKnownTimeZone: String? {
        get { defaults.string(forKey: Keys.lastKnownTimeZone) }
        set { defaults.set(newValue, forKey: Keys.lastKnownTimeZone) }
    }
    
    public var timezoneGraceExtension: Double {
        get { defaults.double(forKey: Keys.timezoneGraceExtension) }
        set { defaults.set(newValue, forKey: Keys.timezoneGraceExtension) }
    }

    public var themeMode: String {
        get { defaults.string(forKey: Keys.themeMode) ?? "system" }
        set { defaults.set(newValue, forKey: Keys.themeMode) }
    }

    public var isAiNotificationsEnabled: Bool {
        get { defaults.bool(forKey: Keys.isAiNotificationsEnabled) }
        set { defaults.set(newValue, forKey: Keys.isAiNotificationsEnabled) }
    }

    public var geminiApiKey: String {
        get { defaults.string(forKey: Keys.geminiApiKey) ?? "" }
        set { defaults.set(newValue, forKey: Keys.geminiApiKey) }
    }

    public var notificationPersona: String {
        get { defaults.string(forKey: Keys.notificationPersona) ?? "savage" }
        set { defaults.set(newValue, forKey: Keys.notificationPersona) }
    }

    public var spicinessLevel: String {
        get { defaults.string(forKey: Keys.spicinessLevel) ?? "spicy" }
        set { defaults.set(newValue, forKey: Keys.spicinessLevel) }
    }

    public var isMorningHypeEnabled: Bool {
        get { defaults.bool(forKey: Keys.isMorningHypeEnabled) }
        set { defaults.set(newValue, forKey: Keys.isMorningHypeEnabled) }
    }

    public var isMiddayNudgeEnabled: Bool {
        get { defaults.bool(forKey: Keys.isMiddayNudgeEnabled) }
        set { defaults.set(newValue, forKey: Keys.isMiddayNudgeEnabled) }
    }

    public var isPlanningAlertEnabled: Bool {
        get { defaults.bool(forKey: Keys.isPlanningAlertEnabled) }
        set { defaults.set(newValue, forKey: Keys.isPlanningAlertEnabled) }
    }

    public var isEmergencyCutoffEnabled: Bool {
        get { defaults.bool(forKey: Keys.isEmergencyCutoffEnabled) }
        set { defaults.set(newValue, forKey: Keys.isEmergencyCutoffEnabled) }
    }
    
    public func saveAll() {
        // UserDefaults automatically saves, but we can call synchronize for instant write verification.
        defaults.synchronize()
    }
    
    public func resetAll() {
        if let domain = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: domain)
        }
        defaults.removePersistentDomain(forName: "group.com.madhvan.streak")
        defaults.synchronize()
    }
}
