# Habits & Categories Module

This module documents category creation, day status resolution, streak calculations, and category detailed views.

---

## Domain Entities & Value Objects

### 1. `Category`
- **File Path:** [Category.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Entities/Category.swift)
- **Responsibility:** A domain model representing a group of tasks (e.g. "Gym", "Reading").
- **Properties:**
  - `id`: UUID.
  - `name`: Text description.
  - `colorHex`: Accent hex color string (e.g. `#E74C3C`).
  - `sortOrder`: Grid sorting preference.
  - `isArchived`: Soft-delete status flag.

### 2. `DayEntry`
- **File Path:** [DayEntry.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Entities/DayEntry.swift)
- **Responsibility:** Cached record of consistency status for a specific date and category (or overall/master if `categoryId` is nil).
- **Properties:**
  - `date`: Start of day (midnight).
  - `categoryId`: Optional identifier.
  - `status`: Resolved status enum (`.green`, `.red`, or `.future`).
  - `taskCount`: Total tasks planned.
  - `completedCount`: Completed tasks.

### 3. `DayStatus`
- **File Path:** [DayStatus.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/ValueObjects/DayStatus.swift)
- **Responsibility:** Resolves daily completion status.
- **Rules:**
  - Future dates: `.future`.
  - Date is today or earlier and has zero tasks: `.red`.
  - All tasks completed (taskCount > 0): `.green`.
  - Tasks missed: `.red`.

---

## Application Use Cases

### 1. `CreateCategoryUseCase`
- **File Path:** [CreateCategoryUseCase.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Application/UseCases/Habits/CreateCategoryUseCase.swift)
- **Responsibility:** Validates new categories. Enforces non-empty names and valid hex formats. Resolves the next `sortOrder` index.

### 2. `ResolveDayStatusUseCase`
- **File Path:** [ResolveDayStatusUseCase.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Application/UseCases/Habits/ResolveDayStatusUseCase.swift)
- **Responsibility:** Recalculates category completion status. Evaluates active tasks, queries task completions, maps statuses, and persists updates.

### 3. `CalculateStreakUseCase`
- **File Path:** [CalculateStreakUseCase.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Application/UseCases/Habits/CalculateStreakUseCase.swift)
- **Responsibility:** Computes current consecutive completion streaks.
- **Workflow:**
  1. Fetches all historical entries for the category.
  2. Starts at today (`Date()`) and walks backward day by day.
  3. Increments the streak count for every `.green` status day.
  4. Stops on the first `.red` status day.
  5. Returns the count.

---

## Presentation Layer (UI)

### 1. `CategoryViewModel`
- **File Path:** [CategoryViewModel.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Presentation/Categories/CategoryViewModel.swift)
- **Responsibility:** Drives category details, fetching category profiles, calendar grids, streaks, linked goals, and task history.

### 2. `CategoryDetailView`
- **File Path:** [CategoryDetailView.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Presentation/Categories/CategoryDetailView.swift)
- **Responsibility:** Displays category history, streak badges, heatmap grids, linked goals, and past task lists. Allows archiving categories.

### 3. `AddCategoryView`
- **File Path:** [AddCategoryView.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Presentation/Categories/AddCategoryView.swift)
- **Responsibility:** Handles category creation and editing. Includes input validation, native color pickers, and live card previews.

### 4. `MultiCategoryWidget`
- **File Path:** [MultiCategoryWidget.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/StreakWidgets/MultiCategoryWidget.swift)
- **Responsibility:** A compact home screen widget (Small and Medium sizes) displaying a list of categories and their streak counts. Users can choose which categories to display via the standard widget options panel. Defaults to listing all active categories.

### 5. `OverallDetailView`
- **File Path:** [OverallDetailView.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Presentation/Home/OverallDetailView.swift)
- **Responsibility:** Displays overall daily task completion history on a scrollable line graph. Selecting any day's point displays the category-grouped task list for that date.
