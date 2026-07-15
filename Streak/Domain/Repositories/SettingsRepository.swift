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
    
    func saveAll()
}
