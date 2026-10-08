// StreakApp.swift
// App entry point. Wires ModelContainer → Repositories → AppEnvironment.
// This file and AppRouter are the only files touched when adding a new module.

import SwiftUI
import SwiftData
import BackgroundTasks
import AppIntents

@main
struct StreakApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let container: ModelContainer
    private let environment: AppEnvironment
    private let router = AppRouter()

    init() {
        // A restore staged from Settings is applied before the store is opened.
        BackupService.applyPendingRestoreIfNeeded(
            storeURL: ModelContainerFactory.storeURL,
            appGroupID: AppConfig.appGroupID
        )

        do {
            let c = try ModelContainerFactory.makeContainer()
            self.container = c
            self.environment = AppEnvironment.live(context: c.mainContext)
            AppEnvironment.current = self.environment

            let env = self.environment

            BGTaskScheduler.shared.register(forTaskWithIdentifier: AppConfig.backgroundTaskId, using: nil) { task in
                task.expirationHandler = {
                    // Task expired, clean up if needed
                }
                Swift.Task { @MainActor in
                    DaySweeper.run(env: env)
                    StreakApp.scheduleLockoutSweep(environment: env)
                    task.setTaskCompleted(success: true)
                }
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    private var themeColorScheme: ColorScheme? {
        switch environment.themeMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(themeColorScheme)
                .environment(environment)
                .environment(router)
                .modelContainer(container)
                .onAppear {
                    DaySweeper.run(env: environment)
                    StreakApp.scheduleLockoutSweep(environment: environment)
                    StreakAppShortcuts.updateAppShortcutParameters()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        DaySweeper.run(env: environment)
                        StreakApp.scheduleLockoutSweep(environment: environment)
                    }
                }
                .onOpenURL { url in
                    guard url.scheme == "streak" else { return }
                    switch url.host {
                    case "tasks": router.selectedTab = .tasks
                    case "home":  router.selectedTab = .home
                    case "finance": router.selectedTab = .finance
                    case "goals":
                        router.selectedTab = .home
                        router.showGoals = true
                    default: break
                    }
                }
        }
    }

    private static func scheduleLockoutSweep(environment: AppEnvironment) {
        let request = BGProcessingTaskRequest(identifier: AppConfig.backgroundTaskId)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        let calendar = Calendar.current
        let settings = environment.settingsRepository
        let endHour = settings.activeDayEndHour
        let endMinute = settings.activeDayEndMinute

        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = endHour
        components.minute = endMinute

        if var deadline = calendar.date(from: components) {
            if deadline <= Date() {
                deadline = calendar.date(byAdding: .day, value: 1, to: deadline) ?? deadline
            }
            request.earliestBeginDate = deadline
        }

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule lockout sweep task: \(error)")
        }
    }
}
