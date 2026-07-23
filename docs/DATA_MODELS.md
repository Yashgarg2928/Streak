# Data Models and Flow
## App: Streak (iOS Habit Tracker)
**Version:** 1.0  
**Date:** 2026-07-08  
**Status:** Draft

---

## 1. Entity Relationship Diagram

```
┌──────────────┐        ┌──────────────┐
│   Category   │──────<>│     Task     │
└──────────────┘  0..*  └──────────────┘
        │                      │
        │ 0..*                 │ resolves
        ▼                      ▼
┌──────────────┐        ┌──────────────┐
│   DayEntry   │        │   DayStatus  │
│ (per-cat)    │        │  (value obj) │
└──────────────┘        └──────────────┘
        
┌──────────────┐        ┌──────────────┐
│    Goal      │────────│   Category   │
│              │  0..1  │  (optional)  │
└──────────────┘        └──────────────┘
        │
        │ 1..*
        ▼
┌──────────────┐
│ GoalProgress │
│   Entry      │
└──────────────┘

┌──────────────────┐
│ ReflectionEntry  │
│  (per day, once) │
└──────────────────┘

┌──────────────┐
│   Settings   │
│  (singleton) │
└──────────────┘
```

---

## 2. Domain Entities

### 2.1 Category

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `name` | String | User-defined, e.g. "Gym" |
| `colorHex` | String | Hex color string e.g. "#E74C3C" |
| `createdAt` | Date | When category was created |
| `isArchived` | Bool | Archived categories hidden from UI but data preserved |
| `sortOrder` | Int | User-defined ordering |

**Business rules:**
- `name` must be non-empty
- `colorHex` must be a valid 6-char hex color
- Archived categories do not accept new tasks
- Archiving a category does not delete historical DayEntry records

---

### 2.2 Task

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `title` | String | Task description text |
| `categoryId` | UUID? | Optional link to a Category. Nil = uncategorized |
| `targetDate` | Date | The day this task is for (date only, no time) |
| `timeframe` | TaskTimeframe | `.daily`, `.weekly`, `.monthly`, or `.backlog` |
| `isCompleted` | Bool | Whether the user checked this off |
| `completedAt` | Date? | Timestamp when task was completed |
| `createdAt` | Date | When task was created |
| `isDeleted` | Bool | Soft-delete flag (excluded from streaks & stats) |

**TaskTimeframe Enum:**
```swift
enum TaskTimeframe: String, Codable, CaseIterable {
    case daily     // Scheduled for specific day (targetDate)
    case weekly    // Current week goal/task
    case monthly   // Current month goal/task
    case backlog   // Timeline-free To-Do list item
}
```

**Business rules:**
- `title` must be non-empty
- `targetDate` stores date only (time component truncated to midnight)
- Soft-deleted tasks (`isDeleted == true`) display at the bottom of lists and do not affect streak calculations or day statuses
- Non-daily tasks (`.weekly`, `.monthly`, `.backlog`) do not affect daily streak calculations unless scheduled/promoted to `.daily`
- Completing a daily task triggers `ResolveDayStatusUseCase` for its category and the master
- Tasks can be scheduled/promoted across timeframes (e.g. from `.weekly` or `.backlog` to `.daily` for Today/Tomorrow) at any time

---

### 2.3 DayEntry

Computed and cached record of a day's completion status per category and master.

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `date` | Date | Date only (midnight) |
| `categoryId` | UUID? | Nil = master entry |
| `status` | DayStatus | .green / .red / .future |
| `taskCount` | Int | Total tasks set for this day in this scope |
| `completedCount` | Int | Tasks completed |
| `lastUpdated` | Date | When this entry was last recomputed |

**Note:** DayEntry is a materialized cache. It is recomputed whenever tasks change. The source of truth is always the Task table.

**DayStatus (Value Object):**
```
enum DayStatus {
    case green      // all tasks completed
    case red        // tasks existed but incomplete, OR no tasks were set
    case future     // date is in the future
}
```

**Red day rule:**
- `taskCount == 0` AND date <= today → `.red`
- `taskCount > 0` AND `completedCount < taskCount` → `.red`
- `completedCount == taskCount` AND `taskCount > 0` → `.green`
- date > today → `.future`

---

### 2.4 Goal

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `title` | String | Goal description |
| `goalType` | GoalType | `.consistencyLinked` / `.milestoneBased` / `.custom` |
| `categoryId` | UUID? | Optional link to a Category |
| `targetValue` | Double | The finish-line number (days, money, units) |
| `currentValue` | Double | Current progress (auto or manual) |
| `unit` | String | Display unit e.g. "days", "₹", "km" |
| `startDate` | Date | Start date |
| `targetDate` | Date? | Optional deadline |
| `isCompleted` | Bool | Whether goal has been achieved |
| `createdAt` | Date | Creation timestamp |
| `dailyNotificationTime` | Date? | Optional daily nudge time |

**GoalType (Value Object):**
```
enum GoalType {
    case consecutiveStreak   // progress = current consecutive streak count (resets to 0 on miss)
    case cumulativeDays      // progress = total count of green days since start (pauses on miss)
    case milestoneBased      // user logs progress manually over time (accumulative)
    case taskCounter         // progress = count of tasks completed in linked category (pauses on miss)
}
```

**Business rules:**
- For `.consecutiveStreak` goals: `currentValue` is auto-updated from the linked category's active streak count. If the category streak resets to 0, this goal's `currentValue` also drops to 0.
- For `.cumulativeDays` goals: `currentValue` is auto-updated by counting the total number of successful (`.green`) days for the category since the goal's `startDate`. Missed days pause progress but do not reset it.
- For `.taskCounter` goals: `currentValue` is auto-updated by counting the total number of tasks completed within the linked category since the goal's `startDate`.
- For `.milestoneBased` goals: user manually logs progress values via `LogGoalProgressUseCase`.
- `currentValue` never exceeds `targetValue` in UI display (capped at 100%).
- A goal is marked `isCompleted = true` when `currentValue >= targetValue`.

---

### 2.5 GoalProgressEntry

One record per day per milestone goal (manual log).

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `goalId` | UUID | Links to Goal |
| `date` | Date | Date of entry |
| `value` | Double | Value logged on this day (cumulative total, not delta) |
| `note` | String? | Optional note for this entry |
| `createdAt` | Date | Timestamp |

**Business rules:**
- One entry per goal per day (upsert — if user logs twice in a day, the second replaces the first)
- `value` is the absolute current total, not the daily increment

---

### 2.6 ReflectionEntry

One per day. User fills this via the Daily Assist form.

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `date` | Date | Date only (midnight) |
| `accomplishments` | String | Free text |
| `missedItems` | String | Free text |
| `tomorrowPriorities` | String | Free text |
| `goalNotes` | String | Free text |
| `consistencyRating` | Int | 1–5 |
| `createdAt` | Date | When form was first saved |
| `updatedAt` | Date | Last edit timestamp |

**Business rules:**
- One entry per calendar day (upsert)
- All fields except `date` are optional (user can save partial entries)
- Historical entries are read-only after 24 hours (cannot edit yesterday's reflection)

---

### 2.7 Settings (Singleton)

Stored in `UserDefaults`. Not a SwiftData entity.

| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `activeDayStartHour` | Int | 7 | Wake time hour (0-23) |
| `activeDayStartMinute` | Int | 0 | Wake time minute (0-59) |
| `activeDayEndHour` | Int | 23 | Deadline hour (0-23) |
| `activeDayEndMinute` | Int | 30 | Deadline minute (0-59) |
| `planningReminderHour` | Int | 22 | Planning reminder hour (0-23) |
| `planningReminderMinute` | Int | 0 | Planning reminder minute (0-59) |
| `isInterCalendarEnabled` | Bool | true | Spans active wake cycle across midnight (allows end time < start time) if true |
| `planningWindowMode` | String | "currentDay" | "currentDay" (plan morning of) or "previousDay" (plan night before) |
| `planningDeadlineHour` | Int | 10 | Planning window deadline hour (0-23) |
| `planningDeadlineMinute` | Int | 0 | Planning window deadline minute (0-59) |
| `dailyAssistHour` | Int | 22 | Reflection reminder hour (0-23) |
| `dailyAssistMinute` | Int | 30 | Reflection reminder minute (0-59) |
| `iCloudSyncEnabled` | Bool | false | Triggers SwiftData CloudKit backend |
| `isOnboardingCompleted` | Bool | false | True if user configured active times |
| `lastKnownTimeZone` | String | device default | For tracking time zone travel shifts |
| `timezoneGraceExtension` | Double | 0.0 | Grace extension time (seconds) |
| `appGroupIdentifier` | String | group.com.madhvan.streak | Shared container group suite identifier |

---

## 3. Export / Import Data Model

The export payload wraps all entities into a single versioned JSON structure.

```json
{
  "exportVersion": 1,
  "exportedAt": "2026-07-08T16:04:22Z",
  "categories": [ ... ],
  "tasks": [ ... ],
  "dayEntries": [ ... ],
  "goals": [ ... ],
  "goalProgressEntries": [ ... ],
  "reflectionEntries": [ ... ]
}
```

**Versioning rules:**
- `exportVersion` increments when the schema changes
- `ImportDataUseCase` checks version compatibility before proceeding
- Older export files are migrated forward (migration function per version bump)
- File extension: `.streak`

---

## 4. Key Data Flows

### 4.1 Creating a Category

```
User input: name + color
        ↓
CreateCategoryUseCase
        ├── Validate: name non-empty
        ├── Validate: color is valid hex, sufficient contrast against paper bg
        ├── Set sortOrder = max(existing) + 1
        └── Persist to SwiftData
```

### 4.2 Adding a Task

```
User input: title + targetDate + optional categoryId
        ↓
AddTaskUseCase
        ├── Validate: title non-empty
        ├── Validate: targetDate is today or tomorrow (v1 constraint)
        ├── Validate: if categoryId provided, category exists and is not archived
        ├── Persist Task to SwiftData
        └── ResolveDayStatusUseCase → recompute DayEntry for (date, categoryId) and (date, master)
```

### 4.3 Completing a Task

```
User taps checkbox
        ↓
CompleteTaskUseCase(taskId)
        ├── Set task.isCompleted = true, task.completedAt = now()
        ├── Persist to SwiftData
        ├── ResolveDayStatusUseCase(categoryId, date)
        │       └── Recompute and persist DayEntry
        ├── ResolveDayStatusUseCase(nil, date) [master]
        │       └── Recompute and persist master DayEntry
        ├── CalculateStreakUseCase(categoryId) → update streak display
        ├── CalculateStreakUseCase(nil) → update master streak display
        └── WidgetCenter.shared.reloadAllTimelines()
```

### 4.4 Streak Calculation

```
CalculateStreakUseCase(categoryId: UUID?)
        ├── Fetch all DayEntry records for categoryId (or master if nil)
        ├── Sort by date descending
        ├── Walk backward from today
        │       ├── If DayEntry.status == .green → streak++
        │       └── If DayEntry.status == .red → STOP
        └── Return streak count
```

**Edge case:** If today has no DayEntry yet (no tasks set for today), today counts as a potential break — the streak shows count up to yesterday. Today turns green only when all today's tasks are completed.

### 4.5 Midnight Sweep

A background task runs at or after midnight to mark any days that ended without tasks as `.red`.

```
Background task triggers after midnight
        ↓
MidnightSweepUseCase
        ├── For yesterday's date:
        │       ├── Fetch all categories
        │       └── For each category: ResolveDayStatusUseCase(categoryId, yesterday)
        ├── ResolveDayStatusUseCase(nil, yesterday) [master]
        └── WidgetCenter.shared.reloadAllTimelines()
```

This ensures red days are recorded even if the user never opened the app.

---

## 5. SwiftData Schema Summary

```
@Model Category
@Model Task
@Model DayEntry
@Model Goal
@Model GoalProgressEntry
@Model ReflectionEntry
```

All models live in the same `ModelContainer`.  
The App Group shared container exposes a lightweight read-only snapshot for widgets (to avoid widget extension writing to the main store).

---

## 6. Data Integrity Rules

| Rule | Enforcement |
|------|-------------|
| No orphaned tasks (category deleted) | Category archival only — no hard delete |
| No duplicate DayEntry per (date, categoryId) | Unique constraint + upsert in use case |
| No reflection entry older than today editable | `updatedAt` check in `SaveReflectionUseCase` |
| GoalProgressEntry: one per goal per day | Upsert logic in `LogGoalProgressUseCase` |
| Tasks only for today or tomorrow | Validated in `AddTaskUseCase` |
| Color contrast enforcement | Minimum luminance difference validated on input |
