# AGENTS.md
## Streak iOS App — Rules for All Agents

Any agent working on this project (streak, anti-gravity, or any future agent) must follow these rules. No exceptions.

---

## Project Identity

- **App:** Streak — iOS habit tracker
- **Stack:** Swift 5.9+ / SwiftUI / SwiftData / iOS 17+
- **Distribution:** AltStore sideload. No App Store. No backend. No network calls.
- **Full docs:** `docs/` — read before touching anything

---

## Hard Rules

### Architecture
- Clean Architecture + DDD. Four layers: `Presentation → Application → Domain ← Infrastructure`
- Domain layer: pure Swift only. Zero UIKit/SwiftUI/SwiftData imports.
- One use case = one struct = one job.
- Repository protocols live in Domain. SwiftData implementations live in Infrastructure.
- Dependency injection via `AppEnvironment` only. No DI framework.
- State management: `@Observable` only. No Combine, no Redux, no TCA.

### Adding Any Feature
Must follow this order — no shortcuts:
1. Update `docs/` first
2. Domain entity → `Domain/Entities/`
3. Repository protocol → `Domain/Repositories/`
4. Use cases → `Application/UseCases/[Feature]/`
5. SwiftData implementation → `Infrastructure/Persistence/`
6. View + ViewModel → `Presentation/[Feature]/`
7. Register in `AppEnvironment` + `AppRouter` only
8. No other existing file should need modification

### Documentation (hard rule — not optional)
Every feature built = docs updated in the same session. See `docs/` for structure.
The doc-sync skill (`.kiro/skills/doc-sync.md`) has the exact mapping of what to update where.

| Built/changed | Update |
|---------------|--------|
| New entity | `DATA_MODELS.md` |
| New use case | `ARCHITECTURE.md` |
| New screen | `HLD.md` + `UI_UX_SPEC.md` |
| New iOS integration | `IOS_INTEGRATIONS.md` |
| New feature module | `PRD.md` (remove from `FUTURE_MODULES.md`) |
| New future feature | `FUTURE_MODULES.md` |
| Breaking schema change | `DATA_MODELS.md` + version bump + `CHANGELOG.md` |

### UI (Neo-Brutalist — non-negotiable)
- Background: `#F5F0E8`. Surface: `#EFEFDF`. Border: `#1A1A1A`, `2.5pt`.
- No shadows. No gradients. No blur. No frosted glass.
- Category color = user's chosen hex. Used for card border, dots, progress bar fill.
- Min tap target: 44×44pt everywhere.
- No loading spinners. No skeleton loaders. No illustrations in empty states.

### Data
- Day status: `.green` (all tasks done) or `.red` (missed OR no tasks set). No partial state.
- Any red day resets streak. No exceptions.
- Categories: archive only, never hard delete.
- Tasks: today or tomorrow only (v1).

### Code Quality
- No new dependency unless unavoidable — sideloaded apps have no SPM server guarantees.
- No abstractions not explicitly requested.
- Follow ponytail.md efficiency rules (global steering, always active).

---

## Agents in This Project

| Agent | File | Purpose | Shortcut |
|-------|------|---------|----------|
| `streak` | `.kiro/agents/streak.json` | Main development agent, full docs in context | `ctrl+shift+s` |

To add a new agent (e.g., anti-gravity): create `.kiro/agents/anti-gravity.json`, add `docs/README.md` and `.kiro/skills/doc-sync.md` to its resources, reference this file in its prompt.

---

## Docs Structure

```
docs/
├── README.md            ← index + quick reference
├── PRD.md               ← what the app does and why
├── ARCHITECTURE.md      ← layer structure, SOLID, folder layout, DI
├── HLD.md               ← system diagram, screen map, data flows
├── UI_UX_SPEC.md        ← Neo-Brutalist spec, components, screen designs
├── DATA_MODELS.md       ← all entities, fields, rules, ER diagram, export format
├── HOSTING.md           ← AltStore, IPA build, signing, entitlements
├── IOS_INTEGRATIONS.md  ← widgets, shortcuts, notifications, iCloud
└── FUTURE_MODULES.md    ← planned features with architecture notes
```
