# Architecture Document
## App: Streak (iOS Habit Tracker)
**Version:** 1.0  
**Date:** 2026-07-08  
**Status:** Draft

---

## 1. Architecture Style

**Clean Architecture + Domain-Driven Design (DDD)**

The app is divided into three concentric layers. Dependencies only point inward — the domain knows nothing about SwiftUI or SwiftData. This makes new feature modules plug in without touching existing ones.

```
┌──────────────────────────────────────────────┐
│              Presentation Layer               │
│         (SwiftUI Views + ViewModels)          │
├──────────────────────────────────────────────┤
│              Application Layer                │
│         (Use Cases / Interactors)             │
├──────────────────────────────────────────────┤
│               Domain Layer                    │
│      (Entities, Business Rules, Protocols)    │
├──────────────────────────────────────────────┤
│           Infrastructure Layer               │
│   (SwiftData, Notifications, iCloud, Files)   │
└──────────────────────────────────────────────┘
```

---

## 2. Layer Responsibilities

### 2.1 Domain Layer
The heart of the app. Pure Swift. No imports of UIKit, SwiftUI, or SwiftData.

- **Entities:** `Category`, `Task`, `Goal`, `DayEntry`, `ReflectionEntry`
- **Value Objects:** `DayStatus` (green/red/future), `StreakCount`, `CategoryColor`, `GoalType`
- **Domain Protocols (Repository interfaces):**
  - `CategoryRepository`
  - `TaskRepository`
  - `GoalRepository`
  - `ReflectionRepository`
- **Business Rules (pure functions or domain services):**
  - Streak calculation logic
  - Day status resolution (green/red/future)
  - Goal progress calculation
  - Task completion → category completion logic

### 2.2 Application Layer
Orchestrates domain logic. Each use case is a single, focused struct or class.

| Use Case | Responsibility |
|----------|---------------|
| `CreateCategoryUseCase` | Validates and persists a new category |
| `AddTaskUseCase` | Adds a task across daily, weekly, monthly, or backlog timeframes |
| `CompleteTaskUseCase` | Marks a task done, triggers day-status recomputation |
| `ResolveDayStatusUseCase` | Determines green/red for a category or master on a given date |
| `CalculateStreakUseCase` | Scans DayEntry history and returns current streak |
| `CreateGoalUseCase` | Creates a new goal with type and target |
| `LogGoalProgressUseCase` | Records a manual progress entry for milestone goals |
| `SaveReflectionUseCase` | Stores a daily reflection form entry |
| `ExportDataUseCase` | Serializes all data to a single JSON structure |
| `ImportDataUseCase` | Deserializes JSON and restores all data |
| `ScheduleReminderUseCase` | Schedules nightly planning and Daily Assist notifications |

### 2.3 Presentation Layer
SwiftUI only. Each screen maps to a ViewModel. ViewModels call use cases and expose `@Published` state.

- No business logic in views or viewmodels
- ViewModels translate domain entities to view-friendly display models
- Navigation is handled by a central `AppRouter`

### 2.4 Infrastructure Layer
Concrete implementations of domain protocols.

| Component | Technology |
|-----------|-----------|
| Persistence | SwiftData (ModelContainer + ModelContext) |
| iCloud sync | SwiftData + CloudKit (optional, user toggle) |
| Notifications | `UNUserNotificationCenter` |
| Widgets | WidgetKit (reads from shared App Group container) |
| Shortcuts | App Intents framework |
| File export/import | `JSONEncoder` / `JSONDecoder` + `UIDocumentPickerViewController` |
| App Group | Shared `UserDefaults` + shared SwiftData container for widget data access |

---

## 3. Module Structure

Each feature is a self-contained module. New features are added as new modules without touching existing ones.

```
Sources/
├── App/
│   ├── AppEntry.swift               # @main entry point
│   ├── AppRouter.swift              # Navigation state machine
│   └── AppEnvironment.swift        # Dependency injection container
│
├── Domain/
│   ├── Entities/
│   │   ├── Category.swift
│   │   ├── Task.swift
│   │   ├── Goal.swift
│   │   ├── DayEntry.swift
│   │   └── ReflectionEntry.swift
│   ├── ValueObjects/
│   │   ├── DayStatus.swift
│   │   ├── GoalType.swift
│   │   └── CategoryColor.swift
│   └── Repositories/               # Protocols only
│       ├── CategoryRepository.swift
│       ├── TaskRepository.swift
│       ├── GoalRepository.swift
│       └── ReflectionRepository.swift
│
├── Application/
│   └── UseCases/
│       ├── Habits/
│       ├── Tasks/
│       ├── Goals/
│       ├── Reflection/
│       └── DataPortability/
│
├── Infrastructure/
│   ├── Persistence/
│   │   ├── SwiftDataCategoryRepository.swift
│   │   ├── SwiftDataTaskRepository.swift
│   │   ├── SwiftDataGoalRepository.swift
│   │   └── SwiftDataReflectionRepository.swift
│   ├── Notifications/
│   │   └── NotificationService.swift
│   ├── Shortcuts/
│   │   └── AppIntentsProvider.swift
│   └── Export/
│       └── JSONExportService.swift
│
├── Presentation/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── HomeViewModel.swift
│   ├── Categories/
│   │   ├── CategoryListView.swift
│   │   ├── CategoryDetailView.swift
│   │   └── CategoryViewModel.swift
│   ├── Tasks/
│   │   ├── TaskListView.swift
│   │   └── TaskViewModel.swift
│   ├── Goals/
│   │   ├── GoalListView.swift
│   │   ├── GoalDetailView.swift
│   │   └── GoalViewModel.swift
│   ├── Reflection/
│   │   ├── ReflectionFormView.swift
│   │   └── ReflectionViewModel.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── SettingsViewModel.swift
│   └── SharedComponents/
│       ├── ConsistencyGridView.swift   # Reusable heatmap grid
│       ├── StreakBadgeView.swift
│       ├── ProgressBarView.swift
│       ├── CategoryDotView.swift
│       └── BrutalistCard.swift         # Base card component
│
├── Widgets/
│   ├── StreakWidget/
│   ├── CategoryWidget/
│   └── TaskWidget/
│
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

---

## 4. SOLID Principles Application

| Principle | How it's applied |
|-----------|-----------------|
| **S** — Single Responsibility | Each use case does exactly one thing. Each view renders exactly one screen. |
| **O** — Open/Closed | New modules are added by creating new use cases and views. Existing code is not modified. |
| **L** — Liskov Substitution | Repository protocols are the contract. SwiftData implementations can be swapped (e.g., for testing with in-memory stores). |
| **I** — Interface Segregation | `CategoryRepository` only has category methods. Goals don't talk to `CategoryRepository`. |
| **D** — Dependency Inversion | ViewModels depend on use case protocols, not concrete implementations. Use cases depend on repository protocols, not SwiftData. |

---

## 5. Dependency Injection

A lightweight `AppEnvironment` struct (passed via SwiftUI environment) holds all concrete dependencies. No third-party DI framework.

```
AppEnvironment
├── categoryRepository: CategoryRepository (protocol)
├── taskRepository: TaskRepository (protocol)
├── goalRepository: GoalRepository (protocol)
├── reflectionRepository: ReflectionRepository (protocol)
├── notificationService: NotificationService
└── exportService: ExportService
```

At app launch, `AppEntry` wires real implementations into `AppEnvironment`. In tests, mock implementations are injected instead.

---

## 6. Data Flow

```
User Action (SwiftUI View)
        ↓
   ViewModel
        ↓
   Use Case
        ↓
Repository Protocol
        ↓
SwiftData (on-device)
        ↓
  (optional) CloudKit sync
```

Widget reads from shared App Group container (SwiftData or UserDefaults snapshot). It does not write.

---

## 7. State Management

- **SwiftUI + `@Observable` (Observation framework, iOS 17+)**
- No Combine, no Redux, no third-party state management
- ViewModels are `@Observable` classes
- Global app state (current date, selected tab) lives in `AppRouter`
- Domain entities are value types (structs) where possible

---

## 8. Persistence Strategy

| Data | Storage |
|------|---------|
| Categories, Tasks, Goals, Reflections | SwiftData ModelContainer |
| Widget data snapshot | App Group shared SwiftData or UserDefaults (lightweight) |
| User settings (reminder time, iCloud toggle) | `UserDefaults` |
| iCloud sync | SwiftData CloudKit backend (optional, user-controlled) |

**App Group identifier:** `group.com.[username].streak`  
Used to share data between the main app and widget extensions.

---

## 9. New Feature Addition Protocol

When adding a new feature module:

1. Define domain entity in `Domain/Entities/`
2. Define repository protocol in `Domain/Repositories/`
3. Write use cases in `Application/UseCases/[FeatureName]/`
4. Implement SwiftData repository in `Infrastructure/Persistence/`
5. Build SwiftUI view + ViewModel in `Presentation/[FeatureName]/`
6. Register in `AppEnvironment`
7. Add navigation entry in `AppRouter`
8. Write documentation in `docs/`

No existing file needs to be modified except `AppEnvironment` and `AppRouter`.

---

## 10. Testing Strategy

- Domain layer: pure Swift unit tests, no mocks needed
- Application layer: inject mock repositories, test use case logic
- Infrastructure layer: integration tests with in-memory SwiftData
- Presentation layer: SwiftUI previews + manual testing
- No UI test framework in v1 (no automation tooling overhead)

---

## 11. Additions — 2026-10-08

**Application layer (use cases)**
| Use case | Job |
|---|---|
| `ResolveDayStatusUseCase` | Now counts planned tasks only, handles rest days, keeps `.frozen` days, auto-uses a Streak Freeze (`allowAutoFreeze`) |
| `CalculateStreakUseCase` | Needs `settingsRepository`; counts from the active day, skips in-progress / rest / frozen days |
| `CalculateHabitStreakUseCase` | Per-habit streak + recent `HabitDay` states from the habit's tasks |
| `LogHealthSnapshotUseCase` | Upserts a day's Apple Health totals (nil fields keep stored values) |

**App layer (orchestration that needs the whole `AppEnvironment`)**
| Type | Job |
|---|---|
| `DaySweeper` | Single launch / foreground / background sweep (widget queue, habit tasks, Health rules, finalize ended days, today, goals, widgets) |
| `HealthSync` | Stores a Health snapshot and ticks habits whose `HealthRule` is met |
| `LogHealthDataIntent` | Shortcuts action feeding `HealthSync` |
| `DayCountdownActivityManager` | Starts / updates / ends the Lock Screen Live Activity |
| `AppEnvironment.setTaskCompleted` | The one task-completion flow (status, XP, badges, goals, widgets) used by Today, Tasks, the check-in, the widget queue and Health |
| `AppEnvironment.live(context:)` / `currentOrStandalone()` | Builds the environment; App Intents reuse the running app's instance |

**Infrastructure**: `BackupService` (SQLite `VACUUM INTO` snapshot + settings), `SwiftDataHealthSnapshotRepository`.
`CoreHabit` (entity, repository, DI) was removed; `CoreHabitModel` stays in the schema only so existing stores open without a destructive migration.
