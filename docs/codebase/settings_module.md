# Settings & Onboarding Module

This module documents the user onboarding flow, active day configuration settings, custom date rollover calculations, and related notification triggers.

---

## 1. Data Schema (UserDefaults)

Settings are persisted in the shared App Group `UserDefaults` (`group.com.madhvan.streak`) to allow both the main application target and the widget target to access date boundaries in real time.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `activeDayStartHour` | Int | `7` | Hour of active day start (0-23) |
| `activeDayStartMinute` | Int | `0` | Minute of active day start (0-59) |
| `activeDayEndHour` | Int | `23` | Hour of active day end/deadline (0-23) |
| `activeDayEndMinute` | Int | `30` | Minute of active day end/deadline (0-59) |
| `planningReminderHour` | Int | `22` | Hour of nightly planning reminder (0-23) |
| `planningReminderMinute` | Int | `0` | Minute of nightly planning reminder (0-59) |
| `isInterCalendarEnabled` | Bool | `true` | True if active day spans across calendar midnight (e.g. 7 AM to 2 AM) |
| `planningWindowMode` | String | `"currentDay"` | `"currentDay"` (plan morning of) or `"previousDay"` (plan night before) |
| `planningDeadlineHour` | Int | `10` | Hour of planning deadline (0-23) |
| `planningDeadlineMinute` | Int | `0` | Minute of planning deadline (0-59) |
| `isOnboardingCompleted` | Bool | `false` | True if user completed the initial active time setup |

---

## 2. Active Day Date Rollover Algorithm

If `isInterCalendarEnabled` is **true**:
Instead of transitioning strictly at midnight, the "Active Day" transitions at the **Active End Time** (e.g. `01:00 AM`).

```
                     Active Day Start Time (e.g., 07:00 AM)
                                      │
                                      ▼
Timeline:  ──[Yesterday 07:00 AM]─────┼─────[Calendar Midnight]─────┼─────[01:00 AM Deadline]──►
                                                                   │
                                                                   ▼
                                                       Active Day End Time (e.g., 01:00 AM)
```

### The Date Resolution Logic
To map any chronological clock time `Date()` to the corresponding "Active Calendar Date" `Date`:

1. Extract the current calendar date component, hour, and minute from the clock date.
2. Build two boundary dates for the current calendar date:
   - **Start Boundary:** Today at `activeDayStartHour`:`activeDayStartMinute`.
   - **End Boundary:**
     - If the End Time is chronologically before the Start Time (meaning it crosses midnight, e.g. Start 7 AM, End 1 AM):
       - The End Boundary is **tomorrow** at `activeDayEndHour`:`activeDayEndMinute`.
     - Else (End Time is before midnight, e.g. Start 7 AM, End 11 PM):
       - The End Boundary is **today** at `activeDayEndHour`:`activeDayEndMinute`.
3. Evaluate the clock time against these boundaries:
   - If the clock time is **before** the Start Boundary:
     - The active date is **yesterday's calendar date**.
   - If the clock time is **after** the End Boundary:
     - The active date is **tomorrow's calendar date** (and the current day is locked).
   - Otherwise:
     - The active date is **today's calendar date**.

If `isInterCalendarEnabled` is **false**:
- The Active Day resolves using the Active Start and End Times on the same calendar day (where End Time must be greater than or equal to Start Time). The Active Day transitions at the Active End Time instead of standard calendar midnight.

### 2.0.1 Planning Deadline Enforcements
The app enforces a custom **Planning Deadline** constraint separate from the active day end time:

1. **Current Day Planning (`"currentDay"`):**
   - The user must plan/add tasks on the active day itself, before the `planningDeadlineHour`:`planningDeadlineMinute` of that day.
   - If they attempt to add/complete tasks after this time, the task does not contribute to the active day streak (marked as red / streak resets).

2. **Previous Day Planning (`"previousDay"`):**
   - The user must plan/add tasks on the *previous calendar day* before the `planningDeadlineHour`:`planningDeadlineMinute` of that previous day.
   - For example, if they want tasks for July 14, they must add them by the deadline on July 13.
   - If they fail to do so, the tasks added on July 14 are logged, but the July 14 day is permanently locked as Red (streak reset).

### 2.1 Timezone Shifting Grace Period Handler
To prevent international travel (which shifts the device's clock forward) from automatically marking the active day as Missed (Red) due to a skipped deadline:

1. **Detect Timezone Shift:**
   - Store the user's last known timezone identifier (e.g. `America/New_York`) in `UserDefaults` under the key `lastKnownTimeZone`.
   - On app launch, compare `lastKnownTimeZone` with `TimeZone.current.identifier`.
2. **Apply Grace Period:**
   - If they differ, calculate the time zone offset difference between the old and new timezones.
   - If the shift is **forward** (e.g., Eastern Time to Greenwich Mean Time, +5 hours):
     - Cache a temporary `timezoneGraceExtension` (value in seconds, e.g. 18,000 seconds) in `UserDefaults`.
     - Extend the active day's End Boundary for the **current transition day only** by this offset difference.
     - Present a transient banner to the user: *"Timezone updated! A 5-hour grace period has been applied to today's streak deadline."*
   - If the shift is **backward** (gaining time):
     - No action is needed (the user gains time to plan).
3. **Persist New Timezone:**
   - Save the new `TimeZone.current.identifier` to `lastKnownTimeZone`. Clear the grace extension once the transition day rolls over.

---

## 3. UI Specifications

### A. Onboarding Flow (`OnboardingView`)
Displayed as a fullscreen overlay or sheet on first launch when `isOnboardingCompleted` is false.
- **Title:** "WELCOME TO STREAK"
- **Instructions:** "Define your wake-cycle. Streaks reset if tasks are not planned before your active day ends."
- **Controls:**
  - Start Time picker (defaults to 7:00 AM)
  - End Time picker (defaults to 11:30 PM)
  - Button "START STREAKING" (writes settings, sets `isOnboardingCompleted = true`, and dismisses).

### B. Settings View (`SettingsView`)
Displayed under the "More" tab.
- **Active Time Section:** Start and End time date pickers.
- **Reminders Section:** Planning notification time and toggle.
- **Category Manager Link:** Button navigating to category list.
- **Data Export/Import:** Flat buttons triggering serialization.
- **Continuous Alarm Section (Stub):** "Continuous Wake Alarm Challenge" options (disabled).

---

## 4. Notification Triggers

1. **Planning Reminder:**
   * Fires daily at the user-set `planningReminderHour`:`planningReminderMinute` (or defaults to 1 hour before their `activeDayEnd`).
   * Prompts the user to plan tasks for the upcoming day.
2. **Rollover Lockout Check:**
   * Runs in the background at `activeDayEnd`. If no tasks are found for the upcoming active day, the day is marked Red and the streak resets to 0.
