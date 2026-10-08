# Changelog

## 2026-10-09 — Dynamic Island countdown always on

- The Lock Screen / Dynamic Island countdown now shows all day while today has unfinished tasks (it used to wait for the last 8 hours of the day).
- It restarts after iOS ends it (Live Activities last ~8 hours): when you open Streak, when the day rolls over with the app open, or from the new **Show Day Countdown** Shortcuts/Siri action. Add that action to a morning automation to keep it running without opening the app. Health syncs restart it too.
- The compact Dynamic Island timer no longer gets cut off when more than 10 hours are left.
- Today refreshes on its own when the active day rolls over while the app is open (new habit tasks, status, widgets).

## 2026-10-08 (round 2) — Apple Health, habits hub, error handling

### Added
- **Apple Health via Shortcuts**: a "Log Health Data in Streak" Shortcuts action plus an in-app setup guide (Fitness → Apple Health). A daily Shortcuts automation sends steps, active energy, exercise minutes and workouts, without HealthKit, so it works with free Apple ID signing.
- **Health-linked habits**: a habit commitment can auto-complete when a Health metric reaches a target (e.g. ≥ 10,000 steps, ≥ 1 workout).
- **Fitness → Apple Health card**: shows the day's synced numbers and progress toward Health-linked habits.
- **Per-habit streaks**: each habit commitment has its own streak and a recent-days strip. Unscheduled, rest and frozen days don't break it.
- **Habits section on Today**, plus a reworked Habit commitments sheet (active vs ended, schedule, Health link, streak, history).

### Changed
- **One source of truth for habits**: a habit counts as followed when its task is ticked, whether from Today, Tasks, the widget, Health or the check-in. The Habit Commitments widget and the check-in now always agree with the task list.
- Removed the unused "core habits" code (its table stays, so existing data opens fine).
- Habit and goal deletion now ask for confirmation (both were one tap).
- Finance friend / settle / direct-collect actions, goal progress logging, goal deletion and adding a habit from Overall History now show an error instead of failing silently.

## 2026-10-08 — Streak fixes, Today screen, backup

### Fixed
- **Streak showed 0 all day** until every task was done. The in-progress day no longer breaks the count, and streaks use the custom active-day boundaries instead of the calendar date.
- **Streak Freezes / rest passes were overwritten** by the next catch-up sweep, so they never protected anything. Protected days are now a `frozen` status that stays put (unless the day is completed after all). Covers the overall streak and every category.
- **Notifications were frozen snapshots**: repeating, with text baked in when Settings was last saved, and "last call" fired even after finishing. They're now one-shot, rebuilt from live data after every change, and skipped once the day is done.
- **AI notifications silently broken**: `gemini-1.5-flash` is retired. Now uses the `gemini-flash-latest` alias, with the key sent in a header.
- **Habit-commitment tasks only existed if the Tasks tab was opened**, so a day could lock red. The day sweep now generates them.
- **Planning-reminder toggle did nothing** (was never saved). It's now bound to the setting.
- **Profile alert could never be dismissed** (message never cleared).
- **Overall Green Day bonus could be farmed** by unticking and re-ticking the last task. Now awarded once per day.
- **End-of-day form double-awarded XP** on every save, matched habits by title, and "Not followed" didn't untick the task. All fixed.
- **Transaction save/delete failures were silent**. Now shown in an alert, and the sheet stays open.
- Background sweep and foreground catch-up were two diverging copies. They're merged into `DaySweeper`.

### Changed
- **Late tasks are BONUS tasks**: they earn XP but never affect the day's status (before, adding one made a finished day red).
- **5 tabs** (Today, Tasks, Fitness, Finance, Profile). Goals moved onto the Today screen; Settings has a gear on Today.
- **Today screen**: tasks left, time left and tap-to-complete checkboxes first, then overall streak, goals and categories. The finance card was removed (it duplicated the Finance tab).
- **End-of-Day Check-In** merges the habit form with the never-wired Daily Assist reflection (rating, wins, what slipped, tomorrow's priorities, past check-ins).
- **Tasks header**: reorder and habit commitments moved into a ⋯ menu; the missed-tasks button is a proper 44pt target; the duplicate countdown was removed.
- **Text readability**: fixed font sizes go through `Font.app(size:)`, which follows the system text size and never drops below 11pt.
- Removed the "Wake up challenge (SOON)" placeholder and unused router cases.

### Added
- **Backup & Restore** (Settings): full database snapshot plus settings, exported to Files; restore is applied on the next launch, with a safety copy kept. The Today screen nudges when a backup is due.
- **Automatic Streak Freeze**: a freeze in inventory is used automatically when a missed day would break a running streak.
- **Rest days** (Settings): chosen weekdays never turn red and don't break the streak.
- **Per-habit schedules**: habit commitments can run on specific weekdays only.
- **Interactive Tasks widget**: tick tasks from the Home Screen.
- **Lock Screen / Dynamic Island countdown** (Live Activity) for the last 8 hours of the day.

