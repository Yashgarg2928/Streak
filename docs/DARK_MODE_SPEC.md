# Dark Mode & Theme System Specification

## 1. Overview
The Streak iOS App implements a dynamic **Light & Dark Neo-Brutalist Theme System**. Designed to preserve high contrast, crisp typography, and bold geometry across all lighting environments, the system seamlessly transitions between Light Neo-Brutalism and Dark Neo-Brutalism while adhering to strict accessibility contrast standards.

---

## 2. Color Palette & Token System

All color tokens are centrally managed in `DesignTokens.swift` (App target) and `WidgetShared.swift` (Widget Extension target) using dynamic `UIKit` `UIColor` trait collection observers.

| Semantic Token | Light Mode (Hex) | Dark Mode (Hex) | Design Intent & Usage |
|---|---|---|---|
| `AppColor.background` | `#F5F0E8` (Vanilla Paper) | `#121212` (Dark Obsidian) | Main app background canvas |
| `AppColor.surface` | `#EFEFDF` (Muted Sand) | `#1E1E1E` (Charcoal Surface) | Card containers, interactive inputs, navigation bars |
| `AppColor.border` | `#1A1A1A` (Ink Black) | `#F5F0E8` (Vanilla Cream) | Bold Neo-Brutalist 2.5pt stroke borders |
| `AppColor.textPrimary` | `#1A1A1A` (Ink Black) | `#F5F0E8` (Vanilla Cream) | Main headings, task titles, high-emphasis text |
| `AppColor.textSecondary` | `#4A4A4A` (Charcoal) | `#A0A0A0` (Muted Silver) | Subtitles, helper text, empty state descriptions |
| `AppColor.textDisabled` | `#9A9A9A` (Muted Slate) | `#666666` (Dark Slate) | Strikethrough completed items, disabled state |
| `AppColor.green` | `#2D7A2D` (Forest Green) | `#34C759` (Vivid Neon Green) | Complete status days, completed checkboxes |
| `AppColor.red` | `#C0392B` (Crimson Red) | `#FF3B30` (Vivid Crimson Red) | Incomplete status days, danger zone actions |
| `AppColor.blank` | `#D0C9B8` (Empty Sand) | `#2C2C2E` (Dark Grey Blank) | Future days in heatmaps, empty slots |
| `AppColor.neutralDot` | `#8A8A8A` (Slate Dot) | `#999999` (Light Slate Dot) | Uncategorized task dots |

---

## 3. Theme Selection Preferences

Users can select their appearance preference in **Settings -> Appearance Theme**:
1. **System (`"system"`):** Automatically adapts to the iOS device's Dark/Light mode setting (Default).
2. **Light (`"light"`):** Forces Light Neo-Brutalist theme regardless of system settings.
3. **Dark (`"dark"`):** Forces Dark Neo-Brutalist theme regardless of system settings.

The theme selection is stored in `SettingsRepository.themeMode` and applied at app startup via `.preferredColorScheme(themeColorScheme)` in `StreakApp.swift`.

---

## 4. Widget Extension Compatibility

Widgets dynamically render in Dark Mode using matching dynamic color definitions in `WColor` (`WidgetShared.swift`), ensuring that iOS Home Screen widgets adapt seamlessly to system dark mode and iOS Tinted/Accented icon modes.
