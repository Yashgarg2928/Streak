// Presentation/Onboarding/OnboardingView.swift

import SwiftUI

struct OnboardingView: View {
    let settings: any SettingsRepository
    let onCompletion: () -> Void
    
    @State private var startHour: Int = 7
    @State private var startMinute: Int = 0
    @State private var endHour: Int = 23
    @State private var endMinute: Int = 30
    @State private var isInterCalendar: Bool = true
    
    @State private var planningMode: String = "currentDay"
    @State private var planningHour: Int = 10
    @State private var planningMinute: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppLayout.sectionSpacing) {
                // Header Card
                BrutalistCard {
                    VStack(spacing: 12) {
                        Text("⚡️ STREAK")
                            .font(.system(.largeTitle, design: .monospaced).weight(.black))
                            .foregroundStyle(AppColor.textPrimary)
                        
                        Text("Define your custom wake-cycle and planning deadlines to keep your streaks accurate.")
                            .font(.system(.body))
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.top, 20)
                
                // Active Boundaries Card
                BrutalistCard {
                    VStack(spacing: AppLayout.itemSpacing * 2) {
                        Text("ACTIVE DAY CYCLE")
                            .font(.system(.headline, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Toggle(isOn: $isInterCalendar) {
                            Text("Day Spans Midnight")
                                .font(.system(.body).weight(.semibold))
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .tint(AppColor.border)
                        
                        if isInterCalendar {
                            Divider()
                                .background(AppColor.border)
                            
                            // Start Time Selection
                            HStack {
                                Text("Active Start:")
                                    .font(.system(.body).weight(.semibold))
                                    .foregroundStyle(AppColor.textSecondary)
                                Spacer()
                                TimeDropdownPicker(hour: $startHour, minute: $startMinute)
                            }
                            
                            Divider()
                                .background(AppColor.border)
                            
                            // End Time Selection
                            HStack {
                                Text("Active End:")
                                    .font(.system(.body).weight(.semibold))
                                    .foregroundStyle(AppColor.textSecondary)
                                Spacer()
                                TimeDropdownPicker(hour: $endHour, minute: $endMinute)
                            }
                            
                            Text("Your active day wraps across midnight (e.g. 7 AM to 2 AM).")
                                .font(.system(.caption))
                                .foregroundStyle(AppColor.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("Your active day follows standard calendar days (resets strictly at Midnight).")
                                .font(.system(.caption))
                                .foregroundStyle(AppColor.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
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
                             ? "Tasks must be created on the day itself before the deadline."
                             : "Tasks for the day must be planned the night before by the deadline.")
                            .font(.system(.caption))
                            .foregroundStyle(AppColor.red)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, AppLayout.screenMargin)
                
                // Finish Button
                BrutalistButton(title: "START STREAKING") {
                    settings.activeDayStartHour = startHour
                    settings.activeDayStartMinute = startMinute
                    settings.activeDayEndHour = endHour
                    settings.activeDayEndMinute = endMinute
                    settings.isInterCalendarEnabled = isInterCalendar
                    settings.planningWindowMode = planningMode
                    settings.planningDeadlineHour = planningHour
                    settings.planningDeadlineMinute = planningMinute
                    settings.isOnboardingCompleted = true
                    settings.saveAll()
                    onCompletion()
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.bottom, 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background.ignoresSafeArea())
    }
}

// Reusable hours/minutes selector row
struct TimeDropdownPicker: View {
    @Binding var hour: Int
    @Binding var minute: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Picker("Hour", selection: $hour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d", h)).tag(h)
                }
            }
            .pickerStyle(.menu)
            .tint(AppColor.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(AppColor.border, lineWidth: 1.5)
            )
            
            Text(":")
                .font(.system(.body).weight(.black))
                .foregroundStyle(AppColor.textPrimary)
            
            Picker("Minute", selection: $minute) {
                ForEach(0..<12, id: \.self) { m in
                    let minVal = m * 5
                    Text(String(format: "%02d", minVal)).tag(minVal)
                }
            }
            .pickerStyle(.menu)
            .tint(AppColor.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(AppColor.border, lineWidth: 1.5)
            )
        }
    }
}
