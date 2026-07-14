# Tasks Module

This module details task creation, date validation, checkbox completion logic, and task list navigation.

---

## Domain Entities

### `Task`
- **File Path:** [Task.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Entities/Task.swift)
- **Responsibility:** A domain model representing a planned daily task.
- **Properties:**
  - `id`: UUID.
  - `title`: Description of the action (e.g. "Read 20 pages").
  - `categoryId`: Optional category identifier (nil for uncategorized tasks).
  - `targetDate`: Target execution date (normalized to midnight).
  - `isCompleted`: Completion status flag.
  - `completedAt`: Optional timestamp.

---

## Application Use Cases

### 1. `AddTaskUseCase`
- **File Path:** [AddTaskUseCase.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Application/UseCases/Tasks/AddTaskUseCase.swift)
- **Responsibility:** Creates and schedules tasks.
- **Business Rules:**
  - Validates that the task title is not empty.
  - Enforces that tasks can only be scheduled for **today** or **tomorrow**.
  - Verifies that target categories exist and are not archived.
  - Triggers `ResolveDayStatusUseCase` to update completion histories.

### 2. `CompleteTaskUseCase`
- **File Path:** [CompleteTaskUseCase.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Application/UseCases/Tasks/CompleteTaskUseCase.swift)
- **Responsibility:** Toggles task completion states.
- **Rules & Logic:**
  - Enforces that future tasks (scheduled for tomorrow) cannot be completed early.
  - Sets completion flags and timestamps.
  - Recalculates both the category day entry and the overall master status.

---

## Presentation Layer (UI)

### 1. `TaskViewModel`
- **File Path:** [TaskViewModel.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Presentation/Tasks/TaskViewModel.swift)
- **Responsibility:** Drives task list screens. Fetches scheduled tasks, filters active categories, adds tasks, and manages deletions.
- **Key Methods:**
  - `load(for:)`: Fetches tasks for a date, sorting incomplete items to the top.
  - `addTask(title:categoryId:for:)`: Instantiates use cases and triggers widget refreshes.
  - `toggle(taskId:for:)`: Toggles task completion states.

### 2. `TaskListView`
- **File Path:** [TaskListView.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Presentation/Tasks/TaskListView.swift)
- **Responsibility:** Renders the main task planner view.
- **Key Components:**
  - **Date Toggle:** Switches views between today and tomorrow.
  - **List View:** Shows daily tasks, grouped by category dots. Supports swipe-to-delete.
  - **Quick Add Bar:** Adds new tasks with inline category pickers.
