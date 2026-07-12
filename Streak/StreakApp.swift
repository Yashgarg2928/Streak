// StreakApp.swift
// App entry point. Wires ModelContainer → Repositories → AppEnvironment.
// This file and AppRouter are the only files touched when adding a new module.

import SwiftUI
import SwiftData

@main
struct StreakApp: App {
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
            self.environment = AppEnvironment(
                categoryRepository:   categoryRepo,
                taskRepository:       SwiftDataTaskRepository(context: ctx),
                goalRepository:       SwiftDataGoalRepository(context: ctx),
                dayEntryRepository:   dayEntryRepo,
                reflectionRepository: SwiftDataReflectionRepository(context: ctx)
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .environment(router)
                .modelContainer(container)
                .onAppear {
                    environment.syncWidgets()
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
}
