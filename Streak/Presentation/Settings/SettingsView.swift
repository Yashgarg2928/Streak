// Presentation/Settings/SettingsView.swift

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

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
    
    @State private var reminderEnabled: Bool
    @State private var reminderHour: Int
    @State private var reminderMinute: Int
    
    // Spicy & Gemini AI Notifications
    @State private var isAiNotificationsEnabled: Bool
    @State private var geminiApiKey: String
    @State private var notificationPersona: String
    @State private var isMorningHypeEnabled: Bool
    @State private var isMiddayNudgeEnabled: Bool
    @State private var isEmergencyCutoffEnabled: Bool
    @State private var apiTestResult: String? = nil
    @State private var isTestingApiKey: Bool = false
    
    @Environment(\.modelContext) private var modelContext
    @State private var showBanner: Bool = false
    @State private var bannerMessage: String = ""
    @State private var showResetConfirmation: Bool = false

    @State private var restWeekdays: Set<Int>
    @State private var isLiveActivityEnabled: Bool

    // Backup & restore
    @State private var backupDocument: StreakBackupDocument? = nil
    @State private var showBackupExporter: Bool = false
    @State private var showBackupImporter: Bool = false
    @State private var pendingRestoreData: Data? = nil
    @State private var pendingRestoreSummary: BackupSummary? = nil
    @State private var showRestoreConfirmation: Bool = false
    @State private var showRestartAlert: Bool = false
    
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
        
        _reminderEnabled = State(initialValue: env.settingsRepository.isPlanningAlertEnabled)
        _restWeekdays = State(initialValue: Set(env.settingsRepository.restWeekdays))
        _isLiveActivityEnabled = State(initialValue: env.settingsRepository.isLiveActivityEnabled)
        _reminderHour = State(initialValue: env.settingsRepository.planningReminderHour)
        _reminderMinute = State(initialValue: env.settingsRepository.planningReminderMinute)

        _isAiNotificationsEnabled = State(initialValue: env.settingsRepository.isAiNotificationsEnabled)
        _geminiApiKey = State(initialValue: env.settingsRepository.geminiApiKey)
        _notificationPersona = State(initialValue: env.settingsRepository.notificationPersona)
        _isMorningHypeEnabled = State(initialValue: env.settingsRepository.isMorningHypeEnabled)
        _isMiddayNudgeEnabled = State(initialValue: env.settingsRepository.isMiddayNudgeEnabled)
        _isEmergencyCutoffEnabled = State(initialValue: env.settingsRepository.isEmergencyCutoffEnabled)
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
                
                // Appearance Theme Card
                BrutalistCard {
                    VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                        Text("APPEARANCE THEME")
                            .font(.system(.headline, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)

                        Picker("Theme Mode", selection: Binding(
                            get: { env.themeMode },
                            set: { env.themeMode = $0 }
                        )) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(.segmented)

                        Text("Choose between Light, Dark, or System automatic theme.")
                            .font(.system(.caption))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                .padding(.horizontal, AppLayout.screenMargin)
                
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
                
                // Rest Days Card
                BrutalistCard {
                    VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                        Text("REST DAYS")
                            .font(.system(.headline, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)

                        WeekdayPicker(selection: $restWeekdays, accent: AppColor.rest, selectedTextColor: AppColor.textPrimary)

                        Text(restWeekdays.isEmpty
                             ? "No rest days. Every day needs planned tasks."
                             : "On \(WeekdayPicker.summary(restWeekdays)) you can skip planning. Rest days never turn red and don't break your streak. Finishing tasks on a rest day still counts as green.")
                            .font(.system(.caption))
                            .foregroundStyle(AppColor.textSecondary)
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

                // Spicy Notification Engine & Optional Gemini AI Card
                BrutalistCard {
                    VStack(alignment: .leading, spacing: AppLayout.itemSpacing * 2) {
                        HStack {
                            Text("🌶️ SPICY NOTIFICATIONS")
                                .font(.system(.headline, design: .monospaced).weight(.bold))
                                .foregroundStyle(AppColor.textPrimary)
                            Spacer()
                        }
                        
                        Text("Multi-touchpoint notifications powered by built-in templates or optional Gemini AI.")
                            .font(.system(.caption))
                            .foregroundStyle(AppColor.textSecondary)

                        // Motivation Persona
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MOTIVATION PERSONA:")
                                .font(.app(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppColor.textSecondary)
                            
                            Picker("Persona", selection: $notificationPersona) {
                                Text("🔥 Savage Roast").tag("savage")
                                Text("⚔️ Drill Sergeant").tag("goggins")
                                Text("🎮 RPG Lore").tag("rpg")
                                Text("🧘 Zen Coach").tag("zen")
                            }
                            .pickerStyle(.segmented)
                        }

                        Divider().background(AppColor.border)

                        // Touchpoints Toggles
                        VStack(alignment: .leading, spacing: 10) {
                            Text("NOTIFICATION TOUCHPOINTS:")
                                .font(.app(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppColor.textSecondary)

                            Toggle("🚀 Morning Hype (08:00 AM)", isOn: $isMorningHypeEnabled)
                                .font(.system(.subheadline, design: .monospaced))
                                .tint(AppColor.border)

                            Toggle("⚠️ Mid-Day Nudge (03:00 PM, skipped once you're done)", isOn: $isMiddayNudgeEnabled)
                                .font(.system(.subheadline, design: .monospaced))
                                .tint(AppColor.border)

                            Toggle("🚨 Last Call (1h before your day ends, if unfinished)", isOn: $isEmergencyCutoffEnabled)
                                .font(.system(.subheadline, design: .monospaced))
                                .tint(AppColor.border)
                        }

                        Divider().background(AppColor.border)

                        // Optional Gemini AI Section
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("🤖 Enable Gemini AI Notifications (Optional)", isOn: $isAiNotificationsEnabled)
                                .font(.system(.body, design: .monospaced).weight(.bold))
                                .foregroundStyle(AppColor.textPrimary)
                                .tint(AppColor.green)

                            if isAiNotificationsEnabled {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Free API Key from Google AI Studio:")
                                        .font(.app(size: 11, weight: .bold))
                                        .foregroundStyle(AppColor.textSecondary)

                                    SecureField("AIZA...", text: $geminiApiKey)
                                        .textFieldStyle(.plain)
                                        .padding(10)
                                        .background(AppColor.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))

                                    HStack {
                                        Button {
                                            isTestingApiKey = true
                                            Swift.Task {
                                                do {
                                                    let res = try await GeminiNotificationService.shared.testApiKey(geminiApiKey)
                                                    apiTestResult = "✅ Connected! Preview: \"\(res)\""
                                                } catch {
                                                    apiTestResult = "❌ \(error.localizedDescription)"
                                                }
                                                isTestingApiKey = false
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                if isTestingApiKey {
                                                    ProgressView().scaleEffect(0.7)
                                                }
                                                Text("TEST API KEY & PREVIEW")
                                                    .font(.app(size: 10, weight: .black))
                                            }
                                            .foregroundStyle(AppColor.background)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(AppColor.border)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                        .disabled(geminiApiKey.isEmpty || isTestingApiKey)
                                        .buttonStyle(.plain)

                                        Spacer()
                                    }

                                    if let apiTestResult {
                                        Text(apiTestResult)
                                            .font(.app(size: 11, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(apiTestResult.contains("✅") ? AppColor.green : AppColor.red)
                                    }

                                    Text("🔒 100% Private: Your API Key is saved locally on your iPhone and never uploaded to any server. Used exclusively for generating local notifications.")
                                        .font(.app(size: 10))
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppLayout.screenMargin)
                
                // Lock Screen Countdown Card
                BrutalistCard {
                    VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                        Toggle(isOn: $isLiveActivityEnabled) {
                            Text("LOCK SCREEN COUNTDOWN")
                                .font(.system(.headline, design: .monospaced).weight(.bold))
                                .foregroundStyle(AppColor.textPrimary)
                        }
                        .tint(AppColor.border)
                        Text("Shows tasks left and time until your day ends on the Lock Screen and in the Dynamic Island while you have unfinished tasks, and disappears once you're done. It starts when you open Streak. iOS stops Live Activities after 8 hours, and opening Streak restarts it. To start it without opening the app, add a Shortcuts automation each morning that runs **Show Day Countdown**.")
                            .font(.system(.caption))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                .padding(.horizontal, AppLayout.screenMargin)

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
                    
                    settings.isAiNotificationsEnabled = isAiNotificationsEnabled
                    settings.geminiApiKey = geminiApiKey
                    settings.notificationPersona = notificationPersona
                    settings.isMorningHypeEnabled = isMorningHypeEnabled
                    settings.isMiddayNudgeEnabled = isMiddayNudgeEnabled
                    settings.isEmergencyCutoffEnabled = isEmergencyCutoffEnabled
                    settings.isPlanningAlertEnabled = reminderEnabled
                    settings.restWeekdays = restWeekdays.sorted()
                    settings.isLiveActivityEnabled = isLiveActivityEnabled
                    
                    settings.saveAll()
                    
                    // Re-resolve today (rest days / deadlines may have changed) and rebuild notifications.
                    DaySweeper.run(env: env)
                    Swift.Task {
                        await SpicyNotificationScheduler.reschedule(env: env, requestPermission: true)
                    }
                    
                    bannerMessage = "Configuration saved successfully!"
                    withAnimation {
                        showBanner = true
                    }
                    
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.success)
                }
                .padding(.horizontal, AppLayout.screenMargin)

                // Backup & Restore Card
                backupCard
                    .padding(.horizontal, AppLayout.screenMargin)

                // Danger Zone Card
                BrutalistCard(borderColor: AppColor.red) {
                    VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                        Text("DANGER ZONE")
                            .font(.system(.headline, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.red)
                        
                        Text("Permanently erase all tasks, categories, goals, reflection logs, and streak history.")
                            .font(.system(.caption))
                            .foregroundStyle(AppColor.textSecondary)
                        
                        Button {
                            showResetConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("RESET ALL APP DATA")
                                    .font(.system(.subheadline, design: .monospaced).weight(.bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppLayout.minTapTarget)
                            .background(AppColor.red)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.bottom, 30)
            }
            .padding(.vertical)
        }
        .background(AppColor.background.ignoresSafeArea())
        .alert("Erase All Data?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Erase Everything", role: .destructive) {
                resetAllAppData()
            }
        } message: {
            Text("This will permanently delete all tasks, categories, goals, and history. This action cannot be undone.")
        }
        .fileExporter(
            isPresented: $showBackupExporter,
            document: backupDocument,
            contentType: .propertyList,
            defaultFilename: BackupService.suggestedFilename()
        ) { result in
            switch result {
            case .success:
                settings.lastBackupDate = Date()
                settings.saveAll()
                env.syncWidgets()
                showBannerMessage("Backup saved. Keep it somewhere off this phone (iCloud Drive, Google Drive…).", success: true)
            case .failure(let error):
                showBannerMessage("Backup failed: \(error.localizedDescription)", success: false)
            }
            backupDocument = nil
        }
        .fileImporter(isPresented: $showBackupImporter, allowedContentTypes: [.propertyList, .data]) { result in
            do {
                let url = try result.get()
                let didAccess = url.startAccessingSecurityScopedResource()
                defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url)
                pendingRestoreSummary = try BackupService.inspect(data)
                pendingRestoreData = data
                showRestoreConfirmation = true
            } catch {
                showBannerMessage(error.localizedDescription, success: false)
            }
        }
        .alert("Restore this backup?", isPresented: $showRestoreConfirmation) {
            Button("Cancel", role: .cancel) { pendingRestoreData = nil }
            Button("Restore", role: .destructive) {
                guard let data = pendingRestoreData else { return }
                do {
                    try BackupService.stageRestore(from: data, storeURL: ModelContainerFactory.storeURL)
                    showRestartAlert = true
                } catch {
                    showBannerMessage(error.localizedDescription, success: false)
                }
                pendingRestoreData = nil
            }
        } message: {
            Text("Backup from \(pendingRestoreSummary?.createdAt.formatted(date: .abbreviated, time: .shortened) ?? "unknown date"). This replaces ALL current data and settings. A safety copy of your current data is kept on this phone.")
        }
        .alert("Restore ready", isPresented: $showRestartAlert) {
            Button("Close Streak") { exit(0) }
        } message: {
            Text("Streak will close now. Open it again to finish restoring your backup.")
        }
        .onAppear {
            checkForTimeZoneShift()
        }
    }

    // MARK: - Backup & Restore

    private var backupCard: some View {
        BrutalistCard {
            VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                Text("BACKUP & RESTORE")
                    .font(.system(.headline, design: .monospaced).weight(.bold))
                    .foregroundStyle(AppColor.textPrimary)

                Text(lastBackupDescription)
                    .font(.system(.subheadline, design: .monospaced).weight(.bold))
                    .foregroundStyle(isBackupStale ? AppColor.orange : AppColor.green)

                Text("Your data only lives on this phone. Export a backup file (tasks, streaks, goals, finance, workouts and settings) to Files, and restore it after reinstalling or on a new phone.")
                    .font(.system(.caption))
                    .foregroundStyle(AppColor.textSecondary)

                HStack(spacing: 10) {
                    Button {
                        exportBackup()
                    } label: {
                        Label("EXPORT", systemImage: "square.and.arrow.up")
                            .font(.system(.subheadline, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.background)
                            .frame(maxWidth: .infinity, minHeight: AppLayout.minTapTarget)
                            .background(AppColor.border)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                    }
                    .buttonStyle(.plain)

                    Button {
                        showBackupImporter = true
                    } label: {
                        Label("RESTORE", systemImage: "square.and.arrow.down")
                            .font(.system(.subheadline, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: AppLayout.minTapTarget)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                                    .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var isBackupStale: Bool {
        guard let last = settings.lastBackupDate else { return true }
        return Date().timeIntervalSince(last) > 14 * 24 * 3600
    }

    private var lastBackupDescription: String {
        guard let last = settings.lastBackupDate else { return "NEVER BACKED UP" }
        return "LAST BACKUP: \(last.formatted(.relative(presentation: .named)).uppercased())"
    }

    private func exportBackup() {
        do {
            try? modelContext.save()
            let data = try BackupService.makeBackup(
                storeURL: ModelContainerFactory.storeURL,
                appGroupID: AppConfig.appGroupID
            )
            backupDocument = StreakBackupDocument(data: data)
            showBackupExporter = true
        } catch {
            showBannerMessage(error.localizedDescription, success: false)
        }
    }

    private func showBannerMessage(_ message: String, success: Bool) {
        bannerMessage = message
        withAnimation { showBanner = true }
        UINotificationFeedbackGenerator().notificationOccurred(success ? .success : .error)
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
    
    private func resetAllAppData() {
        let useCase = ResetAllDataUseCase(context: modelContext, settingsRepository: settings)
        do {
            try useCase.execute()
            bannerMessage = "All app data erased successfully. Restarting..."
            withAnimation { showBanner = true }
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
        } catch {
            bannerMessage = "Failed to erase data: \(error.localizedDescription)"
            withAnimation { showBanner = true }
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.error)
        }
    }
}
