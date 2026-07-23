# Tasks Module

This module details task creation, multi-timeframe planning (Daily, Weekly, Monthly, To-Do List), soft-deletion, checkbox completion logic, and task list navigation.

---

## Domain Entities

### `Task`
- **File Path:** [Task.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Entities/Task.swift)
- **Responsibility:** A domain model representing a planned task or goal across various timeframes.
- **Properties:**
  - `id`: UUID.
  - `title`: Description of the action (e.g. "Read 20 pages").
  - `categoryId`: Optional category identifier (nil for uncategorized tasks).
  - `targetDate`: Target execution date (normalized to midnight).
  - `timeframe`: Scope enum (`TaskTimeframe`: `.daily`, `.weekly`, `.monthly`, `.backlog`).
  - `isCompleted`: Completion status flag.
  - `completedAt`: Optional timestamp.
  - `createdAt`: Timestamp when created.
  - `isDeleted`: Soft-delete flag (excluded from streak calculations).

---

## Application Use Cases

### 1. `AddTaskUseCase`
- **File Path:** [AddTaskUseCase.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Application/UseCases/Tasks/AddTaskUseCase.swift)
- **Responsibility:** Creates and schedules tasks across daily, weekly, monthly, and backlog timeframes.
- **Business Rules:**
  - Validates that the task title is not empty.
  - For `.daily` tasks, validates that target dates are set to **today** or **tomorrow**.
  - For `.weekly`, `.monthly`, and `.backlog` tasks, date restrictions are relaxed.
  - Verifies that target categories exist and are not archived.
  - Triggers `ResolveDayStatusUseCase` for `.daily` tasks to update completion histories.

### 2. `CompleteTaskUseCase`
- **File Path:** [CompleteTaskUseCase.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Application/UseCases/Tasks/CompleteTaskUseCase.swift)
- **Responsibility:** Toggles task completion states.
- **Rules & Logic:**
  - Enforces that future tasks (scheduled for tomorrow) cannot be completed early.
  - Sets completion flags and timestamps.
  - Recalculates category day entries and overall master status for daily tasks.

---

## Presentation Layer (UI)

### 1. `TaskViewModel`
- **File Path:** [TaskViewModel.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Presentation/Tasks/TaskViewModel.swift)
- **Responsibility:** Drives multi-tab task planner screens (`.daily`, `.weekly`, `.monthly`, `.backlog`).
- **Key Methods:**
  - `load(tab:for:)`: Fetches tasks for a specific timeframe/date, sorting active items first and soft-deleted items to the bottom.
  - `addTask(title:categoryId:timeframe:for:)`: Instantiates use cases and triggers widget refreshes.
  - `toggle(taskId:tab:for:)`: Toggles task completion states.
  - `delete(taskId:tab:for:)`: Soft-deletes active tasks (move to bottom with strike-through and `(Deleted)` badge); second deletion permanently purges.
  - `scheduleTask(taskId:to:timeframe:tab:for:)`: Promotes/schedules tasks (e.g. from Weekly/Monthly/To-Do list to Today/Tomorrow).

### 2. `TaskListView`
- **File Path:** [TaskListView.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Presentation/Tasks/TaskListView.swift)
- **Responsibility:** Renders the main task planner view.
- **Key Components:**
  - **4-Segment Main Tab Control:** Switch between `DAILY`, `WEEKLY`, `MONTHLY`, and `TO-DO LIST`.
  - **Date Toggle (Daily Tab):** Switches daily views between Today and Tomorrow.
  - **Progress Header Cards:** Show progress bars and completion percentages for Weekly and Monthly tabs.
  - **Task Row Quick Action Pills:** `[⚡️ TODAY]` and `[🗓️ TOMORROW]` pills and scope move menu to instantly schedule weekly, monthly, or backlog items.
  - **Quick Add Bar:** Adds new tasks with inline category pickers tailored to the active tab's timeframe.

