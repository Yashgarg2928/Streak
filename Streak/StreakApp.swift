// StreakApp.swift
// App entry point. Wires ModelContainer → Repositories → AppEnvironment.
// This file and AppRouter are the only files touched when adding a new module.

import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct StreakApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let container: ModelContainer
    private let environment: AppEnvironment
    private let router = AppRouter()

    init() {
        do {
            let c = try ModelContainerFactory.makeContainer()
            self.container = c
            let ctx = c.mainContext
            let dayEntryRepo   = SwiftDataDayEntryRepository(context: ctx)
            let categoryRepo   = SwiftDataCategoryRepository(context: ctx)
            let settingsRepo   = UserDefaultsSettingsRepository()
            let routineRepo    = SwiftDataHabitRoutineRepository(context: ctx)
            
            self.environment = AppEnvironment(
                categoryRepository:     categoryRepo,
                taskRepository:         SwiftDataTaskRepository(context: ctx),
                goalRepository:         SwiftDataGoalRepository(context: ctx),
                dayEntryRepository:     dayEntryRepo,
                reflectionRepository:   SwiftDataReflectionRepository(context: ctx),
                settingsRepository:     settingsRepo,
                habitRoutineRepository: routineRepo
            )
            
            let container = c
            let env = self.environment
            
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.madhvan.streak.lockoutSweep", using: nil) { task in
                task.expirationHandler = {
                    // Task expired, clean up if needed
                }
                Swift.Task {
                    await StreakApp.performLockoutSweep(container: container, environment: env)
                    StreakApp.scheduleLockoutSweep(environment: env)
                    task.setTaskCompleted(success: true)
                }
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .environment(environment)
                .environment(router)
                .modelContainer(container)
                .onAppear {
                    environment.syncWidgets()
                    StreakApp.performForegroundCatchUpSweep(container: container, environment: environment)
                    StreakApp.scheduleLockoutSweep(environment: environment)
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        StreakApp.performForegroundCatchUpSweep(container: container, environment: environment)
                        StreakApp.scheduleLockoutSweep(environment: environment)
                    }
                }
                .onOpenURL { url in
                    guard url.scheme == "streak" else { return }
                    switch url.host {
                    case "tasks": router.selectedTab = .tasks
                    case "home":  router.selectedTab = .home
                    default: break
                    }
                }
        }
    }
    
    private static func scheduleLockoutSweep(environment: AppEnvironment) {
        let request = BGProcessingTaskRequest(identifier: "com.madhvan.streak.lockoutSweep")
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
            print("Scheduled next lockout sweep task successfully.")
        } catch {
            print("Could not schedule lockout sweep task: \(error)")
        }
    }
    
    private static func performLockoutSweep(container: ModelContainer, environment: AppEnvironment) async {
        let ctx = container.mainContext
        let settings = environment.settingsRepository
        
        let today = ActiveDayResolver.resolveActiveDate(for: Date(), settings: settings)
        
        let dayEntryRepo = SwiftDataDayEntryRepository(context: ctx)
        let categoryRepo = SwiftDataCategoryRepository(context: ctx)
        let taskRepo     = SwiftDataTaskRepository(context: ctx)
        let goalRepo     = SwiftDataGoalRepository(context: ctx)
        
        let resolver = ResolveDayStatusUseCase(
            taskRepository: taskRepo,
            categoryRepository: categoryRepo,
            dayEntryRepository: dayEntryRepo,
            settingsRepository: settings
        )
        
        do {
            // Resolve master status for today
            try resolver.execute(date: today, categoryId: nil)
            
            // Resolve category statuses for today
            let activeCategories = try categoryRepo.fetchActive()
            for cat in activeCategories {
                try resolver.execute(date: today, categoryId: cat.id)
            }
            
            // Sync goals progress
            let syncUseCase = SyncGoalProgressUseCase(
                goalRepository: goalRepo,
                dayEntryRepository: dayEntryRepo,
                taskRepository: taskRepo
            )
            try syncUseCase.execute()
            
            // Reload widgets
            environment.syncWidgets()
        } catch {
            print("Background sweep failed: \(error)")
        }
    }
    
    private static func performForegroundCatchUpSweep(container: ModelContainer, environment: AppEnvironment) {
        let ctx = container.mainContext
        let settings = environment.settingsRepository
        
        let currentActiveDate = ActiveDayResolver.resolveActiveDate(for: Date(), settings: settings)
        
        let defaults = UserDefaults(suiteName: "group.com.madhvan.streak") ?? .standard
        let lastActiveDateKey = "lastActiveDateString"
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        
        guard let lastActiveStr = defaults.string(forKey: lastActiveDateKey),
              let lastActiveDate = fmt.date(from: lastActiveStr) else {
            defaults.set(fmt.string(from: currentActiveDate), forKey: lastActiveDateKey)
            return
        }
        
        let calendar = Calendar.current
        let startOfLastActive = calendar.startOfDay(for: lastActiveDate)
        let startOfCurrentActive = calendar.startOfDay(for: currentActiveDate)
        
        if startOfCurrentActive > startOfLastActive {
            let dayEntryRepo = SwiftDataDayEntryRepository(context: ctx)
            let categoryRepo = SwiftDataCategoryRepository(context: ctx)
            let taskRepo     = SwiftDataTaskRepository(context: ctx)
            let goalRepo     = SwiftDataGoalRepository(context: ctx)
            
            let resolver = ResolveDayStatusUseCase(
                taskRepository: taskRepo,
                categoryRepository: categoryRepo,
                dayEntryRepository: dayEntryRepo,
                settingsRepository: settings
            )
            
            var sweepDate = startOfLastActive
            while sweepDate < startOfCurrentActive {
                do {
                    try resolver.execute(date: sweepDate, categoryId: nil)
                    let activeCategories = try categoryRepo.fetchActive()
                    for cat in activeCategories {
                        try resolver.execute(date: sweepDate, categoryId: cat.id)
                    }
                } catch {
                    print("Catch up sweep failed for date \(sweepDate): \(error)")
                }
                
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: sweepDate) else { break }
                sweepDate = nextDate
            }
            
            do {
                let syncUseCase = SyncGoalProgressUseCase(
                    goalRepository: goalRepo,
                    dayEntryRepository: dayEntryRepo,
                    taskRepository: taskRepo
                )
                try syncUseCase.execute()
            } catch {
                print("Goals sync failed during catch-up: \(error)")
            }
            
            environment.syncWidgets()
            defaults.set(fmt.string(from: currentActiveDate), forKey: lastActiveDateKey)
        }
        
        // Check if the current active date has passed its planning deadline and has 0 tasks
        let deadline = ActiveDayResolver.planningDeadline(for: currentActiveDate, settings: settings)
        if Date() > deadline {
            let taskRepo = SwiftDataTaskRepository(context: ctx)
            let dayEntryRepo = SwiftDataDayEntryRepository(context: ctx)
            let categoryRepo = SwiftDataCategoryRepository(context: ctx)
            
            do {
                let tasks = try taskRepo.fetchAll(for: currentActiveDate)
                if tasks.isEmpty {
                    let masterEntry = DayEntry(
                        date: currentActiveDate,
                        categoryId: nil,
                        status: .red,
                        taskCount: 0,
                        completedCount: 0
                    )
                    try dayEntryRepo.save(masterEntry)
                    
                    let activeCategories = try categoryRepo.fetchActive()
                    for cat in activeCategories {
                        let catEntry = DayEntry(
                            date: currentActiveDate,
                            categoryId: cat.id,
                            status: .red,
                            taskCount: 0,
                            completedCount: 0
                        )
                        try dayEntryRepo.save(catEntry)
                    }
                    
                    environment.syncWidgets()
                }
            } catch {
                print("Failed to enforce planning deadline check: \(error)")
            }
        }
    }
}
