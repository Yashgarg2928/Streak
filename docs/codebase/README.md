# Codebase Documentation Architecture

Welcome to the technical codebase documentation for **Streak**. This directory contains modular, detailed guides explaining the architecture, codebase organization, data flows, and code symbols for each unit of code in the app.

---

## Documentation Modules

| Document | Description | Key Code Files |
| :--- | :--- | :--- |
| 📁 **[App Core Architecture](file:///Users/madhvan07icloud.coom/self-improvment-app/docs/codebase/app_architecture.md)** | Main entry point, Dependency Injection (DI) system, and Navigation Routing state. | `StreakApp.swift`, `AppEnvironment.swift`, `AppRouter.swift`, `RootView.swift` |
| 🎨 **[Shared UI & Design System](file:///Users/madhvan07icloud.coom/self-improvment-app/docs/codebase/shared_ui_components.md)** | Neo-Brutalist design tokens, layout parameters, and reusable/shared UI views. | `DesignTokens.swift`, `SharedComponents.swift`, `ConsistencyGridView.swift` |
| 🗄️ **[Persistence & Data Sharing](file:///Users/madhvan07icloud.coom/self-improvment-app/docs/codebase/persistence_shared_data.md)** | SwiftData persistence models, concrete repository implementations, and widget communication. | `ModelContainerFactory.swift`, `SwiftDataModels.swift`, `SwiftDataRepositories.swift`, `WidgetDataStore.swift` |
| 🏷️ **[Habits & Categories Module](file:///Users/madhvan07icloud.coom/self-improvment-app/docs/codebase/habits_categories_module.md)** | Entities, repositories, use cases, view models, and views for Habit Categories. | `Category.swift`, `DayEntry.swift`, `CreateCategoryUseCase.swift`, `ResolveDayStatusUseCase.swift`, `CalculateStreakUseCase.swift`, `MultiCategoryWidget.swift`, `OverallDetailView.swift` |
| 📝 **[Tasks Module](file:///Users/madhvan07icloud.coom/self-improvment-app/docs/codebase/tasks_module.md)** | Planning, adding, completing, and deleting tasks for today or tomorrow. | `Task.swift`, `AddTaskUseCase.swift`, `CompleteTaskUseCase.swift`, `TaskViewModel.swift`, `TaskListView.swift` |
| 🏆 **[Goals & Daily Assist Modules](file:///Users/madhvan07icloud.coom/self-improvment-app/docs/codebase/goals_reflection_modules.md)** | Entities, repository protocols, and use cases for long-term Goals and Daily Assist reflections. | `Goal.swift`, `GoalProgressEntry.swift`, `ReflectionEntry.swift`, `SaveReflectionUseCase.swift`, `GoalWidget.swift` |
| ⚙️ **[Settings & Onboarding Module](file:///Users/madhvan07icloud.coom/self-improvment-app/docs/codebase/settings_module.md)** | User onboarding, wake-cycle time boundaries, date rollover resolver, and settings settings configurations. | `SettingsView.swift`, `OnboardingView.swift`, `ActiveDayResolver.swift`, `NotificationService.swift` |

---

## Architectural Guidelines

Every feature in Streak is implemented using **Clean Architecture** combined with **Domain-Driven Design (DDD)** concepts:

1. **Unidirectional Dependency Flow:** Dependencies point inward.
   - `Presentation` depends on `Application` and `Domain`.
   - `Application` depends on `Domain`.
   - `Infrastructure` implements repository protocols defined in `Domain`.
2. **Pure Domain Model:** The Domain layer contains pure Swift objects (no dependencies on UIKit, SwiftUI, or SwiftData).
3. **Focused Use Cases:** Each business action is encapsulated in a single Use Case struct.
4. **Lightweight DI:** All repositories and services are registered in the global `AppEnvironment` and made accessible to SwiftUI views via standard Environment Injection.
