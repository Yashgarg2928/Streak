# Finance & Expense Tracker Architecture & Specification

## 1. Overview & Core Mission

The **Finance Tracker** in Streak provides ultra-fast personal expense logging, automated bill splitting, and a dedicated "Owed to Me" receivables ledger.

### Key Capabilities
1. **Interactive Top-of-Screen Window (No App Launch Required):** Powered by iOS `AppIntents`, users can double-tap the back of their iPhone, press the Action Button, or invoke Siri to open a native floating input window at the top of the screen to log payments in seconds.
2. **Automated Pop-Up on Closing Payment Apps:** iOS Shortcuts Automation automatically triggers a prompt when closing Google Pay, Paytm, PhonePe, CRED, or banking apps, preventing forgotten payments.
3. **Automated Bill Splitting & Debt Tracking:** Records shared expenses with automatic calculations. Entering a ₹300 bill with 3 people automatically computes:
   - Personal net share: **₹100**
   - Total to collect: **₹200** (**₹100/friend**)
   - Generates individual friend split records with one-tap settlement.
4. **Neo-Brutalist Dashboard:** Matches Streak's aesthetic with high-contrast borders, category badges, monthly spending metrics, and category analytics.

---

## 2. System Architecture

```
Domain Layer
├── Entities/FinanceTransaction.swift
│   ├── TransactionType (EXPENSE, INCOME)
│   ├── FinanceCategory (Food, Groceries, Shopping, Transport, Bills, etc.)
│   ├── SplitShare (id, personName, amountOwed, isSettled, settledAt)
│   ├── SplitDetails (totalAmount, numberOfPeople, myShare, totalToCollect, splits)
│   ├── FinanceTransaction (id, amount, type, category, note, date, isSplit, splitDetails)
│   └── FinanceSummary (totalSpentThisMonth, totalSpentToday, totalPendingToCollect, etc.)
└── Repositories/FinanceRepository.swift

Application Layer (Use Cases)
├── LogTransactionUseCase.swift
├── SettleSplitShareUseCase.swift
└── GetFinanceSummaryUseCase.swift

Infrastructure Layer (SwiftData & Storage)
├── Persistence/SwiftDataModels.swift
│   ├── FinanceTransactionModel (@Model)
│   └── SplitShareModel (@Model)
├── Persistence/SwiftDataRepositories.swift
│   └── SwiftDataFinanceRepository
└── Persistence/UserDefaultsSettingsRepository.swift (currencySymbol)

App Layer (AppIntents & Shortcuts)
├── FinanceAppIntents.swift
│   ├── FinanceCategoryAppEnum (AppEnum with Siri synonyms)
│   ├── LogExpenseIntent (Detailed intent with amount, category, note, split)
│   ├── QuickLogExpenseIntent (Rapid 1-tap intent for automations)
│   └── ExpenseAddedSiriSnippetView (Neo-Brutalist top-banner confirmation card)
└── StreakAppIntents.swift (StreakAppShortcuts)

Presentation Layer (SwiftUI)
├── Finance/FinanceViewModel.swift
├── Finance/FinanceMainView.swift (Master view with Expenses, Splits, Analytics subtabs)
├── Finance/AddTransactionSheet.swift (Numpad + live split calculator)
├── Finance/ShortcutsSetupGuideSheet.swift (In-app visual guide for automations)
└── Home/HomeView.swift (Master Finance Card widget on Home)
```

---

## 3. Data Models

### `FinanceTransaction`
| Property | Type | Description |
|---|---|---|
| `id` | `UUID` | Unique transaction identifier |
| `amount` | `Double` | Gross transaction amount |
| `type` | `TransactionType` | `.expense` or `.income` |
| `category` | `FinanceCategory` | Food, Groceries, Shopping, Transport, Bills, etc. |
| `note` | `String` | Description / purpose of transaction |
| `date` | `Date` | Transaction date |
| `isSplit` | `Bool` | Whether expense is shared with others |
| `splitDetails` | `SplitDetails?` | Split breakdown and friend shares |
| `createdAt` | `Date` | Creation timestamp |
| `updatedAt` | `Date` | Last modification timestamp |

### `SplitShare`
| Property | Type | Description |
|---|---|---|
| `id` | `UUID` | Unique share identifier |
| `personName` | `String` | Friend's name (e.g., "Rohan", "Aman") |
| `amountOwed` | `Double` | Amount owed by this person |
| `isSettled` | `Bool` | Whether the friend has paid back |
| `settledAt` | `Date?` | Timestamp when marked settled |

---

## 4. Split Modes & Custom Split Tools

The app supports two powerful splitting modes with real-time math and debt tracking:

### Mode A: Equal Division (`DIVIDE EQUALLY`)
- **Total People:** User $+ (N - 1)$ friends.
- **User's Share:** $S_{user} = \frac{A}{N}$
- **Per-Friend Share:** $S_{friend} = \frac{A - S_{user}}{N - 1}$
- **Optional Friend Names:** Enter custom comma-separated names (e.g. "Rohan, Aman, Priya") or use default identifiers ("Friend 1", "Friend 2").

### Mode B: Custom Amounts Per Friend (`CUSTOM AMOUNTS`)
The expense **does not have to divide equally**. You can set any exact, custom amount for each friend individually:
- Add as many friends as needed with `+ ADD ANOTHER FRIEND`.
- Specify each friend's name and the exact amount they owe.
- User's share automatically defaults to the remaining bill ($A - \sum S_{friends}$), or can be overridden manually.
- **Uneven/Arbitrary Splits Allowed:** Friends' debts are recorded directly into the receivables ledger even if the total doesn't equal the exact bill.

### Custom Split Tools (Quick Helpers)
- **⚡ Split Remainder:** Takes whatever bill amount remains unallocated and divides it equally among friends who currently have ₹0 (or across all friends if none are zero).
- **⚡ Split Evenly:** Divides the entire bill equally across all current friends and user as a baseline, allowing quick +/- adjustments.
- **⚡ Clear Amounts:** Resets all friend inputs to ₹0 for clean manual entry.

### Net Personal Expense for Budgeting
Only the user's personal share ($S_{user}$) counts toward personal monthly spending metrics. All friend shares are routed to the **SPLITS & OWED** receivables ledger with 1-tap settlement.

---

## 5. iOS Shortcuts & Automation Setup Guide

### Method A: Automated Pop-Up on Closing Payment Apps
1. Open the native **Shortcuts** app on your iPhone.
2. Tap the **Automation** tab at the bottom and tap **+** (New Automation).
3. Select **App** from the list of triggers.
4. Tap **Choose** and select all your payment apps:
   - *Google Pay, Paytm, PhonePe, CRED, Apple Wallet, Banking apps*
5. Check **Is Closed** (uncheck 'Is Opened').
6. Select **Run Immediately** and disable **Notify When Run**.
7. Tap **Next**, then choose **Quick Log Expense** (or **Log Expense in Streak**).
8. **Result:** Whenever you pay and swipe up to exit the payment app, iOS immediately drops a floating window from the top of your screen asking for the payment amount!

### Method B: Double-Tap Back of iPhone (Back Tap)
1. Open iPhone **Settings** > **Accessibility** > **Touch** > **Back Tap**.
2. Select **Double Tap** (or Triple Tap).
3. Scroll down to the **Shortcuts** section and select **Log Expense** or **Quick Expense**.
4. **Result:** Double-tapping the back of the iPhone instantly brings down the floating input banner without opening the app.

### Method C: Action Button (iPhone 15 Pro / 16 / 17)
1. Open iPhone **Settings** > **Action Button**.
2. Select **Shortcut** > **Log Expense in Streak**.
3. **Result:** Press the Action Button anytime to input an expense.
