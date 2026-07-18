// Domain/Services/ActiveDayResolver.swift

import Foundation

public final class ActiveDayResolver {
    public static func resolveActiveDate(for date: Date, settings: SettingsRepository) -> Date {
        let calendar = Calendar.current
        
        let endHour = settings.activeDayEndHour
        let endMinute = settings.activeDayEndMinute
        let startHour = settings.activeDayStartHour
        let startMinute = settings.activeDayStartMinute
        
        // Determine if end time crosses midnight relative to start time
        let endCrossesMidnight = (endHour < startHour) || (endHour == startHour && endMinute < startMinute)
        
        // Let's test "today" (calendar date of `date`) as the candidate active date
        let candidateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Build the deadline (End Boundary) for this candidate active date
        var deadlineComponents = candidateComponents
        deadlineComponents.hour = endHour
        deadlineComponents.minute = endMinute
        
        guard var candidateDeadline = calendar.date(from: deadlineComponents) else { return date }
        
        if endCrossesMidnight {
            // Deadline is on the next calendar day
            if let nextDayDeadline = calendar.date(byAdding: .day, value: 1, to: candidateDeadline) {
                candidateDeadline = nextDayDeadline
            }
        }
        
        // Apply timezone grace period extension if present
        let graceExtension = settings.timezoneGraceExtension
        if graceExtension > 0 {
            candidateDeadline = candidateDeadline.addingTimeInterval(graceExtension)
        }
        
        // If the current clock time is BEFORE the deadline of the candidate date,
        // then it belongs to the candidate date!
        if date <= candidateDeadline {
            // But wait! Is it before the START of the candidate date?
            // Calculate the previous day's deadline:
            var prevDeadlineComponents = calendar.dateComponents([.year, .month, .day], from: calendar.date(byAdding: .day, value: -1, to: date) ?? date)
            prevDeadlineComponents.hour = endHour
            prevDeadlineComponents.minute = endMinute
            if var prevDeadline = calendar.date(from: prevDeadlineComponents) {
                if endCrossesMidnight {
                    prevDeadline = calendar.date(byAdding: .day, value: 1, to: prevDeadline) ?? prevDeadline
                }
                if graceExtension > 0 {
                    prevDeadline = prevDeadline.addingTimeInterval(graceExtension)
                }
                if date <= prevDeadline {
                    // It is before yesterday's deadline, so it belongs to yesterday!
                    return calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: date) ?? date)
                }
            }
            
            return calendar.startOfDay(for: date)
        } else {
            // It is past today's deadline, so it belongs to tomorrow!
            return calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: date) ?? date)
        }
    }
    
    public static func planningDeadline(for activeDate: Date, settings: SettingsRepository) -> Date {
        let calendar = Calendar.current
        let deadlineHour = settings.planningDeadlineHour
        let deadlineMinute = settings.planningDeadlineMinute
        
        if settings.planningWindowMode == "currentDay" {
            var components = calendar.dateComponents([.year, .month, .day], from: activeDate)
            components.hour = deadlineHour
            components.minute = deadlineMinute
            return calendar.date(from: components) ?? activeDate
        } else {
            let previousDay = calendar.date(byAdding: .day, value: -1, to: activeDate)!
            var components = calendar.dateComponents([.year, .month, .day], from: previousDay)
            components.hour = deadlineHour
            components.minute = deadlineMinute
            return calendar.date(from: components) ?? activeDate
        }
    }
}
