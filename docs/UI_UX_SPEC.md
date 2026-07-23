# UI/UX Design Specification
## App: Streak (iOS Habit Tracker)
**Version:** 1.0  
**Date:** 2026-07-08  
**Status:** Draft

---

## 1. Design Language: Neo-Brutalism

The app follows the **Neo-Brutalist** design philosophy applied to digital interfaces:

- Raw, honest, functional
- No decorative elements that don't serve a purpose
- Everything is visible and readable at a glance
- No gradients, no shadows, no blurs, no frosted glass
- Thick borders act as the primary visual structure
- Bold typography as a design element
- Color used sparingly and meaningfully — only category colors, nothing decorative

**References:** Early Notion, Linear (sparse version), paper notebooks, zines.

---

## 2. Color Palette

### 2.1 Dynamic Neo-Brutalist Color Palette (Light & Dark)

The app dynamically adapts between **Light Neo-Brutalism** and **Dark Neo-Brutalism**:

| Token | Light Mode Value | Dark Mode Value | Use |
|-------|-------|-------|-----|
| `background` | `#F5F0E8` | `#121212` | App background canvas |
| `surface` | `#EFEFDF` | `#1E1E1E` | Card/widget background |
| `border` | `#1A1A1A` | `#F5F0E8` | High-contrast 2.5pt borders & dividers |
| `text-primary` | `#1A1A1A` | `#F5F0E8` | Primary text, headings |
| `text-secondary` | `#4A4A4A` | `#A0A0A0` | Secondary text, labels, hints |
| `text-disabled` | `#9A9A9A` | `#666666` | Placeholder text, inactive labels, soft-deleted items |
| `green` | `#2D7A2D` | `#34C759` | Completed day marker & strict heatmap status |
| `red` | `#C0392B` | `#FF3B30` | Missed/red day marker & strict heatmap status |
| `blank` | `#D0C9B8` | `#2C2C2E` | Future day / no data |
| `neutral-dot` | `#8A8A8A` | `#999999` | Uncategorized task dot |

### 2.2 Category Colors

User picks from a full HSB color wheel. The selected color becomes that category's identity.

Rules:
- The raw picked color is stored (hue, saturation, brightness)
- All UI uses that color for borders of that category's card, the dot in task lists, and graph cell fills
- No auto-darkening or lightening — the user's chosen color is used directly
- White or near-white colors are disallowed (minimum brightness contrast against paper background enforced)

### 2.3 Dark Mode

Not in v1. The Neo-Brutalist paper aesthetic is intentionally light. Dark mode can be added as a theme toggle in a future version.

---

## 3. Typography

| Role | Font | Weight | Size |
|------|------|--------|------|
| Screen title | SF Pro Rounded | Bold | 28pt |
| Section header | SF Pro Display | Semibold | 20pt |
| Card title | SF Pro Display | Semibold | 17pt |
| Body text | SF Pro Text | Regular | 15pt |
| Task item | SF Pro Text | Medium | 16pt |
| Label / hint | SF Pro Text | Regular | 13pt |
| Streak number | SF Pro Display | Heavy | 36pt |
| Progress % | SF Pro Display | Bold | 22pt |

All text uses Dynamic Type — user's accessibility font size settings are respected.  
No custom fonts in v1 (avoids font licensing and App Store review complications for sideload builds).

---

## 4. Spacing & Layout

| Token | Value |
|-------|-------|
| `margin-screen` | 16pt horizontal |
| `card-padding` | 14pt |
| `card-border-width` | 2.5pt |
| `card-corner-radius` | 6pt (subtly rounded — not pill-shaped) |
| `item-spacing` | 10pt |
| `section-spacing` | 24pt |
| `dot-size` | 10pt diameter |
| `heatmap-cell-size` | 12pt × 12pt |
| `heatmap-cell-gap` | 3pt |

---

## 5. Component Library

### 5.1 BrutalistCard
The base container for all cards and widgets.

```
┌─────────────────────────────┐  ← 2.5pt border, color #1A1A1A
│                             │  ← background: surface (#EFEFDF)
│   [Content here]            │  ← corner radius: 6pt
│                             │  ← no shadow
└─────────────────────────────┘
```

Category cards use the category color for their border instead of `#1A1A1A`.

### 5.2 CategoryDot
A filled circle used to identify categories in lists.

```
● ← 10pt filled circle, category color
```

Used in:
- Task list (before each task label)
- Goal list (before goal title)
- Any list that mixes items from multiple categories

### 5.3 ConsistencyGrid (Heatmap)
A 52×7 grid (one year). Scrollable horizontally.

```
M  ■ ■ ■ □ ■ ■ ■ ■ □ ■ ...
T  ■ □ ■ ■ ■ ■ □ ■ ■ ■ ...
W  □ ■ ■ ■ ■ ■ ■ ■ □ ■ ...
T  ■ ■ □ ■ □ ■ ■ ■ ■ □ ...
F  ■ ■ ■ □ ■ ■ ■ ■ ■ ■ ...
S  □ ■ ■ ■ ■ □ ■ ■ ■ ■ ...
S  ■ □ ■ ■ ■ ■ ■ □ ■ ■ ...
```

| Cell state | Color |
|------------|-------|
| Green (completed) | `#2D7A2D` |
| Red (missed/no tasks) | `#C0392B` |
| Blank (future) | `#D0C9B8` |

Cell: 12×12pt square, 3pt gap, 2pt corner radius.  
Month labels above columns. Day-of-week labels on left.  
Tap a cell → shows date + status in a small popover.

### 5.4 StreakBadge
```
┌──────────────┐
│  🔥 47 days  │  ← bold number, icon, thick border
└──────────────┘
```
Uses `text-primary` for number. Flame emoji or a simple icon.

### 5.5 ProgressBar (Goals)
```
┌────────────────────────────────────────┐
│██████████████████░░░░░░░░░░░░░░░░░░░░░│  ← 2.5pt border
└────────────────────────────────────────┘
     68%    ←  label below
```
- Fill color = linked category color, or default accent if no category
- Empty portion = `#D0C9B8`
- No animation on load (static, updates on data change)
- Height: 18pt

### 5.6 TaskRow
```
○  ● Reading   Write 3 pages of the book
```
- `○` = empty checkbox (tap to complete)
- `✓` = filled checkbox (completed, task text gets strikethrough)
- `●` = category color dot (10pt)
- Task text at 16pt Medium
- Minimum tap target: 44×44pt (accessibility)

### 5.7 Navigation
Bottom tab bar with 4 tabs:

| Tab | Icon | Screen |
|-----|------|--------|
| Home | Grid/house icon | Master graph + category cards |
| Tasks | Checklist icon | Today's task list |
| Goals | Target/flag icon | Goal list |
| More | Three dots | Reflection log + Settings |

Tab bar: thick top border (2.5pt), paper background, no blur.

---

## 6. Screen Designs

### 6.1 Home Screen

```
┌─────────────────────────────────────────┐
│  STREAK                        [+]  [⚙] │  ← screen title, add + settings
├─────────────────────────────────────────┤
│  ┌───────────────────────────────────┐  │
│  │  OVERALL   🔥 47 days             │  │  ← master streak card
│  │  [heatmap grid — full width]      │  │
│  └───────────────────────────────────┘  │
│                                         │
│  CATEGORIES                             │  ← section header
│  ┌────────────┐  ┌────────────┐         │
│  │ ■ GYM      │  │ ■ READING  │  ...    │  ← category cards (H-scroll)
│  │ 🔥 12 days │  │ 🔥 3 days  │         │
│  │ [heatmap]  │  │ [heatmap]  │         │
│  └────────────┘  └────────────┘         │
└─────────────────────────────────────────┘
│  [Home]  [Tasks]  [Goals]  [More]       │  ← tab bar
```

Category cards are horizontally scrollable. Each card border uses the category's color.

### 6.2 Task List Screen

```
┌─────────────────────────────────────────┐
│  TODAY — WED, 8 JUL                     │
├─────────────────────────────────────────┤
│  ○  ● Gym       Morning workout (6am)   │
│  ✓  ● Gym       Log macros              │
│  ○  ● Reading   Read 20 pages           │
│  ○  ○ —         Call parents            │  ← uncategorized, gray dot
│  ○  ● Finance   Check portfolio         │
├─────────────────────────────────────────┤
│           [+ Add task]                  │  ← bottom quick-entry
└─────────────────────────────────────────┘
```

No section headers. Color dots do the grouping visually. List sorted by: category order, then uncategorized at bottom.

### 6.3 Category Detail Screen

```
┌─────────────────────────────────────────┐
│  ← GYM                    [Edit]  [⋯]  │
├─────────────────────────────────────────┤
│  🔥 12 days   |   Total: 87/120         │
│                                         │
│  [Full-width heatmap grid]              │
│                                         │
│  LINKED GOALS                           │
│  ┌─────────────────────────────────┐    │
│  │  Go to gym for 90 days          │    │
│  │  ████████████░░░░░░░░  67%      │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

### 6.4 Goal List Screen

```
┌─────────────────────────────────────────┐
│  GOALS                         [+]      │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐    │
│  │  ● Gym — 90-day streak          │    │
│  │  ██████████░░░░░░░  67 / 90 days│    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │  ○ —  Save ₹1,00,000           │    │
│  │  ████░░░░░░░░░░░░░  ₹32k / ₹1L │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

#### 6.4a Goal Detail Screen

Opens when tapping any Goal Card in the Goals List.

```
┌─────────────────────────────────────────┐
│  ← GOAL DETAIL                [Edit] [🗑] │  ← back, edit, delete buttons
├─────────────────────────────────────────┤
│  ● GYM — 90-DAY STREAK                  │  ← title, category dot
│  Goal Type: Consecutive Streak          │
│                                         │
│  67 / 90 days                           │  ← current / target metric
│  ┌─────────────────────────────────┐    │
│  │██████████████████░░░░░░░░░░░░░░░│    │  ← brutalist progress bar
│  └─────────────────────────────────┘    │
│  74% Completed                          │
│                                         │
│  [Log Progress]                         │  ← manual entry button (milestone-based only)
│                                         │
│  PROGRESS TIMELINE                      │
│  • 12 Jul: Logged +₹10,000 (Paycheck)   │  ← update entries history
│  • 10 Jul: Logged +₹5,000 (Freelance)   │
└─────────────────────────────────────────┘
```

- **Interactive Log button:** Appears only if `goalType` is `.milestoneBased`. Tapping opens a quick popover sheet to log numeric progress increments with notes.
- **Auto-Sync:** Auto-calculated types (streaks, cumulative green days, task counter) read database state directly; manual entries are disabled.

#### 6.4b Add / Edit Goal Screen

Opens as a sheet when tapping the `[+]` button on the Goal List.

```
┌─────────────────────────────────────────┐
│  ADD GOAL                          [✓]  │  ← title, save button
├─────────────────────────────────────────┤
│  Title: [ Gym Challenge           ]     │  ← text field
│                                         │
│  Goal Type:                             │
│  ( ) Consecutive Streak                 │  ← radio selector
│  ( ) Cumulative Green Days              │
│  (*) Milestone (Manual Value)           │
│  ( ) Task Completion Count              │
│                                         │
│  Target Value: [ 90       ]             │  ← numeric field
│  Unit Symbol:  [ days     ]             │  ← text field (e.g. days, ₹, km)
│  Target Date:  [ 2026-09-08 ]             │  ← date picker (optional)
│  Link Category:[ Fitness  v ]             │  ← dropdown list (optional)
└─────────────────────────────────────────┘
```

- **Dynamic Validation:** If a category is linked, it disables incompatible goal types or auto-selects related options. Saving requires a non-empty title and target value > 0.

### 6.5 Daily Assist / Reflection Form

Opens as a full-screen sheet over any screen when triggered by notification tap.

```
┌─────────────────────────────────────────┐
│  DAILY ASSIST  — Wed, 8 Jul             │
│                                    [✓]  │  ← save button
├─────────────────────────────────────────┤
│  What did you accomplish today?         │
│  ┌─────────────────────────────────┐    │
│  │                                 │    │  ← multiline text input
│  └─────────────────────────────────┘    │
│                                         │
│  What didn't you complete, and why?     │
│  ┌─────────────────────────────────┐    │
│  │                                 │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Priorities for tomorrow?               │
│  ┌─────────────────────────────────┐    │
│  │                                 │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Goal progress notes?                   │
│  ┌─────────────────────────────────┐    │
│  │                                 │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Today's consistency: ① ② ③ ④ ⑤       │  ← 1-5 tap selector
└─────────────────────────────────────────┘
```

### 6.6 Overall History Screen

Opens when clicking the "OVERALL" card on the Home screen.

```
┌─────────────────────────────────────────┐
│  ← OVERALL HISTORY                      │
├─────────────────────────────────────────┤
│  COMPLETION RATE (0% - 100%)            │
│  ┌───────────────────────────────────┐  │
│  │  /\                 ● selected    │  │  ← Line graph (scrollable)
│  │ /  \   /\  _                      │  │
│  │/    \_/  \/                       │  │
│  └───────────────────────────────────┘  │
│                                         │
│  TASKS FOR JULY 13, 2026                │
│  ┌───────────────────────────────────┐  │
│  │  ● GYM                            │  │  ← Grouped tasks list
│  │  ✓  Morning workout               │  │
│  │  ○  Log macros                    │  │
│  │  ● READING                        │  │
│  │  ○  Read 20 pages                 │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

- **Graph style:** Line graph plotted with `AppColor.border` (#1A1A1A) with visible dots at each day's point.
- **Scroll range:** Chart displays 30 days (1 complete month) at a time, scrollable horizontally.
- **Interactions:** Tap any day's dot to select it and update the grouped task list below.

### 6.7 Settings Screen
Accessed from the "More" tab button. Presents all app configurations in Neo-Brutalist cards.

```
┌─────────────────────────────────────────┐
│  SETTINGS                               │
├─────────────────────────────────────────┤
│  ┌───────────────────────────────────┐  │
│  │  ACTIVE TIME BOUNDARIES            │  │
│  │  Start: [ 07:00 AM ]              │  │  ← DatePicker (hour/minute)
│  │  End:   [ 11:30 PM ]              │  │  ← DatePicker (hour/minute)
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │  PLANNING REMINDER                 │  │
│  │  [✓] Enable Daily Reminder        │  │  ← Toggle
│  │  Time:  [ 10:30 PM ]              │  │  ← DatePicker (hour/minute)
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │  CATEGORY MANAGEMENT               │  │
│  │  [ Manage Categories ]             │  │  ← Navigational Button
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │  DATA IMPORT / EXPORT              │  │
│  │  [ Export Data (JSON) ]            │  │  ← ShareSheet Button
│  │  [ Import Data (JSON) ]            │  │  ← FilePicker Button
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │  CHALLENGE WAKE ALARM (SOON)       │  │  ← Disabled preview block
│  │  [ ] 5 Pushups Challenge to Stop  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### 6.8 Onboarding Screen
Fullscreen overlay displayed on initial launch when active boundaries are not yet configured.

```
┌─────────────────────────────────────────┐
│                                         │
│            STREAK                       │
│                                         │
│  Define your active day boundaries.     │
│  Tasks must be planned before the       │
│  end of your active day to preserve     │
│  your streak.                           │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  Active Start Time: [ 07:00 AM ]  │  │
│  │  Active End Time:   [ 11:30 PM ]  │  │
│  └───────────────────────────────────┘  │
│                                         │
│          [ START STREAKING ]            │  ← Heavy Neo-Brutalist button
│                                         │
└─────────────────────────────────────────┘
```

---

## 7. Interaction Rules

- **Tap targets:** Minimum 44×44pt for all interactive elements
- **Swipe to delete:** Tasks and goals support left-swipe → delete
- **Long press:** On a category card → quick actions (Edit, Archive, Add task)
- **Haptic feedback:** Light tap on task completion, medium on streak milestone
- **No animations except:** Checkbox fill on task completion (100ms, no easing curve — instant snap, Brutalist)
- **No loading spinners:** All operations are local and fast. No skeleton loaders.
- **Empty states:** Plain text. "No tasks for today. Add one." No illustrations.

---

## 8. Accessibility

- All text respects Dynamic Type size settings
- VoiceOver labels on all interactive elements
- Minimum contrast ratio 4.5:1 for all text against background
- Category color dots have text labels accessible to VoiceOver (category name announced)
- Heatmap cells have accessibility labels: "July 8, completed" / "July 7, missed"

---

## 9. Widget UI Spec

### Lock Screen Widgets (Accessory)
- Accessory Rectangular: "🔥 47d | Today: 3/5 tasks"
- Accessory Circular: Streak number only ("47")

### Home Screen Widgets

**Small (2×2):** Master streak number + today's status dot

```
┌─────────────┐
│   STREAK    │
│     47      │  ← heavy font
│   🟢 Today  │
└─────────────┘
```

**Medium (4×2):** Last 4 weeks mini-heatmap + streak

```
┌──────────────────────────────┐
│  STREAK  🔥 47   [mini grid] │
└──────────────────────────────┘
```

All widgets: paper background, thick border, same design language as the app.
