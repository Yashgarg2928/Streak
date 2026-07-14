# Persistence & Data Sharing

Streak uses a local persistence layer built on Apple's **SwiftData** framework, mapped from pure Domain entities. For widget updates, it uses **App Groups** to write a shared payload to standard `UserDefaults`.

---

## SwiftData Initialization

### `ModelContainerFactory`
- **File Path:** [ModelContainerFactory.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Infrastructure/Persistence/ModelContainerFactory.swift)
- **Type:** `enum` namespace
- **Responsibility:** Configures and registers persistence classes inside a single `ModelContainer`.
- **Key Methods:**
  - `makeContainer(inMemory:)`: Generates configurations. Leverages `isStoredInMemoryOnly` when `inMemory` is true for preview environments or unit testing contexts.

---

## DB Persistence Models

Persistent `@Model` representations mirror Domain layer structs. Located in [SwiftDataModels.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Infrastructure/Persistence/SwiftDataModels.swift):

| Model Name | Field Definitions & Types | Domain Mapper |
| :--- | :--- | :--- |
| `CategoryModel` | `id: UUID`, `name: String`, `colorHex: String`, `sortOrder: Int`, `isArchived: Bool`, `createdAt: Date` | `toDomain()` -> [Category](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Entities/Category.swift) |
| `TaskModel` | `id: UUID`, `title: String`, `categoryId: UUID?`, `targetDate: Date`, `isCompleted: Bool`, `completedAt: Date?`, `createdAt: Date` | `toDomain()` -> [Task](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Entities/Task.swift) |
| `DayEntryModel` | `id: UUID`, `date: Date`, `categoryId: UUID?`, `statusRaw: String`, `taskCount: Int`, `completedCount: Int`, `lastUpdated: Date` | `toDomain()` -> [DayEntry](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Entities/DayEntry.swift) |
| `GoalModel` | `id: UUID`, `title: String`, `goalTypeRaw: String`, `categoryId: UUID?`, `targetValue: Double`, `currentValue: Double`, `unit: String`, `startDate: Date`, `targetDate: Date?`, `isCompleted: Bool`, `dailyNotificationTime: Date?`, `createdAt: Date` | `toDomain()` -> [Goal](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Entities/Goal.swift) |
| `GoalProgressEntryModel` | `id: UUID`, `goalId: UUID`, `date: Date`, `value: Double`, `note: String?`, `createdAt: Date` | `toDomain()` -> [GoalProgressEntry](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Entities/GoalProgressEntry.swift) |
| `ReflectionEntryModel` | `id: UUID`, `date: Date`, `accomplishments: String`, `missedItems: String`, `tomorrowPriorities: String`, `goalNotes: String`, `consistencyRating: Int`, `createdAt: Date`, `updatedAt: Date` | `toDomain()` -> [ReflectionEntry](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Entities/ReflectionEntry.swift) |

---

## Repositories Implementation

Concrete repository classes implement Domain repository interfaces. Located in [SwiftDataRepositories.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Infrastructure/Persistence/SwiftDataRepositories.swift):

### 1. `SwiftDataCategoryRepository`
- Implements [CategoryRepository](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Repositories/CategoryRepository.swift).
- Uses `#Predicate` macros to filter non-archived models. Matches IDs, handles updates, deletes, archives, and computes `maxSortOrder()`.

### 2. `SwiftDataTaskRepository`
- Implements [TaskRepository](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Repositories/TaskRepository.swift).
- Fetches tasks for a specific date, handles filtering by `categoryId` for categorization checks, inserts new tasks, and deletes items.

### 3. `SwiftDataDayEntryRepository`
- Implements [DayEntryRepository](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Repositories/DayEntryRepository.swift).
- Retrieves cache entries matching specific dates and categories. Operates upsert methods (`save(_:)`) that either update existing records or insert new models.

### 4. `SwiftDataGoalRepository`
- Implements [GoalRepository](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Repositories/GoalRepository.swift).
- Manages long-term goals and progress log history (`GoalProgressEntry`). Logs progress values using upsert filters matching both the goal UUID and targeted dates.

### 5. `SwiftDataReflectionRepository`
- Implements [ReflectionRepository](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Domain/Repositories/ReflectionRepository.swift).
- Fetches and stores daily reflection journal entries (`ReflectionEntryModel`) sorted chronologically.

---

## Widget Data Sync (App Group)

### `WidgetData` & `WidgetDataStore`
- **File Path:** [WidgetDataStore.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Infrastructure/WidgetDataStore.swift)
- **Type:** `struct` and `enum` helper
- **Responsibility:** Packages category names, streaks, active tasks, and status maps into a serializable payload, writing it to the shared App Group.
- **Shared App Group Identifier:** `"group.com.madhvan.streak"`
- **Key Methods:**
  - `save(_:)`: Encodes `WidgetData` using `JSONEncoder` and commits it to the shared `UserDefaults(suiteName:)` path under the key `"widgetData"`.
  - `load()`: Decodes the shared data to render widgets.
- **Data Structs:**
  - `WidgetData.CategoryWidgetData`: Snapshot of a category containing its color, streak count, and daily status history.
  - `WidgetData.TaskItem`: Lightweight representation of today's tasks (title, status, and category color) for widget lists.
