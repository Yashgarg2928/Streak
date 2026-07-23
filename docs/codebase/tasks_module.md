# Tasks & Consistency Module

This module details task creation, multi-timeframe planning (Daily, Weekly, Monthly, To-Do List), strict task immutability (no deletion/no editing policy), checkbox completion logic, and day status resolution rules.

---

## Business Rules & Immutability

1. **Strict Task Immutability:** Once created, tasks cannot be edited, rescheduled, or deleted. Attempts to delete or edit present explicit warnings (`⚠️ Tasks cannot be edited or deleted once created`).
2. **Day Status Resolution (`DayStatus.swift`):**
   - **GREEN (`.green`):** Category or master day turns Green when ALL tasks scheduled for that day are completed (`taskCount > 0 && completedCount == taskCount`).
   - **RED (`.red`):** Checked strictly at two times:
     1. When the planning deadline passes and 0 tasks were scheduled (lockout condition).
     2. When the active day has ended and scheduled tasks remain incomplete.
   - **BLANK (`.future`):** Active in-progress days with pending tasks remain Blank (`#D0C9B8` / `#2C2C2E`) until completed or day ends.

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

### 2. `GenerateRoutineTasksUseCase`
- **File Path:** [GenerateRoutineTasksUseCase.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Application/UseCases/Tasks/GenerateRoutineTasksUseCase.swift)
- **Responsibility:** Automatically populates daily tasks for active recurring habit commitments (e.g. Monthly Fixed commitments or Custom Sprints).
- **Rules & Logic:**
  - Evaluates active routines covering the target date.
  - Generates daily `Task` instances with `routineId` and `isLocked` flags.

---

## Presentation Layer (UI)

### 1. `TaskViewModel`
- **File Path:** [TaskViewModel.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Presentation/Tasks/TaskViewModel.swift)
- **Responsibility:** Drives multi-tab task planner screens (`.daily`, `.weekly`, `.monthly`, `.backlog`).
- **Key Methods:**
  - `load(tab:for:)`: Fetches tasks for a specific timeframe/date.
  - `addTask(title:categoryId:timeframe:for:)`: Instantiates use cases and triggers widget refreshes.
  - `toggle(taskId:tab:for:)`: Toggles task completion states.
  - `delete(taskId:tab:for:)`: Blocks task deletion with an explicit warning banner (`⚠️ Tasks cannot be deleted or edited once created`).
  - `scheduleTask(...)`: Blocks task editing/rescheduling.

### 2. `TaskListView`
- **File Path:** [TaskListView.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Presentation/Tasks/TaskListView.swift)
- **Responsibility:** Renders the main task planner view.
- **Key Components:**
  - **4-Segment Main Tab Control:** Switch between `DAILY`, `WEEKLY`, `MONTHLY`, and `TO-DO LIST`.
  - **Date Toggle (Daily Tab):** Switches daily views between Today and Tomorrow.
  - **Progress Header Cards:** Show progress bars and completion percentages for Weekly and Monthly tabs.
  - **Task Row Quick Action Pills:** `[⚡️ TODAY]` and `[🗓️ TOMORROW]` pills and scope move menu to instantly schedule weekly, monthly, or backlog items.
  - **Quick Add Bar:** Adds new tasks with inline category pickers tailored to the active tab's timeframe.

