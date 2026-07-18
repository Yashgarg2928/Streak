// Presentation/Settings/SettingsView.swift

import SwiftUI

struct SettingsView: View {
    let settings: any SettingsRepository
    let env: AppEnvironment
    
    @State private var startHour: Int
    @State private var startMinute: Int
    @State private var endHour: Int
    @State private var endMinute: Int
    @State private var isInterCalendar: Bool
    
    @State private var planningMode: String
    @State private var planningHour: Int
    @State private var planningMinute: Int
    
    @State private var reminderEnabled: Bool = true
    @State private var reminderHour: Int
    @State private var reminderMinute: Int
    
    @State private var showBanner: Bool = false
    @State private var bannerMessage: String = ""
    
    init(env: AppEnvironment) {
        self.env = env
        self.settings = env.settingsRepository
        
        _startHour = State(initialValue: env.settingsRepository.activeDayStartHour)
        _startMinute = State(initialValue: env.settingsRepository.activeDayStartMinute)
        _endHour = State(initialValue: env.settingsRepository.activeDayEndHour)
        _endMinute = State(initialValue: env.settingsRepository.activeDayEndMinute)
        _isInterCalendar = State(initialValue: env.settingsRepository.isInterCalendarEnabled)
        
        _planningMode = State(initialValue: env.settingsRepository.planningWindowMode)
        _planningHour = State(initialValue: env.settingsRepository.planningDeadlineHour)
        _planningMinute = State(initialValue: env.settingsRepository.planningDeadlineMinute)
        
        _reminderHour = State(initialValue: env.settingsRepository.planningReminderHour)
        _reminderMinute = State(initialValue: env.settingsRepository.planningReminderMinute)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppLayout.sectionSpacing) {
                // Banner Notification
                if showBanner {
                    HStack {
                        Text(bannerMessage)
                            .font(.system(.subheadline, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        Button(action: { showBanner = false }) {
                            Image(systemName: "xmark")
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                    .padding()
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                            .stroke(AppColor.green, lineWidth: AppLayout.borderWidth)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.horizontal, AppLayout.screenMargin)
                }
                
                // Header
                HStack {
                    Text("SETTINGS")
                        .font(.system(.title, design: .monospaced).weight(.black))
                        .foregroundStyle(AppColor.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.top, 10)
                
                // Active Boundaries Card
                BrutalistCard {
                    VStack(spacing: AppLayout.itemSpacing * 2) {
                        Text("ACTIVE DAY CYCLE")
                            .font(.system(.headline, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Toggle(isOn: $isInterCalendar) {
                            Text("Spans Midnight")
                                .font(.system(.body).weight(.semibold))
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .tint(AppColor.border)
                        
                        Divider()
                            .background(AppColor.border)
                        
                        HStack {
                            Text("Active Start:")
                                .font(.system(.body).weight(.semibold))
                                .foregroundStyle(AppColor.textSecondary)
                            Spacer()
                            TimeDropdownPicker(hour: $startHour, minute: $startMinute)
                        }
                        
                        Divider()
                            .background(AppColor.border)
                        
                        HStack {
                            Text("Active End:")
                                .font(.system(.body).weight(.semibold))
                                .foregroundStyle(AppColor.textSecondary)
                            Spacer()
                            TimeDropdownPicker(hour: $endHour, minute: $endMinute)
                        }
                        
                        Divider()
                            .background(AppColor.border)
                        
                        Text(isInterCalendar
                             ? "Your active day wraps across midnight (e.g. 1 PM to 1 AM)."
                             : "Your active day is within a single calendar day (e.g. 9 AM to 6 PM).")
                            .font(.system(.caption))
                            .foregroundStyle(AppColor.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, AppLayout.screenMargin)
                
                // Planning Window Card
                BrutalistCard {
                    VStack(spacing: AppLayout.itemSpacing * 2) {
                        Text("PLANNING WINDOW")
                            .font(.system(.headline, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Picker("Planning Window Mode", selection: $planningMode) {
                            Text("Plan Morning of").tag("currentDay")
                            Text("Plan Night Before").tag("previousDay")
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 2)
                        
                        Divider()
                            .background(AppColor.border)
                        
                        HStack {
                            Text("Planning Deadline:")
                                .font(.system(.body).weight(.semibold))
                                .foregroundStyle(AppColor.textSecondary)
                            Spacer()
                            TimeDropdownPicker(hour: $planningHour, minute: $planningMinute)
                        }
                        
                        Text(planningMode == "currentDay"
                             ? "Tasks must be planned on the active day itself before the deadline."
                             : "Tasks for the active day must be planned the night before by the deadline.")
                            .font(.system(.caption))
                            .foregroundStyle(AppColor.red)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, AppLayout.screenMargin)
                
                // Planning Reminder Card
                BrutalistCard {
                    VStack(spacing: AppLayout.itemSpacing * 2) {
                        Text("PLANNING REMINDERS")
                            .font(.system(.headline, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Toggle(isOn: $reminderEnabled) {
                            Text("Enable Planning Reminder")
                                .font(.system(.body).weight(.semibold))
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .tint(AppColor.border)
                        
                        if reminderEnabled {
                            Divider()
                                .background(AppColor.border)
                            
                            HStack {
                                Text("Reminder Time:")
                                    .font(.system(.body).weight(.semibold))
                                    .foregroundStyle(AppColor.textSecondary)
                                Spacer()
                                TimeDropdownPicker(hour: $reminderHour, minute: $reminderMinute)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppLayout.screenMargin)
                
                // Continuous Alarm Preview Card
                BrutalistCard {
                    VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                        HStack {
                            Text("WAKE UP CHALLENGE (SOON)")
                                .font(.system(.headline, design: .monospaced).weight(.bold))
                                .foregroundStyle(AppColor.textPrimary)
                            Spacer()
                            Text("PREVIEW")
                                .font(.system(.caption, design: .monospaced).weight(.black))
                                .foregroundStyle(AppColor.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColor.blank)
                                .clipShape(Capsule())
                        }
                        
                        Text("Continuous wake alarm that will not stop until you complete a selected challenge.")
                            .font(.system(.caption))
                            .foregroundStyle(AppColor.textSecondary)
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(AppColor.textDisabled)
                            Text("Perform 5 push-ups to turn off alarm")
                                .font(.system(.body).weight(.semibold))
                                .foregroundStyle(AppColor.textDisabled)
                        }
                    }
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .opacity(0.6)
                
                // Save Button
                BrutalistButton(title: "SAVE CONFIGURATION") {
                    if !isInterCalendar {
                        let endTotal = endHour * 60 + endMinute
                        let startTotal = startHour * 60 + startMinute
                        if endTotal <= startTotal {
                            bannerMessage = "End time must be after start time when Spans Midnight is off."
                            withAnimation {
                                showBanner = true
                            }
                            // Trigger failure haptic
                            let feedback = UINotificationFeedbackGenerator()
                            feedback.notificationOccurred(.error)
                            return
                        }
                    }
                    
                    settings.activeDayStartHour = startHour
                    settings.activeDayStartMinute = startMinute
                    settings.activeDayEndHour = endHour
                    settings.activeDayEndMinute = endMinute
                    settings.isInterCalendarEnabled = isInterCalendar
                    settings.planningWindowMode = planningMode
                    settings.planningDeadlineHour = planningHour
                    settings.planningDeadlineMinute = planningMinute
                    settings.planningReminderHour = reminderHour
                    settings.planningReminderMinute = reminderMinute
                    settings.saveAll()
                    
                    // Reschedule reminders
                    rescheduleLocalReminders()
                    
                    bannerMessage = "Configuration saved successfully!"
                    withAnimation {
                        showBanner = true
                    }
                    
                    // Trigger haptic
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.success)
                    
                    // Sync widgets
                    env.syncWidgets()
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.bottom, 30)
            }
            .padding(.vertical)
        }
        .background(AppColor.background.ignoresSafeArea())
        .onAppear {
            checkForTimeZoneShift()
        }
    }
    
    private func checkForTimeZoneShift() {
        let currentTZ = TimeZone.current.identifier
        if let lastTZ = settings.lastKnownTimeZone, lastTZ != currentTZ {
            let oldTZ = TimeZone(identifier: lastTZ) ?? .current
            let newTZ = TimeZone(identifier: currentTZ) ?? .current
            let difference = newTZ.secondsFromGMT() - oldTZ.secondsFromGMT()
            
            if difference > 0 {
                settings.timezoneGraceExtension = Double(difference)
                settings.lastKnownTimeZone = currentTZ
                settings.saveAll()
                
                bannerMessage = "Timezone shifted forward! A grace extension of \(difference / 3600)h has been applied to today's deadline."
                showBanner = true
            } else {
                settings.lastKnownTimeZone = currentTZ
                settings.saveAll()
            }
        } else if settings.lastKnownTimeZone == nil {
            settings.lastKnownTimeZone = currentTZ
            settings.saveAll()
        }
    }
    
    private func rescheduleLocalReminders() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            
            guard reminderEnabled else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "⏰ Plan Your Active Day"
            content.body = "Set your goals before your active day deadline passes!"
            content.sound = .default
            
            var components = DateComponents()
            components.hour = reminderHour
            components.minute = reminderMinute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "streak.planning-reminder",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
}
