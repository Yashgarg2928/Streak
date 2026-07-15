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
            Keys.timezoneGraceExtension: 0.0
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
    
    public func saveAll() {
        // UserDefaults automatically saves, but we can call synchronize for instant write verification.
        defaults.synchronize()
    }
}
