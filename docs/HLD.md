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
Tab bar (5 tabs: Today · Tasks · Fitness · Finance · Profile)
    │
    ├── Today Tab (Home)
    │       ├── Gear → Settings sheet          + → New Category
    │       ├── Day-ends countdown
    │       ├── Today card: planned done X/Y, progress, tap-to-complete task list
    │       │       (BONUS tag on late tasks), ADD TASK → Tasks tab, CHECK-IN → End-of-Day Check-In sheet
    │       │                                   ├── Habit commitments: Followed / Not followed
    │       │                                   ├── Reflection: 1–5 rating, wins, what slipped, tomorrow's priorities
    │       │                                   └── Past Check-ins log
    │       ├── Backup reminder (when never backed up or > 14 days)
    │       ├── Overall card (streak, freezes ready, heatmap) → Overall History Screen
    │       ├── Habits (per-habit streak + 7-day strip) → Habit Commitments sheet
    │       ├── Goals (top 3 active) → Goal Detail;  ALL GOALS → Goal List Screen
    │       └── Category cards → Category Detail Screen
    │
    ├── Tasks Tab (Multi-Timeframe Planner)
    │       └── Task List Screen
    │                   ├── Header: title, missed-tasks review button, ⋯ menu (Habit commitments, Reorder)
    │                   ├── Segment Bar: DAILY | WEEKLY | MONTHLY | TO-DO LIST
    │                   ├── Daily Tab: Yesterday / Today / Tomorrow toggle, daily task list
    │                   ├── Weekly / Monthly / To-Do tabs with quick schedule pills
    │                   └── Add task bar (contextual input per timeframe tab)
    │
    ├── Fitness Tab (Workout & Nutrition)
    │       └── Apple Health card (Shortcuts sync) → Apple Health Sync guide
    ├── Finance Tab
    └── Profile Tab (XP, level, shop, badges, XP log, Settings button)

Settings (sheet)
    ├── Appearance theme
    ├── Active day cycle, planning window, rest days
    ├── Planning reminder + notification touchpoints (+ optional Gemini AI)
    ├── Lock Screen countdown (Live Activity)
    ├── Backup & Restore
    └── Danger Zone (reset all data)
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

## 6. Data Flow: Backup / Restore

```
Export (Settings → Backup & Restore → EXPORT):
BackupService.makeBackup
        ├── SQLite `VACUUM INTO` → consistent snapshot of the live SwiftData store
        ├── + App Group and app UserDefaults (settings)
        ├── Binary plist: { app, formatVersion, createdAt, store, appGroupDefaults, standardDefaults }
        └── SwiftUI fileExporter → user saves Streak-Backup-YYYY-MM-DD.plist to Files
              └── lastBackupDate recorded (drives the Today-screen backup reminder)

Restore (Settings → Backup & Restore → RESTORE):
fileImporter → BackupService.inspect (validates app + version + SQLite header)
        ├── Confirm: "replaces ALL current data"
        ├── BackupService.stageRestore → PendingRestore.plist next to the store
        └── App closes; on next launch (before the ModelContainer opens):
              BackupService.applyPendingRestoreIfNeeded
                    ├── current store moved to PreRestore/ (safety copy)
                    ├── snapshot written as default.store
                    └── settings restored (lastActiveDateString cleared so no gap days are penalised)
```

The store lives in the App Group container (`…/AppGroup/<id>/Library/Application Support/default.store`), so PendingRestore.plist and PreRestore/ live there too.

---

## 6b. Data Flow: Day Sweep

`DaySweeper.run` runs on launch, on every return to foreground, and from the background lockout task:

1. Apply task ticks queued by the interactive Tasks widget (`WidgetTaskToggleQueue`).
2. Generate today's habit-commitment tasks.
3. Finalize every day that ended since the last sweep: XP decay, automatic Streak Freeze.
4. Re-resolve today (planning-deadline lockout, rest days).
5. Sync goals → `syncWidgets()` → widgets, notifications (rebuilt from live data), Live Activity.

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
