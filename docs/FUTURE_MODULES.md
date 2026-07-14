# Future Modules
## App: Streak (iOS Habit Tracker)
**Version:** 1.0  
**Date:** 2026-07-08  
**Status:** Living document — updated as new features are planned

---

## Purpose

This document catalogs all features that are explicitly out of scope for v1.0 but are designed to be added in future versions. The architecture is built to accommodate all of these without restructuring existing code.

Each module follows the same addition protocol:
1. Define domain entity
2. Define repository protocol
3. Write use cases
4. Implement SwiftData repository
5. Build SwiftUI view + ViewModel
6. Register in AppEnvironment
7. Add navigation entry in AppRouter
8. Write documentation

---

## Module 1: Proof System

**Priority:** High (next after v1.0)

### Description
When completing a task, the user can optionally submit "proof" of completion. This adds accountability even in a single-user context.

### Proof types (planned)
| Type | Description |
|------|-------------|
| Photo | User takes a photo as proof (e.g., gym selfie, book page) |
| Note | Free text note attached to the completion |
| Number | A logged value (e.g., weight lifted, pages read) |
| Location | GPS check-in (e.g., at the gym location) |
| None | Default — no proof required |

### User flow
- When creating a task, user optionally selects the required proof type
- When completing that task, if proof is required, the proof capture screen opens before the task is marked done
- Proofs are stored locally per task completion
- Proof photos stored in app's local storage (not Photos library unless user explicitly saves)

### Data model additions
```
ProofEntry
├── id: UUID
├── taskId: UUID
├── completedAt: Date
├── proofType: ProofType
├── textNote: String?
├── numericValue: Double?
├── unit: String?
├── photoPath: String?       ← local file path
├── latitude: Double?
└── longitude: Double?
```

### Architecture note
No existing entity changes. New `ProofEntry` entity added alongside `Task`. `CompleteTaskUseCase` gains an optional `ProofEntry?` parameter.

---

## Module 2: Friend Accountability

**Priority:** Medium

### Description
A social accountability layer where a friend can verify whether the user completed their tasks. Designed as a lightweight check-in, not a full social network.

### Planned approaches (in order of preference)

#### Option A: WhatsApp / iMessage Shortcut (no backend)
- A Shortcuts automation generates a summary of the day's tasks and opens WhatsApp/iMessage to a specific contact
- The friend replies manually — no in-app integration
- Simple, no infrastructure needed
- The app reads the friend's response as a manual input (the user logs it themselves)

#### Option B: Shared iCloud (peer-to-peer, no server)
- Two users share a CloudKit public zone
- User A's tasks are visible to User B in read-only mode
- User B can mark items as "verified" from their device
- No server — uses Apple's CloudKit infrastructure
- Requires both users to be on the app

#### Option C: Backend database (full implementation)
- Lightweight backend (e.g., Supabase free tier or PocketBase self-hosted)
- Users create accounts (email/password or Sign in with Apple)
- Friends connect via unique user codes
- Friend's device polls for their friend's task status
- This enables the "WhatsApp group style" accountability

### Recommended path
Start with Option A (pure Shortcuts, no code needed), then move to Option B when the demand is confirmed, then Option C only if Option B is insufficient.

### Data model additions (Option B/C)
```
FriendLink
├── id: UUID
├── localUserId: UUID
├── friendIdentifier: String    ← CloudKit/backend user ID
├── friendDisplayName: String
└── createdAt: Date

FriendVerification
├── id: UUID
├── taskId: UUID
├── verifiedByFriendId: UUID
├── verifiedAt: Date
└── note: String?
```

---

## Module 3: Screen Time Integration

**Priority:** Low (requires App Store approval)

### Description
Use the `ManagedSettings` framework to programmatically restrict access to distracting apps until the user completes their tasks for the day.

### How it would work
- User configures "blocked apps" for each time window
- Until all morning tasks are checked, selected apps (e.g., Instagram, YouTube) are blocked
- When all tasks complete, restrictions lift automatically
- Uses `FamilyActivityPicker` + `ManagedSettingsStore`

### Blocker
Requires the **Family Controls** entitlement (`com.apple.developer.family-controls`). Apple grants this only to apps reviewed by the App Store team. Not available for sideloaded apps.

**Path to implement:**
1. Publish app to App Store (requires an App Store Connect account)
2. Apply for Family Controls entitlement (justification required)
3. Implement the module

---

## Module 4: Health App Integration

**Priority:** Medium

### Description
Read data from Apple Health to auto-complete certain habit tasks.

### Examples
| Health data | Auto-completes |
|-------------|---------------|
| Workout logged (type: functional strength) | "Gym" task for today |
| Steps > 8000 | "Walk" task for today |
| Sleep > 7h logged | "Sleep goal" task |
| Mindful minutes > 10 | "Meditation" task |

### Data flow
```
HealthKit query (read-only)
        ↓
HealthKitBridge (Infrastructure layer)
        ↓
AutoCompleteTaskUseCase
        ↓
CompleteTaskUseCase (existing, no changes)
```

### Architecture note
New `HealthKitBridge` struct in Infrastructure layer. New `AutoCompleteTaskUseCase`. No changes to Domain or existing use cases. New permission: HealthKit read access.

---

## Module 5: Advanced Goal Types

**Priority:** Medium

### Description
Expand the Goal module with richer goal structures.

| Type | Description |
|------|-------------|
| Habit chain | Link multiple categories — all must be green to count progress |
| Countdown | "X days until [event]" reverse tracker |
| Ratio goal | "Read 3 of 5 days per week" — partial consistency accepted |
| Financial goal | Currency-aware, with formatted display |
| Learning goal | Track chapters/pages/hours in a resource |

---

## Module 6: Weekly & Monthly Review

**Priority:** Medium

### Description
A structured weekly review screen (inspired by GTD weekly review methodology).

**Content:**
- Last week's consistency percentage per category
- Goals progress this week
- Upcoming next week tasks / planning
- Space to write weekly intentions

Stored as `WeeklyReview` entity. Triggered by a weekly notification.

---

## Module 7: Themes (Dark Mode + Custom Themes)

**Priority:** Low

### Description
Multiple visual themes selectable in Settings.

| Theme | Description |
|-------|-------------|
| Paper (default) | Current Neo-Brutalist light theme |
| Ink | Dark background, white borders, same Brutalist aesthetic |
| Carbon | Dark with dark gray cards — less harsh than Ink |

Implementation: A `ThemeProvider` environment object. All color tokens reference theme values instead of hardcoded hex strings. Existing component library requires no structural changes — only color token binding.

---

## Module 8: Widgets Expansion

**Priority:** Medium

### Planned additional widgets
| Widget | Size | Content |
|--------|------|---------|
| Goal progress | Small | Single goal progress bar + % |
| Weekly summary | Large | 7-day view of all categories |
| Reflection prompt | Medium | Today's Daily Assist question |
| Category grid | Large | All categories + their today status |

---

## Module 9: Import from Other Apps

**Priority:** Low

### Description
Import habit history from popular apps so users don't lose their data when switching.

| App | Import format |
|-----|---------------|
| Habitica | JSON export |
| Streaks | Backup file |
| Apple Reminders | EventKit integration |

---

## Module 10: Notification Enhancements

**Priority:** Medium

### Planned enhancements
- **Inline task completion from notification:** iOS allows text input and button actions in notifications. Allow checking off a task directly from the lock screen notification without opening the app.
- **Dynamic Island integration (iPhone 14 Pro+):** Show current streak count in the Dynamic Island
- **Focus Filter:** Integrate with iOS Focus modes — e.g., in "Work" focus, only show Work-category tasks in widgets

---

## Architecture Guarantee

All modules above can be added by following the standard module addition protocol. No existing domain entity, use case, or view requires modification. The only files touched when adding a module are:
- `AppEnvironment.swift` (register new repository/service)
- `AppRouter.swift` (add navigation destination)
- New files for the new module

This is the architectural contract. If adding a feature requires modifying an existing use case, that is a signal to refactor the use case into a more focused form first.
