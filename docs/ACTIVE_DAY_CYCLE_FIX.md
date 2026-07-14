# Active Day Cycle — Problem Analysis & Proposed Fix

## What I Understand About Streak

**Streak** is your iOS habit tracker (Swift/SwiftUI/SwiftData, iOS 17+, AltStore sideload). It tracks daily habits via categories, tasks, streaks, and a consistency heatmap. The core rule is brutal: any day with incomplete or zero tasks = RED = streak reset.

There are currently 6 modules built: Categories, Master Consistency Graph, Daily Tasks, Goals, Daily Assist, and Settings/Onboarding. The architecture is Clean Architecture + DDD with four layers.

---

## The Feature: Active Day Cycle

The **Active Day Cycle** defines the time window during which a user must complete their tasks for the day. It's configured via:

| Setting | Purpose |
|---------|---------|
| `activeDayStartHour:Minute` | When the user's active day begins |
| `activeDayEndHour:Minute` | The deadline — when tasks must be done by |
| `isInterCalendarEnabled` | The "Spans Midnight" toggle |

The core resolver lives in `Domain/Services/ActiveDayResolver.swift`.

---

## The Problem (3 Issues)

### Issue 1: Time pickers disappear when "Spans Midnight" is OFF

In both `Presentation/Settings/SettingsView.swift` and `Presentation/Onboarding/OnboardingView.swift`, the start/end time pickers are wrapped in:

```swift
if isInterCalendar {
    // time pickers shown here
}
```

When the toggle is OFF → **pickers vanish**. The user cannot set a 9 AM–6 PM window because the UI hides it.

### Issue 2: Resolver completely ignores start/end times when toggle is OFF

In `ActiveDayResolver.swift` lines 9–11:

```swift
guard settings.isInterCalendarEnabled else {
    return calendar.startOfDay(for: date)  // ← always midnight boundary
}
```

When the toggle is OFF, the resolver short-circuits and returns a plain midnight boundary. The configured start/end times are **completely ignored**, making any custom active window impossible.

### Issue 3: No validation that end ≥ start when midnight span is OFF

There's no enforcement anywhere. A user could toggle OFF "Spans Midnight" but still have `endHour < startHour` saved from a previous configuration. The resolver wouldn't even use them, so it was never a problem — but once we fix Issues 1 & 2, we need this guard.

---

## What "Spans Midnight" Should Actually Mean

> The toggle should NOT be a gate for "do custom times exist?" — it should only control **whether the end time can wrap into the next calendar day**.

| Toggle State | Meaning | Example | Validation |
|---|---|---|---|
| **OFF** | Start and end are on the **same calendar day** | 9:00 AM → 6:00 PM | End must be > Start (24h clock) |
| **ON** | End time can be **on the next calendar day** | 1:00 PM → 1:00 AM (+1 day) | Any combination allowed. If end < start → it's next day. |

User-stated rule:

> *"If the end time is smaller than the start time, it will always be of the next day. Simple as that."*

---

## Proposed Solution

### Changes to 3 files. Nothing else.

---

### 1. `ActiveDayResolver.swift` — Remove the guard, always use start/end times

The existing logic on lines 12–69 **already handles both cases correctly**. The key line:

```swift
let endCrossesMidnight = (endHour < startHour) || (endHour == startHour && endMinute < startMinute)
```

- When toggle is **OFF** (end ≥ start): `endCrossesMidnight = false` → deadline is today at end time ✓
- When toggle is **ON** (end < start): `endCrossesMidnight = true` → deadline is tomorrow at end time ✓

**The fix: Delete the guard on lines 9–11.** That's it. The rest of the method works for both modes.

```diff
 public static func resolveActiveDate(for date: Date, settings: SettingsRepository) -> Date {
     let calendar = Calendar.current
     
-    guard settings.isInterCalendarEnabled else {
-        return calendar.startOfDay(for: date)
-    }
-    
     let endHour = settings.activeDayEndHour
     ...
```

#### What happens after this fix:

| Scenario | Start | End | Toggle | Before Start | During Window | After End |
|---|---|---|---|---|---|---|
| 9-to-5 worker | 09:00 | 18:00 | OFF | Active = today | Active = today | Active = tomorrow (day locked) |
| Night owl | 13:00 | 01:00 | ON | Active = yesterday (if before 01:00) | Active = today | Active = tomorrow |
| Full day | 06:00 | 23:30 | OFF | Active = today | Active = today | Active = tomorrow (day locked at 23:30) |

---

### 2. `SettingsView.swift` — Always show time pickers + add validation

Move the time pickers **outside** the `isInterCalendar` conditional. Keep only the explanatory text conditional:

```diff
-if isInterCalendar {
-    Divider() ...
-    // Start time picker
-    // End time picker
-}
+Divider() ...
+// Start time picker (always visible)
+// End time picker (always visible)
+
+// Dynamic explanation text based on toggle
+if isInterCalendar {
+    Text("Your active day wraps across midnight (e.g. 1 PM to 1 AM).")
+} else {
+    Text("Your active day is within a single calendar day (e.g. 9 AM to 6 PM).")
+}
```

**Validation on save:** When `isInterCalendar == false`, enforce that end time > start time. Show an error banner instead of saving if violated:

```swift
if !isInterCalendar {
    let endTotal = endHour * 60 + endMinute
    let startTotal = startHour * 60 + startMinute
    if endTotal <= startTotal {
        bannerMessage = "End time must be after start time when Midnight Span is off."
        showBanner = true
        return
    }
}
```

---

### 3. `OnboardingView.swift` — Mirror the same changes

Same pattern: always show time pickers, add validation before save, update explanatory text. The `TimeDropdownPicker` component (defined in this file) is already reusable — no changes to the component itself.

---

## What This Does NOT Touch (Intentionally Separate)

| Concept | Status |
|---|---|
| Planning deadline / planning window | Already separate in UI + code. No changes needed. |
| Planning for next day vs. current day | Already handled by `planningWindowMode`. Untouched. |
| Task lockout / midnight sweep | Uses `ActiveDayResolver.resolveActiveDate()` — will automatically benefit from the fix. |
| Streak calculation | Uses `DayEntry` which is populated by the resolver. Works transitively. |

---

## Summary

| File | Change | Δ Lines |
|---|---|---|
| `Domain/Services/ActiveDayResolver.swift` | Delete the 3-line guard clause | −3 |
| `Presentation/Settings/SettingsView.swift` | Always show pickers + validation + updated text | ~+15 |
| `Presentation/Onboarding/OnboardingView.swift` | Same as SettingsView | ~+15 |

> The resolver logic already works for both modes — it just never gets called when the toggle is OFF because of a premature `guard` return. Deleting 3 lines fixes the core issue. The rest is UI cleanup.
