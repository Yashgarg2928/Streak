# iOS Integrations
## Widgets, Shortcuts, Notifications, iCloud
## App: Streak (iOS Habit Tracker)
**Version:** 1.0  
**Date:** 2026-07-08  
**Status:** Draft

---

## 1. WidgetKit Integration

Widgets are separate app extension targets that share data with the main app via an **App Group** container. Widgets cannot directly access the main app's SwiftData store — they read from a shared snapshot.

### 1.1 Architecture

```
Main App
    └── On any data change:
            ├── Write lightweight snapshot to App Group UserDefaults or shared file
            └── Call WidgetCenter.shared.reloadAllTimelines()

Widget Extension
    └── TimelineProvider reads from App Group snapshot
            └── Renders SwiftUI widget view
```

The snapshot written to the App Group contains only what widgets need — no full entity graph.

### 1.2 Shared Widget Data Structure

```json
{
  "masterStreak": 47,
  "masterStatusToday": "green",
  "tasksToday": { "total": 5, "completed": 3 },
  "categories": [
    {
      "id": "uuid",
      "name": "Gym",
      "colorHex": "#E74C3C",
      "streak": 12,
      "statusToday": "green"
    }
  ],
  "lastUpdated": "2026-07-08T16:04:22Z"
}
```

### 1.3 Widget Inventory

#### Widget 1: Master Streak (Small)
- **Placement:** Home screen
- **Size:** Small (2×2)
- **Content:** Overall streak count + today's status color dot

```
┌─────────────────┐
│    STREAK       │  ← border in #1A1A1A
│      47         │  ← heavy font
│  🟢  Today      │  ← green/red dot
└─────────────────┘
```

#### Widget 2: Master Streak (Medium)
- **Placement:** Home screen
- **Size:** Medium (4×2)
- **Content:** Streak count + last 4 weeks mini-heatmap

```
┌──────────────────────────────────────┐
│  STREAK  🔥 47   ■ ■ □ ■ ■ ■ □ ■   │
│                  ■ □ ■ ■ ■ □ ■ ■   │
└──────────────────────────────────────┘
```

#### Widget 3: Today's Tasks (Medium)
- **Placement:** Home screen
- **Size:** Medium (4×2)
- **Content:** Today's task list, first 4 tasks, completion status

```
┌──────────────────────────────────────┐
│  TODAY — 3/5 tasks                   │
│  ✓ ● Gym   Morning workout           │
│  ○ ● Reading  Read 20 pages          │
│  ○ ○ —   Call parents                │
└──────────────────────────────────────┘
```

Tapping opens the Tasks screen in the main app (deep link).

#### Widget 4: Category Widget (Small)
- **Placement:** Home screen
- **Size:** Small (2×2)
- **Content:** Single category streak + status dot
- **User configurable:** Which category to show (widget configuration via `IntentConfiguration`)

```
┌─────────────────┐
│  GYM            │  ← border in category color
│     12          │
│  🟢  Today      │
└─────────────────┘
```

#### Widget 5: Lock Screen Streak (Accessory Rectangular)
- **Placement:** Lock screen
- **Content:** "🔥 47d | 3/5 tasks today"

#### Widget 6: Lock Screen Day Status (Accessory Circular)
- **Placement:** Lock screen
- **Content:** Streak number in center, colored ring (green/red) as border

#### Widget 7: Multi-Category Widget (Small & Medium)
- **Placement:** Home screen
- **Size:** Small (2×2), Medium (4×2)
- **Content:** Compact list of category names and their current streak counts.
- **User Configurable:** Pick which categories to display. Defaults to all active categories if none are selected.

#### Widget 8: Goal Widget (Medium)
- **Placement:** Home screen
- **Size:** Medium (4×2)
- **Content:** Displays a selected goal's progress bar, completion metrics, and deadline. styled exactly like the in-app goal card.
- **User Configurable:** Select which specific Goal to display.

### 1.3a Interactive Tasks Widget

The medium/large Tasks widget checkboxes are `Button(intent: ToggleWidgetTaskIntent)` (StreakWidgets/ToggleWidgetTaskIntent.swift).
The widget extension can't run the app's completion flow, so the intent:
1. flips the item in the cached `WidgetData` immediately (instant visual feedback), and
2. appends the change to `WidgetTaskToggleQueue` in App Group UserDefaults.

`DaySweeper` drains the queue on the next launch / foreground / background sweep and applies each tick through
`AppEnvironment.setTaskCompleted` (day status, XP, badges, goals). Streak counts and status dots in widgets update
once the app has applied the queue.

### 1.3b Day Countdown Live Activity

`DayCountdownLiveActivity` (widget extension) + `DayCountdownActivityManager` (app) + shared `DayCountdownAttributes`.
- Shows planned tasks done / total, streak, and a countdown to the end of the active day on the Lock Screen and Dynamic Island.
- Shown whenever the active day has open planned tasks; updated on every `syncWidgets()`. iOS only allows starting one
  from the foreground or a `LiveActivityIntent`, and ends it after ~8 hours, so it (re)starts when the app opens, when the
  active day rolls over while the app is open, or when **Show Day Countdown** (`StartDayCountdownIntent`, Siri: "Start my
  Streak countdown") or **Log Health Data in Streak** runs from Shortcuts. A morning automation keeps it on all day.
- Ends 15 minutes after the day turns green / rest / frozen, or immediately when disabled in Settings.
- Requires `NSSupportsLiveActivities = YES` (Info.plist). No push entitlement needed (local updates only).

### 1.4 Widget Tap → Deep Link

Every widget tap opens the main app at a specific screen using URL scheme deep links:

| Widget | Tap destination |
|--------|----------------|
| Master streak | Home screen |
| Today's tasks | Tasks screen |
| Category widget | Category detail screen |
| Lock screen | Home screen |

URL scheme: `streak://`  
Examples: `streak://home`, `streak://tasks`, `streak://category/{uuid}`

---

## 2. Shortcuts Integration (App Intents)

The App Intents framework (iOS 16+) exposes app actions to:
- iOS Shortcuts app
- Siri
- Spotlight
- Lock screen buttons (iOS 16+ Action button on iPhone 15 Pro+)

### 2.1 Intent Inventory (v1)

All intents are defined as Swift structs conforming to `AppIntent`.

#### Intent 1: `LogTaskCompletion`
- **Description:** Mark a specific task as done for today
- **Parameters:** Task title (fuzzy matched), or task selection from list
- **Result:** Confirmation text "Marked '[task]' as complete ✓"
- **Use case:** Morning routine automation — one Shortcut taps through multiple habits

#### Intent 2: `GetTodayStreak`
- **Description:** Returns the current master streak count
- **Parameters:** None
- **Result:** Number (usable in Shortcuts conditionals) + "Your streak is 47 days"
- **Use case:** Shortcuts widget or Siri query "Hey Siri, what's my streak?"

#### Intent 3: `GetCategoryStreak`
- **Description:** Returns streak for a specific category
- **Parameters:** Category name (dynamic options list from app data)
- **Result:** Number + display string
- **Use case:** "Hey Siri, what's my gym streak?"

#### Intent 4: `OpenTodayTasks`
- **Description:** Deep-links to the Tasks screen
- **Parameters:** None
- **Result:** Opens app at tasks screen
- **Use case:** Morning Shortcut "Start my day" → opens tasks

#### Intent 5: `AddTask`
- **Description:** Creates a new task for today or tomorrow
- **Parameters:** Task title (text), Category (optional, dynamic list), Target date (today/tomorrow)
- **Result:** Confirmation "Added '[task]' to today's list"
- **Use case:** Ask Siri to add a task hands-free while driving

#### Intent 6: `GetGoalProgress`
- **Description:** Returns progress % for a named goal
- **Parameters:** Goal name (dynamic options list)
- **Result:** Percentage + "You're 67% toward '[goal]'"
- **Use case:** Shortcuts automation — show goal progress as part of morning briefing

### 2.2 Shortcut Suggestions

The app provides "Suggested Shortcuts" that appear in Spotlight and the Shortcuts gallery automatically (via `AppShortcutsProvider`).

Suggested shortcuts shown to user on first launch or via Settings:
- "Log my morning workout" → `LogTaskCompletion` for Gym category tasks
- "What's my streak today?" → `GetTodayStreak`
- "Add a task" → `AddTask`

### 2.3 Siri Integration

App Intents are automatically available to Siri with no additional configuration. The app name "Streak" acts as the invocation phrase.

Examples:
- "Hey Siri, open Streak tasks"
- "Hey Siri, log my gym workout in Streak"
- "Hey Siri, what's my reading streak in Streak?"

### 2.4 Future Shortcuts Expansion

The App Intents structure is designed to accept new intents by adding new `AppIntent` structs. No existing intents need modification. Planned future intents:
- `LogGoalProgress` (milestone goals)
- `SaveReflection` (quick note to Daily Assist)
- `GetWeekSummary`
- `ToggleCategory` (pause/resume a category)

---

## 3. Notification System

All notifications are **local**. No push notification server.

> **Current scheduling model (SpicyNotificationScheduler):** notifications are one-shot requests for the current and
> next active day, rebuilt (debounced) after every data change via `syncWidgets()`. Messages always carry the live
> streak / pending count. Mid-day nudge and "last call" (1h before the day ends) are skipped once the day is green,
> rest or frozen; nothing but the planning reminder fires on rest days; the planning reminder is skipped when the next
> day already has tasks. Optional Gemini messages use the `gemini-flash-latest` alias (API key sent in the
> `x-goog-api-key` header) and are cached so there's at most one AI call per touchpoint per day.

### 3.1 Notification Types

#### Type 1: Planning Reminder
- **Purpose:** Prompt user to set the upcoming active day's tasks
- **Trigger:** User-defined time (e.g., 10:00 PM), daily. Defaults to 1 hour before the user's `Active End Time`.
- **Repeat behavior:** If no tasks have been planned for the upcoming active day after the reminder fires, follow-up notifications repeat every **5 minutes** up to the active day deadline.
- **Stop condition:** As soon as at least one task is created for the upcoming active day, all pending planning notifications are cancelled.
- **Deadline rollover behavior:** At the user's custom `Active End Time` (deadline), if no tasks were scheduled/completed for the day that just ended, the app's rollover sweep marks the day as Missed (Red).

**Notification content:**
```
Title:  ⏰ Plan Your Active Day
Body:   Set your goals before your active day deadline passes!
Action: Tap → opens AddTask screen for the upcoming active day
```

**Repeat scheduling logic:**
- On planning reminder fire: schedule follow-up notifications at 5-minute intervals up to the active day's deadline.
- On task creation: `UNUserNotificationCenter.removeDeliveredNotifications` + `removePendingNotificationRequests` for all planning identifiers.

#### Type 2: Daily Assist (Reflection)
- **Purpose:** Prompt nightly reflection
- **Trigger:** User-defined time (e.g., 10:30 PM), daily
- **Repeat:** Once per day, does not repeat if dismissed
- **Action:** Tap → opens ReflectionFormView as a full-screen sheet

**Notification content:**
```
Title:  📓 Daily Assist
Body:   Time to reflect. How did today go?
Action: Tap → opens reflection form
```

**Actionable notification buttons (iOS inline actions):**
```
[Open Reflection Form]   ← primary action, opens app
[Remind in 30 min]       ← schedules one more notification 30 minutes later
```

#### Type 3: Goal Progress Nudge
- **Purpose:** Remind user to log manual goal progress
- **Trigger:** Per-goal user-set time (optional, enabled per goal in goal settings)
- **Repeat:** Once per day
- **Action:** Tap → opens Goal Detail screen for that goal

**Notification content:**
```
Title:  🎯 [Goal Name]
Body:   Log today's progress toward your goal.
```

### 3.2 Notification Permission

Requested on first launch during onboarding. If denied:
- App still functions fully
- Reminders section in Settings shows "Notifications disabled — tap to enable in Settings"
- Deep link to iOS Settings notification page provided

### 3.3 Notification Identifiers

All notification identifiers follow a structured format to allow targeted cancellation:

```
planning-reminder-[date]          e.g. planning-reminder-2026-07-08
planning-followup-[date]-[n]      e.g. planning-followup-2026-07-08-3
daily-assist-[date]               e.g. daily-assist-2026-07-08
goal-nudge-[goalId]-[date]        e.g. goal-nudge-uuid-2026-07-08
```

---

## 4. iCloud Sync

### 4.1 How It Works

SwiftData natively supports CloudKit as a backend. When iCloud sync is enabled, the same SwiftData `ModelContainer` that stores local data also syncs to the user's private iCloud CloudKit database.

- Data is stored in the user's **private** iCloud container — not visible to the developer, not shared between users
- Sync is automatic and handled by Apple's CloudKit framework
- Conflict resolution is handled by CloudKit (last-write-wins per field)
- Works on the same Apple ID across multiple devices (if user has two iPhones or uses iPad)

### 4.2 User Controls

- Toggle in Settings: "Sync to iCloud" (default: off)
- When toggled on: SwiftData migrates to a CloudKit-backed container
- When toggled off: Data remains on device, iCloud copy is not deleted (user manages via iCloud settings)
- Sync status indicator in Settings: "Last synced: 5 minutes ago" / "Sync paused (offline)"

### 4.3 Privacy

- iCloud sync uses the user's own Apple ID
- Data is end-to-end encrypted in iCloud (Apple's private database)
- The developer has zero access to any user's iCloud data
- No shared CloudKit container — each user's data is in their own private container

---

## 5. Backup & Restore

Settings → **Backup & Restore**.
- **Export:** `BackupService.makeBackup` snapshots the SwiftData SQLite store with `VACUUM INTO` (safe while the app runs)
  and bundles it with the app's settings into a binary plist, saved via SwiftUI's `fileExporter` as
  `Streak-Backup-YYYY-MM-DD.plist`. Save it off the phone (iCloud Drive, Google Drive, AirDrop to a Mac).
- **Restore:** pick the file with `fileImporter` → validated → staged next to the store → the app closes and applies it on
  the next launch before the database opens. The previous data is kept in `PreRestore/` beside the store.
- The Today screen shows a reminder when you've never backed up (and have a few days of history) or the last backup is
  more than 14 days old.

---

## 6. Background App Refresh

The app registers a `BGProcessingTask` for the **midnight sweep** — marking days as red if no tasks were set before midnight.

**Task identifier:** `com.[username].streak.midnightsweep`

This runs when iOS decides to schedule background tasks (typically overnight when device is charging and on Wi-Fi). It is not guaranteed to run at exactly midnight — but will run within a reasonable window.

If background refresh is disabled by the user, the sweep runs the next time the app is opened (compensatory sweep on app foreground).

---

## 7. Guided Access & Screen Time

### 7.1 Guided Access
Guided Access is a built-in iOS feature (Settings → Accessibility → Guided Access). It locks the iPhone to a single app. The Streak app itself does not need to implement anything — the user enables Guided Access system-wide. The app will support being used in Guided Access mode without any crashes or unexpected behavior.

### 7.2 Screen Time API
The Screen Time API (`ManagedSettings` framework, iOS 15+) allows apps to apply screen restrictions programmatically. This requires the **Family Controls** entitlement, which Apple grants only to approved App Store apps.

**Current status:**
- Screen Time API is **not available** for sideloaded apps (requires App Store entitlement approval)
- The app will not implement Screen Time API in v1
- This feature is documented as a future module — if the app ever goes to the App Store, it can be pursued
- Guided Access (which requires no special entitlement) serves as the available alternative

---

## 8. Permissions Summary

| Permission | When requested | Required? |
|------------|---------------|-----------|
| Notifications | First launch onboarding | Strongly recommended |
| iCloud | When user enables sync in Settings | Optional |
| Background App Refresh | First launch | Recommended for midnight sweep |
| No camera, location, contacts, or microphone | — | Not needed |

---

## 9. Apple Health via Shortcuts

Streak can't use HealthKit: the entitlement isn't available to free Apple ID signing (AltStore). Instead:

- **`LogHealthDataIntent`** ("Log Health Data in Streak", App/HealthAppIntents.swift) — optional Number parameters
  Steps, Active Energy (kcal), Exercise Minutes, Workouts, Workout Minutes. Runs without opening the app and reuses the
  running app's `AppEnvironment` when there is one.
- The user's own shortcut reads Health (**Find Health Samples** + **Calculate Statistics → Sum** / **Count**) and passes
  the totals; a **Time of Day** automation (optionally **Apple Watch Workout → Ends**) runs it. Setup steps live in the
  in-app guide (Fitness → Apple Health → SET UP).
- `HealthSync` stores a `HealthSnapshot` for the active day and ticks every habit whose `HealthRule` is met through
  `AppEnvironment.setTaskCompleted`. `DaySweeper` re-applies the rules on launch so habits created later still tick.
