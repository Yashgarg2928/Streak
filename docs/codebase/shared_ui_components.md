# Shared UI & Design System

This module outlines the visual styling foundation of the application, mapping Neo-Brutalist design specifications into code tokens and reusable custom SwiftUI views.

---

## Design Tokens

### `AppColor` & `AppLayout`
- **File Path:** [DesignTokens.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Presentation/SharedComponents/DesignTokens.swift)
- **Type:** `enum` namespaces
- **Responsibility:** Serves as the single source of truth for design tokens. Custom Color and Category helper extensions are located here.
- **Color Palettes:**
  - `background` (`#F5F0E8`): Warm paper background.
  - `surface` (`#EFEFDF`): Standard card/control filler.
  - `border` & `textPrimary` (`#1A1A1A`): Primary line outlines and dark text.
  - `textSecondary` (`#4A4A4A`), `textDisabled` (`#9A9A9A`).
  - `green` (`#2D7A2D`): Completion color.
  - `red` (`#C0392B`): Break/missed day color.
  - `blank` (`#D0C9B8`): Empty future cells.
- **Layout System:**
  - `borderWidth` (`2.5pt`): Thick black borders.
  - `cornerRadius` (`6pt`): Subtle rounding.
  - `minTapTarget` (`44pt`): Safe interaction boundaries.
  - `heatmapCell` (`12pt`) & `heatmapGap` (`3pt`): Sizing grids.

---

## Reusable Components

Located in [SharedComponents.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Presentation/SharedComponents/SharedComponents.swift):

### 1. `BrutalistCard`
- **Responsibility:** Visual wrapper featuring solid borders, neutral paper background, and zero shadows. Used for categories, heatmaps, and tasks. Supports category-specific border highlights.
- **API:** `init(borderColor: Color = AppColor.border, content: () -> Content)`

### 2. `CategoryDot`
- **Responsibility:** A `10pt` diameter indicator dot. Categorized tasks display their category identity; uncategorized items display neutral gray (`AppColor.neutralDot`).
- **API:** `init(color: Color = AppColor.neutralDot)`

### 3. `StreakBadgeView`
- **Responsibility:** A bold label with a flame icon highlighting daily streaks. Rendered with custom borders matching category colors.
- **API:** `init(count: Int, color: Color = AppColor.border)`

### 4. `ProgressBarView`
- **Responsibility:** Static progress meters used to visualize goals. Designed with standard borders, custom filling offsets, and monospace percentage labels.
- **API:** `init(fraction: Double, label: String, fillColor: Color = AppColor.border)`

### 5. `TaskRowView`
- **Responsibility:** The interactive checklist row. Shows completion status via checkbox checkmarks, category colors, and title text. Handles strikethroughs and touch overrides.
- **API:** `init(task: Task, categoryColor: Color?, onToggle: () -> Void)`

### 6. `BrutalistButton`
- **Responsibility:** Call-to-action button containing bold text, solid border lines, and standard tap feedback.
- **API:** `init(title: String, borderColor: Color = AppColor.border, action: () -> Void)`

---

## Heatmap Consistency Grid

### `ConsistencyGridView`
- **File Path:** [ConsistencyGridView.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Presentation/SharedComponents/ConsistencyGridView.swift)
- **Type:** `View struct`
- **Responsibility:** Draws a multi-month grid visualizing daily habit performance. Designed for local rendering without layout lag.
- **Internal State & Setup:**
  - Converts date dictionaries using `DateFormatter` key mappings formatted as `"yyyy-MM-dd"` (ensures safe key matching free from timezone variations).
  - Uses `TabView` with page-indicator styles disabled to group grids side-by-side (2 months per page, total 6 pages of horizontal paging).
- **Core Layout Methods:**
  - `monthColumn(for:)`: Resolves the first weekday column index, calculates monthly day counts, and draws cells aligned with column grids.
  - `fillColor(for:date:)`: Evaluates the cell state: green if completed, red if missed or empty, or transparent if in the future.
  - `a11yLabel(status:date:)`: Standard accessibility descriptions for screen readers (e.g. *"July 8, completed"*).
