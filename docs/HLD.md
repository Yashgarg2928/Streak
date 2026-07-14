# High-Level Design (HLD)
## App: Streak (iOS Habit Tracker)
**Version:** 1.0  
**Date:** 2026-07-08  
**Status:** Draft

---

## 1. System Overview

Streak is a fully local iOS application. There are no servers, no APIs, no network calls. The entire system runs inside a single iPhone.

```
┌─────────────────────────────────────────────────────────┐
│                        iPhone                           │
│                                                         │
│  ┌─────────────┐    ┌──────────────┐   ┌────────────┐  │
│  │  Main App   │    │   Widgets    │   │  Shortcuts │  │
│  │  (SwiftUI)  │    │ (WidgetKit)  │   │ (AppIntents│  │
│  └──────┬──────┘    └──────┬───────┘   └─────┬──────┘  │
│         │                  │                  │         │
│         └──────────────────┼──────────────────┘         │
│                            │                            │
│                   ┌────────▼────────┐                   │
│                   │  App Group      │                   │
│                   │  (Shared Data)  │                   │
│                   └────────┬────────┘                   │
│                            │                            │
│                   ┌────────▼────────┐                   │
│                   │   SwiftData     │                   │
│                   │ (Local SQLite)  │                   │
│                   └────────┬────────┘                   │
│                            │ (optional)                 │
│                   ┌────────▼────────┐                   │
│                   │    iCloud       │                   │
│                   │  (CloudKit sync)│                   │
│                   └─────────────────┘                   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │            UNNotificationCenter                 │    │
│  │  (Planning reminders + Daily Assist prompts)    │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Component Breakdown

### 2.1 Main App
The primary SwiftUI application target. Contains all screens, business logic, and data management.

**Responsibilities:**
- All CRUD operations on categories, tasks, goals, reflections
- Rendering consistency graphs and streaks
- Task completion and day-status resolution
- Goal progress tracking
- Settings management
- Data export and import

### 2.2 Widget Extension
A separate app extension target sharing the App Group container.

**Widget types:**
| Widget | Sizes | Placement |
|--------|-------|-----------|
| Master Streak | Small, Medium | Home screen |
| Category Streak | Small, Medium | Home screen |
| Today's Tasks | Medium, Large | Home screen |
| Streak Counter | Small | Lock screen (accessory rectangular) |
| Day Status | Small | Lock screen (accessory circular) |

Widgets are **read-only**. They display data from the shared container. Tapping a widget deep-links into the main app.

### 2.3 Shortcuts Extension (App Intents)
Exposes app actions to the iOS Shortcuts app.

**Intents (v1):**
| Intent | Description |
|--------|-------------|
| `LogTaskCompletion` | Mark a specific task as done |
| `GetTodayStreak` | Returns current master streak count |
| `GetCategoryStreak` | Returns streak for a named category |
| `OpenTodayTasks` | Deep-link opens today's task list |
| `AddTask` | Creates a new task for today or tomorrow |
| `GetGoalProgress` | Returns progress % for a named goal |

Future intents will be added as new App Intent structs without touching existing ones.

### 2.4 Notification System
Uses `UNUserNotificationCenter`. All notifications are local (no push server).

**Notification types:**
| Type | Trigger | Repeat |
|------|---------|--------|
| Planning Reminder | User-set time | Every 5 min until tasks added |
| Daily Assist | User-set time | Once per day |
| Goal Progress Nudge | User-set time per goal | Once per day |

### 2.5 Data Layer (SwiftData)
Single `ModelContainer` with all entities. Optionally backed by CloudKit for iCloud sync.

App Group shared container provides a read-only snapshot for widgets.

### 2.6 Export / Import
- **Export:** `JSONEncoder` serializes all entities → user shares via share sheet (AirDrop, Files, etc.)
- **Import:** User picks a `.streak` JSON file → `JSONDecoder` restores all data
- File extension: `.streak`
- File format: JSON (human-readable, version-tagged)

---

## 3. Screen Map

```
App Launch
    │
    ▼
Home Screen
    ├── Master Consistency Graph
    ├── Master Streak Counter
    ├── Overall Card
    │       └── Tap → Overall History Screen
    │                   ├── Line Graph (Completion rate 0% - 100%, scrollable 1 month width)
    │                   └── Task List (grouped by category for the selected day)
    ├── Category Cards (horizontal scroll or grid)
    │       └── Tap → Category Detail Screen
    │                   ├── Category Consistency Graph
    │                   ├── Category Streak Counter
    │                   └── Linked Goals
    │
    ├── Today's Tasks (floating button or tab)
    │       └── Task List Screen
    │                   ├── Tasks grouped by category color dot
    │                   ├── Check/uncheck tasks
    │                   └── Add task (quick entry)
    │
    ├── Goals Tab
    │       └── Goal List Screen
    │                   └── Tap → Goal Detail Screen
    │                               ├── Progress bar
    │                               ├── History log
    │                               └── Log progress (manual)
    │
    ├── Reflection Tab (Daily Assist)
    │       └── Reflection Log Screen
    │                   └── Tap date → Reflection Entry View
    │
    └── Settings Tab
            ├── Planning Reminder time
            ├── Daily Assist time
            ├── iCloud sync toggle
            ├── Export data
            ├── Import data
            └── Manage Categories (create, edit, archive, reorder)
```

---

## 4. Data Flow: Task Completion → Day Status

```
User checks a task
        │
        ▼
CompleteTaskUseCase
        │
        ├── Mark task as completed in SwiftData
        │
        ├── ResolveDayStatusUseCase(category, date)
        │       │
        │       ├── Fetch all tasks for category on that date
        │       ├── If all tasks completed → DayStatus = .green
        │       └── Else → DayStatus = .red
        │
        ├── ResolveDayStatusUseCase(master, date)
        │       │
        │       ├── Fetch all tasks for all categories on that date
        │       ├── If all tasks in all categories + uncategorized completed → .green
        │       └── Else → .red
        │
        ├── CalculateStreakUseCase(category)
        │       └── Walk backward from today, count consecutive .green days
        │
        ├── Update App Group shared container (for widget refresh)
        │
        └── Trigger WidgetCenter.shared.reloadAllTimelines()
```

---

## 5. Data Flow: Nightly Planning Reminder

```
System time reaches user's planning reminder time
        │
        ▼
UNNotificationCenter fires scheduled notification
        │
        ▼
User sees notification: "Set your goals for tomorrow"
        │
        ├── [User adds tasks] → repeat notifications CANCELLED
        │
        └── [User ignores] → notification repeats every 5 minutes
                │
                └── [Midnight passes, no tasks set]
                        │
                        └── ResolveDayStatusUseCase marks all categories RED
```

---

## 6. Data Flow: Export / Import

```
Export:
User taps "Export Data"
        │
        ▼
ExportDataUseCase
        ├── Fetch all entities from SwiftData
        ├── Serialize to ExportPayload struct
        ├── JSONEncoder → Data
        ├── Write to temp file: backup_2026-07-08.streak
        └── Present UIActivityViewController (share sheet)

Import:
User taps "Import Data"
        │
        ▼
UIDocumentPickerViewController (pick .streak file)
        │
        ▼
ImportDataUseCase
        ├── JSONDecoder → ExportPayload struct
        ├── Validate version compatibility
        ├── [Warn: this will replace all current data]
        ├── User confirms
        ├── Clear existing SwiftData store
        └── Write all entities from payload to SwiftData
```

---

## 7. Key Technical Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| UI framework | SwiftUI | Native, best widget support, best Shortcuts integration |
| State management | `@Observable` (iOS 17+) | No overhead, native, sufficient for app size |
| Persistence | SwiftData | Native, replaces CoreData boilerplate, CloudKit ready |
| iCloud sync | SwiftData + CloudKit | Zero backend, Apple manages sync conflicts |
| Notifications | `UNUserNotificationCenter` | Local only, no server needed |
| Widgets | WidgetKit | iOS native, supports home + lock screen |
| Shortcuts | App Intents | Modern API, replaces legacy SiriKit intents |
| No Combine | ✓ | `@Observable` covers all reactive needs |
| No third-party libs | ✓ | Reduces signing complexity for sideloaded app |
| No Redux/TCA | ✓ | Overkill for a single-user local app |

---

## 8. iOS Version Requirements

| Feature | Minimum iOS |
|---------|-------------|
| SwiftUI base | iOS 14+ |
| `@Observable` macro | iOS 17+ |
| SwiftData | iOS 17+ |
| Lock screen widgets | iOS 16+ |
| App Intents (Shortcuts) | iOS 16+ |
| **Target minimum** | **iOS 17** |

iOS 17 is the floor. This covers all iPhones XS and newer running the latest software.

---

## 9. Security & Privacy

- No network access (zero data leaves the device without explicit user action)
- iCloud sync uses Apple's encrypted iCloud infrastructure
- Export file is plaintext JSON — user is responsible for where they send it
- No analytics, no crash reporting, no telemetry
- App entitlements: `com.apple.developer.icloud-container-identifiers` (optional), `com.apple.security.application-groups`
