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

## 4. Split Calculation Rules

When a transaction of amount $A$ is split among $N$ total people (the user $+ (N - 1)$ friends):
- **User's Share:** $S_{user} = \frac{A}{N}$ (or custom defined)
- **Total To Collect:** $C_{total} = A - S_{user}$
- **Per-Friend Share:** $S_{friend} = \frac{C_{total}}{N - 1}$
- **Net Personal Expense for Budgeting:** Only $S_{user}$ counts toward the user's personal monthly spending metrics, while $A$ is tracked as gross outflow.

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
