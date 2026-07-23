# Product Requirements Document (PRD)
## App Name: (TBD — working title: "Streak")
**Version:** 1.0  
**Date:** 2026-07-08  
**Author:** Product Owner  
**Status:** Draft

---

## 1. Overview

A personal iOS habit tracker for daily self-improvement. Built for personal use and distributed to a small closed group of friends via AltStore (sideloaded IPA). No backend. All data lives on-device with optional iCloud backup and single-file export/import.

The app is designed as a **super-app scaffold** — the core three modules ship first, but the architecture must allow new feature modules to be dropped in without restructuring existing code.

---

## 2. Problem Statement

Existing habit tracker apps are either too gamified (cluttered, noisy) or too minimal (no depth). There is no app that combines:
- GitHub-style consistency graphs per habit category
- A structured nightly to-do planning system tied to consistency
- Game-like goal tracking with progress bars
- iOS-native features: widgets, lock screen widgets, Shortcuts, notifications
- Brutalist, paper-aesthetic UI — minimal, bold, no noise

---

## 3. Target Users

- Primary: The app owner (single user, personal device)
- Secondary: A small group of friends (3–10 people), each running their own fully independent copy, sideloaded via their own Apple ID

No shared data in v1. Friend accountability is a future module.

---

## 4. Core Principles

1. **Local-first.** No backend, no accounts, no internet requirement.
2. **Documentation-first.** Every feature is documented before code is written.
3. **Extensible by design.** New feature modules plug in without touching existing ones.
4. **SOLID + Domain-driven.** Each domain (Habits, Goals, Tasks, Notifications) is isolated.
5. **Minimal UI.** Neo-Brutalist aesthetic. Nothing on screen that doesn't need to be there.

---

## 5. Feature Modules (v1.0)

### 5.1 Module: Habit Categories
**Priority:** P0 — Core

**Description:**  
User creates named habit categories (e.g., "Gym", "Reading", "Finance"). Each category has:
- A user-chosen name
- A user-chosen color (full color wheel picker)
- That color is used as the category's identity color across the entire app (borders, dots, tags)

**Rules:**
- No limit on number of categories
- Categories can be reordered
- Categories can be archived (not deleted — data is preserved)
- Each category has its own consistency graph (GitHub-style heatmap)

**Consistency Graph Rules (per category):**
- Day is GREEN: all to-do tasks for that category on that day were completed
- Day is RED: tasks existed but were not all completed, OR no tasks were set for that day
- Day is EMPTY/BLANK: date is in the future
- Graph shows the past 365 days (scrollable) in a grid

**Streak Counter (per category):**
- Count of consecutive days where all tasks for that category were completed
- A red day (any reason) resets the streak to 0
- Displayed prominently in the category view

---

### 5.2 Module: Master Consistency Graph
**Priority:** P0 — Core

**Description:**  
A single master graph on the home screen representing the overall consistency across all categories and all tasks.

**Rules:**
- Day is GREEN: every task in every category AND all uncategorized tasks were completed
- Day is RED: any task was missed, OR any category had no tasks set, OR no tasks were set at all
- Master streak counter: consecutive fully-green days
- This is the top-level health indicator of the user's discipline

---

### 5.3 Module: Multi-Timeframe Task & Goal Planning
**Priority:** P0 — Core

**Description:**  
A flexible task planning system spanning four distinct timeframes:
1. **Daily (Today / Tomorrow):** Specific day tasks bound to strict green/red streak evaluations.
2. **Weekly Plan:** Weekly goals and priorities with progress percentage bars.
3. **Monthly Plan:** Monthly targets and major call items with completion metrics.
4. **To-Do List (Backlog):** Timeline-free reminders and ideas with pending counters.

**Task structure:**
- Task text (required)
- Category link (optional — can be uncategorized)
- Timeframe scope (`.daily`, `.weekly`, `.monthly`, `.backlog`)
- Completion checkbox
- Category color dot

**Category color dot:**
- Every task in the list shows a small filled circle in the category's color
- Uncategorized tasks show a neutral gray dot

**Quick Scheduling & Promotion:**
- Every weekly, monthly, and backlog task features `[⚡️ TODAY]` and `[🗓️ TOMORROW]` quick action pills.
- Tapping `⚡️ TODAY` or `🗓️ TOMORROW` promotes any weekly, monthly, or backlog task into Today's or Tomorrow's active daily task list.
- Tasks can also be re-scoped between timeframes via the task row scope menu at any time.

**Soft-Deletion Rules:**
- Swipe-to-delete on active tasks performs a soft-delete (moves task to bottom with strike-through and `(Deleted)` badge).
- Soft-deleted tasks do not affect day statuses, streaks, or goal progress calculations.
- Swiping delete a second time on a soft-deleted task permanently purges it from database storage.

**Planning Reminder:**
- User sets a reminder time (e.g., 10:00 PM)
- At that time, a notification fires: "Set your goals for tomorrow"
- If no tasks are added within the reminder window, notifications repeat every 5 minutes
- Repetition stops the moment at least one task is added for any category
- If midnight passes with no tasks set, that day is marked red across all categories and the master graph

**Completion logic:**
- When all daily tasks for a category are checked, that category's day is marked green
- If even one active daily task is unchecked, the day remains red (no partial state)
- Non-daily tasks (`.weekly`, `.monthly`, `.backlog`) do not affect daily streak calculations unless promoted to `.daily`

---

### 5.4 Module: Goals (Progress Tracker)
**Priority:** P1 — Core

**Description:**  
User creates long-term goals with a game-style progress bar.

**Goal types:**

| Type | Tracking Method | Reset on Miss? | Linked to Category? |
|------|----------------|----------------|---------------------|
| **Consecutive Streak** | Tied to a category's current active streak count. | Yes (drops to 0) | Yes |
| **Cumulative Days** | Tied to a category's total count of successful (green) days since start. | No (pauses) | Yes |
| **Milestone-based** | User defines a numeric target (e.g. ₹10,00,000 saved, 500km run) and manually logs progress value over time. | No (stays flat) | Optional |
| **Task Counter** | Tied to a category's total count of completed tasks since start. | No (pauses) | Yes |

**Goal structure:**
- Goal name
- Goal type (above)
- Target value (number, days, or custom unit)
- Current value (updated manually or auto from consistency)
- Start date / Target date
- Linked category (optional)
- Daily notification toggle: sends a nudge at a user-set time to log progress

**Progress bar visual:**
- Thick bordered progress bar (Brutalist style)
- Shows % complete and current/target value
- Color matches the linked category, or a default accent if uncategorized

---

### 5.5 Module: Daily Assist (Reflection Notification)
**Priority:** P1 — Core

**Description:**  
A nightly reflection prompt. User sets the time. At that time, the app sends a notification. Tapping opens a full-screen reflection form inside the app.

**Reflection form questions (fixed set, v1):**
1. What did you accomplish today?
2. What did you not complete, and why?
3. What are your top priorities for tomorrow?
4. How are your active goals progressing?
5. Rate your overall consistency today (1–5)

**Output:**
- Entries are stored locally per day
- Accessible as a journal/log in the app
- Not required — user can dismiss, but the notification fires regardless

---

### 5.6 Module: Settings & Onboarding (Active Day Configuration)
**Priority:** P1 — Core

**Description:**  
Allows the user to define their custom wake-cycle (Active Start and End times) which shifts the calendar rollover boundary. Includes onboarding setup and a centralized settings screen.

**Key Features:**
- **Active Time Period:** Start and End time configuration. The End Time (deadline) acts as the rollover boundary for streaks.
- **Lockout Rule:** If no tasks are scheduled for the upcoming active day before the End Time, the day is locked as Missed (Red), resetting the streak. Any tasks added afterwards are marked late and do not count toward the streak.
- **Onboarding Flow:** Fullscreen overlay on first run to configure start/end times before accessing the app.
- **Settings Screen:** Accessed from the "More" tab to configure active times, manage categories, toggle Appearance Theme (System/Light/Dark), and Danger Zone data reset.

---

### 5.7 Module: Daily Habit Commitments & Sprints
**Priority:** P1 — Core

**Description:**  
Enables users to establish recurring daily habit commitments (e.g. 2 hours of DSA, hydration, exercise).

**Key Features:**
- **Monthly Fixed Commitments:** Runs every day for the current month. Strictly locked (`isLocked = true`) — once created, it cannot be edited or deleted.
- **Habit Sprints:** Custom timeframe routines (e.g., 7 days or 14 days) for short-term daily habit sprints.
- **Auto Task Generation:** `GenerateRoutineTasksUseCase` automatically populates daily checklist items for active routines upon app launch/viewing.

---

### 5.8 Module: Dynamic Light & Dark Neo-Brutalist Theme System
**Priority:** P1 — Core

**Description:**  
Provides high-contrast Neo-Brutalist visual design across both Light Mode (Paper `#F5F0E8`) and Dark Mode (Obsidian `#121212`).

**Key Features:**
- **Dynamic Token Architecture:** `AppColor` and `WColor` tokens resolve dynamically based on system trait collections.
- **Theme Selection:** User preference in Settings for System Automatic, Always Light, or Always Dark.
- **Widget Adaptability:** Home screen widgets automatically adapt to dark mode and tinted icon settings.

---

## 6. Non-Functional Requirements

| Requirement | Spec |
|-------------|------|
| Platform | iOS 17+ |
| Language | Swift 5.9+, SwiftUI |
| Storage | SwiftData (local, on-device) |
| iCloud sync | Optional toggle in Settings. Uses iCloud Drive via SwiftData's CloudKit sync |
| Export | Single JSON file export via share sheet / AirDrop |
| Import | Load JSON file to restore all data |
| Distribution | AltStore IPA sideload. No App Store. |
| Signing | Free Apple ID (7-day resign cycle) or paid dev account (1-year) |
| Permissions | Notifications, iCloud (optional) |
| Performance | All operations < 100ms on iPhone XS or newer |
| Offline | 100% offline. Zero network calls. |

---

## 7. Out of Scope (v1.0)

- Friend accountability / social features
- Proof system (photo/video evidence for tasks)
- Backend / database / user accounts
- Android / web versions
- AI features
- Gamification beyond progress bars

These are documented in `FUTURE_MODULES.md`.

---

## 8. Open Questions (Resolved)

| Question | Decision |
|----------|----------|
| Native vs cross-platform | Swift + SwiftUI only |
| Backend? | None. Local-only. |
| Distribution | AltStore sideload |
| Signing | Free Apple ID (friends re-sign individually) |
| Partial day state? | No. Green or Red. No partial. |
| Day with no tasks | Red |
| Streak break condition | Any red day resets streak |
| Reminder repeat interval | Every 5 minutes until tasks are set |
| iCloud sync | Optional user toggle |
| Data portability | Export/import as single JSON file via AirDrop |
| UI theme | Neo-Brutalist: paper/cream background, thick dark borders, no shadows |
| Category color | Full color wheel, user picks per category |
| Dark mode | Not in v1 |

---

## 9. Success Criteria

- User can create categories, add tasks, and check them off daily
- Consistency graphs correctly reflect green/red based on task completion
- Streaks calculate correctly and reset on any red day
- Nightly planning reminder fires and repeats until tasks are added
- Goals display accurate progress bars
- Daily Assist reflection form works and stores entries
- Home screen and lock screen widgets show key data
- iOS Shortcuts can log completions and query status
- App exports/imports data as a single JSON file
- App installs cleanly via AltStore with free Apple ID
