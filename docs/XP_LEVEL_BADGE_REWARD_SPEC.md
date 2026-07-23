# Streak XP, Level, Badge & Reward System — Design Specification

> **Status:** PRE-IMPLEMENTATION — review and approve before any code is written.
> **Reference systems:** Duolingo (streak freeze, gems, daily quests), Habitica (XP + HP decay, gear shop), Stack Overflow (reputation, badges), HackerRank (badges + leaderboards), WoW/RPG (polynomial XP curve, prestige titles).

---

## 1. Philosophy & Goals

| Principle | How it applies |
|---|---|
| **Reward effort, not just outcome** | Even partial completion earns XP, full completion earns more |
| **Loss aversion drives habits** | Missing days *costs* XP — users feel the pain of inaction |
| **Prestige through titles** | Titles mean something because levels are hard to maintain |
| **Meaningful shop** | Every item in the shop connects to a real-world self-improvement trade-off |
| **No pay-to-win** | Everything is earned in-app. No IAP, no shortcuts |

---

## 2. The XP Economy — Earning

### 2.1 Daily Earning Table

| Action | XP Earned | Notes |
|---|---|---|
| Complete a single daily task | **+10 XP** | Per task |
| Complete ALL daily tasks (overall green day) | **+50 XP bonus** | On top of per-task XP |
| Complete all tasks for a specific category | **+25 XP bonus** | Per full-green category |
| Habit/routine task completed | **+15 XP** | Per habit task |
| Habit/routine: full day all habits done | **+30 XP bonus** | On top of per-habit XP |
| Complete a weekly task | **+30 XP** | Per task |
| Complete a monthly task | **+80 XP** | Per task |
| Backlog task completed | **+20 XP** | Per task |

### 2.2 Milestone Bonuses

| Milestone | XP |
|---|---|
| Perfect week (7 consecutive green days) | **+200 XP** |
| Perfect month (all days green) | **+1,000 XP** |
| Streak: 7 days | **+100 XP** |
| Streak: 30 days | **+500 XP** |
| Streak: 100 days | **+2,000 XP** |
| Streak: 365 days | **+10,000 XP** |
| First task ever | **+50 XP** (one-time) |
| First green day | **+100 XP** (one-time) |
| First perfect week | **+250 XP** (one-time) |

### 2.3 Streak Multiplier (the "momentum bonus")

The longer your streak, the more XP each green day earns:

| Current Streak | Daily Bonus Multiplier |
|---|---|
| 1–6 days | ×1.0 (base) |
| 7–13 days | ×1.2 |
| 14–29 days | ×1.5 |
| 30–59 days | ×2.0 |
| 60–99 days | ×2.5 |
| 100+ days | ×3.0 |

> Applied only to the "Complete ALL daily tasks" +50 XP bonus, not per-task XP.

---

## 3. The XP Economy — Losing

> **Design rationale:** XP decay mirrors real life — neglect has a cost. But it should never feel so punishing that users quit. Floors and caps prevent death spirals.

### 3.1 Daily Decay Table

| Failure | XP Lost | Notes |
|---|---|---|
| Overall red day (all tasks missed or no tasks added) | **−30 XP** | Applied at end of day |
| Category red day | **−10 XP** | Per red category, capped at 3 categories per day |
| Habit routine task missed | **−15 XP** | Per missed routine task |
| Streak break (after ≥7 days) | **−50 XP** | One-time penalty when streak resets |
| Streak break (after ≥30 days) | **−150 XP** | Replaces the above penalty |

### 3.2 Anti-Death-Spiral Protections

- **XP Floor:** XP can never go below 0. You can't become "negative XP."
- **Daily Decay Cap:** Maximum daily XP loss is capped at **−150 XP** regardless of how many categories or tasks are missed.
- **Level Floor:** Level can drop but never below 1.
- **Streak Freeze Shield:** If you own an active Streak Freeze, the streak-break penalty is also waived.

---

## 4. Level System

### 4.1 XP Curve Formula

Uses a **polynomial curve** (industry standard, avoids grind walls):

```
XP required for Level N = 100 × (N ^ 1.8)
```

| Level | XP to reach this level | Total XP accumulated |
|---|---|---|
| 1 | 100 | 100 |
| 5 | 1,149 | 3,337 |
| 10 | 3,981 | 17,700 |
| 20 | 13,195 | 96,700 |
| 30 | 26,827 | 282,000 |
| 50 | 67,608 | 1,130,000 |
| 75 | 140,977 | 3,260,000 |
| 100 | 239,503 | 7,200,000 |

> At a realistic pace of ~150 XP/day (good user), Level 10 takes ~4 months, Level 20 takes ~2 years. This is intentional — high levels are genuinely rare.

### 4.2 Level Drop Rule

If your cumulative XP drops (due to daily decay), your displayed level reflects your current XP total. There is no separate "level decay" — level is always `floor(inverse of formula applied to totalXP)`. So losing XP naturally lowers your level if you cross a threshold.

> **Example:** You're Level 12 with 26,000 total XP. A bad week drops you to 24,500 XP → you drop back to Level 11.

---

## 5. Title System

Titles are awarded at level thresholds. Each title has a short subtitle that captures the spirit.

| Level Range | Title | Subtitle |
|---|---|---|
| 1–4 | 🌱 **Seedling** | "Just getting started" |
| 5–9 | 🔥 **Sparked** | "Something's igniting" |
| 10–14 | 🏃 **In Motion** | "Momentum is building" |
| 15–19 | 💪 **Committed** | "This is becoming a lifestyle" |
| 20–24 | 🧱 **Builder** | "Consistency is your superpower" |
| 25–29 | ⚡ **Charged** | "Running on discipline" |
| 30–39 | 🎯 **Focused** | "Distraction can't reach you" |
| 40–49 | 🛡 **Resilient** | "Setbacks are just data" |
| 50–59 | 🏆 **Elite** | "You've outpaced most humans" |
| 60–74 | 🌟 **Champion** | "Top 1% of consistent people" |
| 75–89 | 🔱 **Legend** | "Your discipline is legendary" |
| 90–99 | ☄️ **Transcendent** | "Beyond ordinary limits" |
| 100 | 👑 **Immortal** | "You are the system" |

---

## 6. Badge System

Badges are **permanent** — once earned, they never go away, even if XP/level drops.

### 6.1 Badge Categories

#### 🔥 Streak Badges (Milestone)
| Badge | Trigger |
|---|---|
| **First Flame** | First ever green day |
| **Week Warrior** | 7-day streak |
| **Fortnight Fighter** | 14-day streak |
| **Month Master** | 30-day streak |
| **Century Keeper** | 100-day streak |
| **365 Club** | 365-day streak |
| **Comeback King** | Rebuild a streak to 7+ after it broke at ≥14 |

#### 🏗 Consistency Badges (Accumulation)
| Badge | Trigger |
|---|---|
| **Habit Starter** | First habit routine created |
| **Habit Stack** | 3 active habit routines simultaneously |
| **Perfect Week** | All 7 days green in a calendar week |
| **Perfect Month** | All days green in a calendar month |
| **Century Tasks** | 100 total tasks completed |
| **Task Titan** | 1,000 total tasks completed |
| **Habit Master** | 30 consecutive days all habit tasks done |

#### 🎯 Goal Badges (Achievement)
| Badge | Trigger |
|---|---|
| **Goal Setter** | First goal created |
| **Goal Crusher** | First goal 100% completed |
| **Overachiever** | Complete 3 goals |
| **Vision Board** | 5 active goals simultaneously |

#### 🏅 Level Badges (Prestige)
| Badge | Trigger |
|---|---|
| **Rising** | Reach Level 10 |
| **Committed** | Reach Level 20 |
| **Elite** | Reach Level 50 |
| **Legend** | Reach Level 75 |
| **Immortal** | Reach Level 100 |

#### 🛒 Shop Badges (Participation)
| Badge | Trigger |
|---|---|
| **First Purchase** | First item bought from shop |
| **Self-Aware** | Create a first custom reward |
| **Well-Stocked** | Own 3 streak freezes at once |
| **Big Spender** | Spend 5,000 XP total in the shop |

#### 💀 Adversity Badges (Rare/Hidden — shown only after earned)
| Badge | Trigger |
|---|---|
| **Phoenix** | Rebuild from Level drop back to previous level |
| **Unbreakable** | Use a streak freeze and then complete 14 more days |
| **Ghost Protocol** | Miss a full week, then come back and get 7 straight green days |

---

## 7. Reward Shop

### 7.1 Fixed Rewards (Defined by the system)

These are unlocked only at specific **minimum levels** AND purchased with XP.

| Reward | XP Cost | Min Level | Effect |
|---|---|---|---|
| ⛄ **Streak Freeze** | 200 XP | Level 3 | Protects streak for 1 missed day. Must equip before day ends. Max 2 owned at once. |
| ⚡ **XP Boost (24h)** | 300 XP | Level 5 | All XP earned in next 24h is doubled. |
| 🔄 **Double Habit Day** | 400 XP | Level 8 | One day where all habit XP is ×3. |
| 📅 **Weekend Shield** | 500 XP | Level 10 | Protects streak across Sat + Sun (2-day freeze, used as single unit). |
| 🌙 **Binge Night Pass** | 600 XP | Level 15 | One guilt-free night off — streak stays intact, but no XP earned or lost. |
| 💤 **Rest Day Pass** | 350 XP | Level 12 | Similar to Binge Night, but covers a full calendar day. |
| 🎯 **XP Multiplier (1 Week)** | 1,500 XP | Level 25 | 1.5× XP multiplier for 7 days. |
| 🏆 **Prestige Badge Slot** | 2,000 XP | Level 30 | Unlocks a custom badge display slot on your profile. |
| ☄️ **Legendary Streak Armor** | 5,000 XP | Level 50 | Protects a 30-day or longer streak for up to 3 missed days in a month. |

> **Cap rules:** Streak Freeze max owned = 2. Binge/Rest passes max owned = 1.

### 7.2 User-Defined Rewards (Custom)

The user creates their own rewards with a self-chosen name and description, but the XP price is chosen from **fixed tiers** — the system enforces these tiers to prevent the economy from collapsing.

| Tier | XP Cost | Intended for |
|---|---|---|
| 🟢 **Snack** | 150 XP | Small treats — a coffee, 30 min YouTube, dessert |
| 🔵 **Leisure** | 400 XP | A gaming session, episode binge, a good meal out |
| 🟡 **Experience** | 800 XP | A day trip, a movie theatre visit, a restaurant |
| 🟠 **Splurge** | 1,500 XP | A weekend activity, a new book/game, a spa day |
| 🔴 **Milestone** | 3,000 XP | A big personal reward — trip planning, major purchase |
| 👑 **Dream** | 7,000 XP | Something the user saves up for long-term |

> Users name the reward (e.g. "Binge GOT season", "Buy new sneakers") but must pick one of these tiers. They cannot enter an arbitrary number.

---

## 8. Data Model Requirements

New entities needed:

```
PlayerProfile
  - totalXP: Int            // ever-accumulated, decays in place
  - level: Int              // derived from totalXP
  - title: String           // derived from level
  - streakFreezes: Int      // owned count (max 2)
  - ownedItems: [ShopItem]  // active/unused items

Badge
  - id: UUID
  - badgeKey: String        // e.g. "week_warrior"
  - earnedAt: Date

XPTransaction
  - id: UUID
  - date: Date
  - amount: Int             // positive = earn, negative = decay
  - reason: XPTransactionReason (enum)

ShopItem
  - id: UUID
  - type: ShopItemType (enum: streakFreeze, xpBoost, restDay, bingePass, etc.)
  - purchasedAt: Date
  - usedAt: Date?           // nil = still active
  - expiresAt: Date?        // for time-limited boosts

CustomReward
  - id: UUID
  - title: String
  - description: String
  - tier: CustomRewardTier (enum: snack, leisure, experience, splurge, milestone, dream)
  - xpCost: Int             // fixed by tier, not user input
  - redeemedAt: Date?       // nil = not yet redeemed
  - createdAt: Date
```

---

## 9. Key Logic Rules

### Level Calculation
```swift
func level(for totalXP: Int) -> Int {
    // Solve: 100 * (N^1.8) = totalXP  →  N = (totalXP / 100)^(1/1.8)
    return max(1, Int(pow(Double(totalXP) / 100.0, 1.0 / 1.8)))
}
```

### XP Award Triggers
- XP is awarded when a task is toggled to **completed**.
- Milestone/streak bonuses are checked once per day at end of day (when day resolves to green/red).
- Decay is applied once per day when a day resolves to **red** (same trigger as DayStatus.red).

### Streak Freeze Logic
- Must be **equipped** (activated) before the day ends.
- Once equipped for a day, it consumes 1 freeze from inventory.
- That day's DayStatus shows as **protected** (neutral, not red).
- Streak does not break, and no XP decay for that day.
- The streak-break XP penalty is also waived.

### Badge Award Trigger
- Checked any time a relevant action completes.
- Each badge can only be awarded once (idempotent check on `badgeKey`).

### Custom Reward Redemption
- Tapping "Redeem" deducts XP immediately and stamps `redeemedAt`.
- If XP balance is insufficient, the purchase is blocked with a clear message.
- Redeemed custom rewards are archived (kept in history), not deleted.

---

## 10. Open Design Questions (Need Your Input)

> Before implementation starts, please answer these:

1. **Level drop aggression:** Should level drops happen in real-time as XP decays, or only checked/displayed once per day (at end of day resolution)?

2. **Streak Freeze activation:** Should the user manually tap "Equip" for the freeze before a day is missed? Or should it auto-activate when a streak is about to break?

3. **XP history visibility:** Should users see a full transaction log (like a bank statement of XP earned/lost per day), or just the current balance + level?

4. **Custom reward limit:** Should there be a cap on how many custom rewards a user can create (e.g., max 10)?

5. **Binge Night / Rest Day:** Are these your own ideas that you've defined, or should the app let the user name/define what their "binge night" is? (This affects whether it's a fixed or custom reward.)

6. **Badge display:** Where should badges appear? Options:
   - On the Home screen (profile section at top)
   - Only inside a dedicated "Profile" tab
   - On category cards (category-specific badges)
   - All of the above?

7. **Level visibility:** Should other categories/views show your current level/title, or only a dedicated Profile screen?

8. **App tab:** Should XP/Level/Shop live in a new **Profile** tab in the main tab bar, or inside Settings, or as its own navigation area?

---

## 11. Recommended Implementation Phases

| Phase | Scope |
|---|---|
| **Phase 1** | `PlayerProfile`, XP earning on task completion, level + title calculation, basic profile screen |
| **Phase 2** | XP decay on red days, streak-break penalty, XP transaction log |
| **Phase 3** | Badge system (all badge types + award logic) |
| **Phase 4** | Fixed reward shop (streak freeze, XP boost, rest day passes) |
| **Phase 5** | Custom rewards (user-defined, tier-based pricing) |
| **Phase 6** | Streak Freeze integration with DayStatus |
| **Phase 7** | Streak multiplier on long streaks |
