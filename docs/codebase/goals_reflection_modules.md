# Goals & Daily Assist Reflection Modules

This module documents the long-term Goals tracker and the Daily Assist reflection journal components.

---

## Goals Module Code Units

### 1. `Goal`
- **File Path:** [Goal.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Entities/Goal.swift)
- **Responsibility:** A domain entity representing a long-term goal.
- **Properties:**
  - `id`: UUID.
  - `title`: Description of the goal.
  - `goalType`: GoalType enum.
  - `categoryId`: Optional linked category.
  - `targetValue`: The target milestone value.
  - `currentValue`: Current progress.
  - `unit`: Display unit (e.g. `"days"`, `"₹"`, `"km"`).
  - `startDate` & `targetDate`: Goal timeline.
  - `isCompleted`: Completion status.
- **Calculated Properties & Progress Calculation Rules:**
  - `progressFraction`: Returns `currentValue / targetValue` capped at `1.0`.
  - **Dynamic Progress Updates:**
    - **`consecutiveStreak`**: Driven by the linked category's active streak count. If the streak resets to 0, progress drops to 0.
    - **`cumulativeDays`**: Driven by querying the count of successful (`.green`) `DayEntry` records for the linked category starting from `startDate` to today.
    - **`milestoneBased`**: Driven by the cumulative sum of all logged `GoalProgressEntry` values since `startDate`.
    - **`taskCounter`**: Driven by querying the total count of completed `Task` records associated with the linked category from `startDate` to today.

### 2. `GoalProgressEntry`
- **File Path:** [GoalProgressEntry.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Entities/GoalProgressEntry.swift)
- **Responsibility:** Records daily progress updates for milestone-based goals.
- **Properties:**
  - `goalId`: Linked goal.
  - `date`: Entry date (midnight).
  - `value`: Cumulative progress value.
  - `note`: Optional text note.

### 3. `GoalType`
- **File Path:** [GoalType.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/ValueObjects/GoalType.swift)
- **Responsibility:** Classification of goal tracking methods.
- **Cases:**
  - `consecutiveStreak`: Progress updates automatically based on a category's consecutive streak count (resets to 0 on a miss).
  - `cumulativeDays`: Progress updates automatically based on the count of green days since start (pauses on a miss).
  - `milestoneBased`: Progress is logged manually by the user over time (accumulative).
  - `taskCounter`: Progress updates automatically based on the count of completed tasks in a category since start (pauses on a miss).

### 4. `GoalRepository`
- **File Path:** [GoalRepository.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Repositories/GoalRepository.swift)
- **Responsibility:** Repository protocol for fetching goals, active list filtering, saving goal status, and logging daily progress entries.

### 5. `GoalWidget`
- **File Path:** [GoalWidget.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/StreakWidgets/GoalWidget.swift)
- **Responsibility:** Displays the progress bar, completion ratio, and deadline metric of a user-selected goal. Supports `systemMedium` sizes.

---

## Daily Assist Reflection Code Units

### 1. `ReflectionEntry`
- **File Path:** [ReflectionEntry.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Entities/ReflectionEntry.swift)
- **Responsibility:** A domain model representing a daily reflection journal entry.
- **Properties:**
  - `id`: UUID.
  - `date`: Start of the day (midnight).
  - `accomplishments`: Free-text summary of daily wins.
  - `missedItems`: Log of missed items and explanations.
  - `tomorrowPriorities`: Tomorrow's priorities.
  - `goalNotes`: Goal progress notes.
  - `consistencyRating`: Overall daily rating (integer value bounded between `0` and `5`).
  - `createdAt` & `updatedAt`: Timestamps.

### 2. `ReflectionRepository`
- **File Path:** [ReflectionRepository.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Repositories/ReflectionRepository.swift)
- **Responsibility:** Repository protocol defining queries to fetch reflections by date, write journal entries, and query complete histories.

### 3. `SaveReflectionUseCase`
- **File Path:** [SaveReflectionUseCase.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Application/UseCases/Reflection/SaveReflectionUseCase.swift)
- **Responsibility:** Updates the `updatedAt` timestamp and saves daily reflection entries.

---

## Current Status & Roadmap

The domain models, repository interfaces, SwiftData entities, and repository implementations for both Goals and Reflections are fully implemented:
- Persistent models are registered in `ModelContainerFactory`.
- Repository classes are implemented in `SwiftDataRepositories.swift`.
- Wires and use cases are resolved in `AppEnvironment` and `AppRouter`.

*The presentation screens (e.g. `GoalListView`, `GoalDetailView`, and `ReflectionFormView`) are currently stubbed in the tab bar and will be built out in future development cycles.*
