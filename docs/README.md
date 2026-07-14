# Streak — Documentation Index

iOS habit tracker. Local-first. Neo-Brutalist. AltStore distributed.

---

## Documents

| File | Contents |
|------|----------|
| [PRD.md](./PRD.md) | Product Requirements Document — what the app does, for whom, and why |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Clean Architecture + DDD structure, SOLID principles, module layout, folder structure |
| [HLD.md](./HLD.md) | High-Level Design — system components, screen map, data flows, technical decisions |
| [UI_UX_SPEC.md](./UI_UX_SPEC.md) | Neo-Brutalist design language, color tokens, typography, component library, screen designs |
| [DATA_MODELS.md](./DATA_MODELS.md) | All entities, fields, business rules, ER diagram, export/import format |
| [HOSTING.md](./HOSTING.md) | AltStore distribution, IPA build process, signing, GitHub releases, entitlements |
| [IOS_INTEGRATIONS.md](./IOS_INTEGRATIONS.md) | Widgets (WidgetKit), Shortcuts (App Intents), Notifications, iCloud sync |
| [FUTURE_MODULES.md](./FUTURE_MODULES.md) | All planned future features with architecture notes for each |
| [codebase/README.md](./codebase/README.md) | Codebase Architecture & Modular Unit Documentation — deep-dive explanation of all code units |

---

## Quick Reference

**Tech stack:** Swift 5.9+ / SwiftUI / SwiftData / iOS 17+  
**Distribution:** AltStore (free Apple ID sideload)  
**Backend:** None — 100% local  
**UI style:** Neo-Brutalism — paper background `#F5F0E8`, thick `2.5pt` dark borders, no shadows  
**Minimum device:** iPhone XS running iOS 17

**Core modules (v1.0):**
1. Habit Categories with per-category consistency heatmap + streak
2. Master consistency graph + master streak
3. Daily to-do planning with nightly reminder
4. Goals with game-style progress bar
5. Daily Assist reflection form
6. Settings & Onboarding with active day rollover settings and notifications
