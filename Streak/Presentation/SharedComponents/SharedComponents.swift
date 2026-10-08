// Presentation/SharedComponents/SharedComponents.swift
// Reusable Neo-Brutalist UI components used across all screens.

import SwiftUI

// MARK: - BrutalistCard
// Base container. borderColor defaults to AppColor.border.
// Category cards pass their category color.

struct BrutalistCard<Content: View>: View {
    var borderColor: Color = AppColor.border
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(AppLayout.cardPadding)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(borderColor, lineWidth: AppLayout.borderWidth)
            )
    }
}

// MARK: - CategoryDot
// 10pt filled circle in the category's color (or neutral gray for uncategorized).

struct CategoryDot: View {
    var color: Color = AppColor.neutralDot

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: AppLayout.dotSize, height: AppLayout.dotSize)
            .accessibilityHidden(true)
    }
}

// MARK: - StreakBadgeView

struct StreakBadgeView: View {
    let count: Int
    var color: Color = AppColor.border

    var body: some View {
        HStack(spacing: 4) {
            Text("🔥")
                .font(.app(size: 16))
            Text("\(count)")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(AppColor.textPrimary)
            Text(count == 1 ? "day" : "days")
                .font(.system(.subheadline).weight(.medium))
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(color, lineWidth: AppLayout.borderWidth)
        )
    }
}

// MARK: - ProgressBarView

struct ProgressBarView: View {
    let fraction: Double    // 0.0 – 1.0
    let label: String
    var fillColor: Color = AppColor.border

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColor.blank)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(fillColor)
                        .frame(width: geo.size.width * max(0, min(fraction, 1)))
                }
            }
            .frame(height: 18)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
            )

            Text(label)
                .font(.system(.caption, design: .monospaced).weight(.medium))
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}

// MARK: - TaskRowView

struct TaskRowView: View {
    @Environment(AppEnvironment.self) private var env
    let task: Task
    let categoryColor: Color?
    let onToggle: () -> Void
    var onScheduleToday: (() -> Void)? = nil
    var onScheduleTomorrow: (() -> Void)? = nil
    var onMoveToTimeframe: ((TaskTimeframe) -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onMoveToBacklog: (() -> Void)? = nil
    var isReordering: Bool = false
    var onMoveUp: (() -> Void)? = nil
    var onMoveDown: (() -> Void)? = nil
    var onMoveToTop: (() -> Void)? = nil
    var onMoveToBottom: (() -> Void)? = nil

    private var isFuture: Bool {
        let activeToday = env.settingsRepository.isOnboardingCompleted
            ? ActiveDayResolver.resolveActiveDate(for: Date(), settings: env.settingsRepository)
            : Calendar.current.startOfDay(for: Date())
        return Calendar.current.startOfDay(for: task.targetDate) > Calendar.current.startOfDay(for: activeToday)
    }

    private var isPast: Bool {
        let activeToday = env.settingsRepository.isOnboardingCompleted
            ? ActiveDayResolver.resolveActiveDate(for: Date(), settings: env.settingsRepository)
            : Calendar.current.startOfDay(for: Date())
        return Calendar.current.startOfDay(for: task.targetDate) < Calendar.current.startOfDay(for: activeToday)
    }

    private var isLateTask: Bool {
        guard task.timeframe == .daily else { return false }
        let planningDeadline = ActiveDayResolver.planningDeadline(for: task.targetDate, settings: env.settingsRepository)
        return task.isAddedLate(planningDeadline: planningDeadline)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Button {
                    if !isFuture { onToggle() }
                } label: {
                    HStack(spacing: 10) {
                        // Checkbox — greyed out for future tasks
                        Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                            .font(.app(size: 22, weight: .medium))
                            .foregroundStyle(
                                isFuture ? AppColor.textDisabled :
                                task.isCompleted ? AppColor.green : AppColor.textSecondary
                            )
                            .frame(width: 28, height: 28)

                        // Category dot
                        CategoryDot(color: categoryColor ?? AppColor.neutralDot)

                        // Task title
                        HStack(spacing: 6) {
                            Text(task.title)
                                .font(.system(.body).weight(.medium))
                                .foregroundStyle(
                                    isFuture ? AppColor.textSecondary : AppColor.textPrimary
                                )
                                .strikethrough(task.isCompleted, color: AppColor.textDisabled)
                                .lineLimit(nil)
                                .multilineTextAlignment(.leading)
                            
                            if task.isLocked {
                                HStack(spacing: 3) {
                                    Image(systemName: "lock.fill")
                                        .font(.app(size: 9, weight: .bold))
                                    Text("LOCKED")
                                        .font(.app(size: 9, weight: .black))
                                }
                                .foregroundStyle(AppColor.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(AppColor.blank)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }

                            if isLateTask {
                                HStack(spacing: 3) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.app(size: 9, weight: .bold))
                                    Text("BONUS")
                                        .font(.app(size: 9, weight: .black))
                                }
                                .foregroundStyle(AppColor.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(AppColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.orange, lineWidth: 1))
                                .accessibilityLabel("Added after the planning cutoff. Bonus task, doesn't affect today's status.")
                            }

                            if isPast && !task.isCompleted && task.timeframe == .daily && task.routineId == nil && !task.isLocked {
                                HStack(spacing: 3) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.app(size: 9, weight: .bold))
                                    Text("MISSED")
                                        .font(.app(size: 9, weight: .black))
                                }
                                .foregroundStyle(AppColor.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(AppColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.orange, lineWidth: 1))
                            }
                        }

                        Spacer(minLength: 4)
                    }
                    .frame(minHeight: AppLayout.minTapTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isReordering {
                    HStack(spacing: 4) {
                        if let onMoveUp {
                            Button(action: onMoveUp) {
                                Image(systemName: "chevron.up")
                                    .font(.app(size: 11, weight: .bold))
                                    .foregroundStyle(AppColor.textPrimary)
                                    .frame(width: 28, height: 28)
                                    .background(AppColor.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(AppColor.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Move task up")
                        }

                        if let onMoveDown {
                            Button(action: onMoveDown) {
                                Image(systemName: "chevron.down")
                                    .font(.app(size: 11, weight: .bold))
                                    .foregroundStyle(AppColor.textPrimary)
                                    .frame(width: 28, height: 28)
                                    .background(AppColor.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(AppColor.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Move task down")
                        }
                    }
                }

                if let onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.app(size: 14, weight: .bold))
                            .foregroundStyle(AppColor.red)
                            .frame(width: 28, height: 28)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(AppColor.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete to-do task")
                }
            }

            // Action pills: [⚡ ADD TO TODAY] [📅 ADD TO TOMORROW] [📋 MOVE TO TO-DO]
            if !task.isCompleted && (onScheduleToday != nil || onScheduleTomorrow != nil || onMoveToBacklog != nil) {
                HStack(spacing: 8) {
                    if let onScheduleToday {
                        Button(action: onScheduleToday) {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.app(size: 9, weight: .black))
                                Text("ADD TO TODAY")
                                    .font(.app(size: 9, weight: .black))
                            }
                            .foregroundStyle(AppColor.background)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(AppColor.border)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                    }

                    if let onScheduleTomorrow {
                        Button(action: onScheduleTomorrow) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.app(size: 9, weight: .bold))
                                Text("ADD TO TOMORROW")
                                    .font(.app(size: 9, weight: .black))
                            }
                            .foregroundStyle(AppColor.textPrimary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(AppColor.border, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if let onMoveToBacklog {
                        Button(action: onMoveToBacklog) {
                            HStack(spacing: 4) {
                                Image(systemName: "tray.and.arrow.down")
                                    .font(.app(size: 9, weight: .bold))
                                Text("MOVE TO TO-DO")
                                    .font(.app(size: 9, weight: .black))
                            }
                            .foregroundStyle(AppColor.textPrimary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(AppColor.border, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 38) // align with task title
            }
        }
        .contextMenu {
            if onMoveToTop != nil || onMoveUp != nil || onMoveDown != nil || onMoveToBottom != nil {
                Section("Reorder") {
                    if let onMoveToTop {
                        Button(action: onMoveToTop) {
                            Label("Move to Top", systemImage: "arrow.up.to.line")
                        }
                    }
                    if let onMoveUp {
                        Button(action: onMoveUp) {
                            Label("Move Up", systemImage: "arrow.up")
                        }
                    }
                    if let onMoveDown {
                        Button(action: onMoveDown) {
                            Label("Move Down", systemImage: "arrow.down")
                        }
                    }
                    if let onMoveToBottom {
                        Button(action: onMoveToBottom) {
                            Label("Move to Bottom", systemImage: "arrow.down.to.line")
                        }
                    }
                }
            }
            if let onScheduleToday {
                Button(action: onScheduleToday) {
                    Label("Add to Today", systemImage: "bolt.fill")
                }
            }
            if let onScheduleTomorrow {
                Button(action: onScheduleTomorrow) {
                    Label("Add to Tomorrow", systemImage: "calendar")
                }
            }
            if let onMoveToBacklog {
                Button(action: onMoveToBacklog) {
                    Label("Move to To-Do List", systemImage: "tray.and.arrow.down")
                }
            }
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - EmptyStateView

struct EmptyStateView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(.body))
            .foregroundStyle(AppColor.textDisabled)
            .multilineTextAlignment(.center)
            .padding()
    }
}

// MARK: - BrutalistButton

struct BrutalistButton: View {
    let title: String
    var borderColor: Color = AppColor.border
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.body).weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: AppLayout.minTapTarget)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(borderColor, lineWidth: AppLayout.borderWidth)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ActiveDayCountdownView
// Real-time countdown timer to the active day's rollover deadline.

struct ActiveDayCountdownView: View {
    let settings: any SettingsRepository

    var body: some View {
        TimelineView(.animation(minimumInterval: 1)) { context in
            let now = context.date
            let activeDate = ActiveDayResolver.resolveActiveDate(for: now, settings: settings)
            let deadline = ActiveDayResolver.activeDayDeadline(for: activeDate, settings: settings)
            let timeRemaining = max(0, deadline.timeIntervalSince(now))
            
            let hours = Int(timeRemaining) / 3600
            let minutes = (Int(timeRemaining) % 3600) / 60
            let seconds = Int(timeRemaining) % 60
            
            let timeString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            
            HStack(spacing: 8) {
                Text("⏳")
                    .font(.app(size: 14))
                Text("DAY ENDS IN:")
                    .font(.system(.caption, design: .monospaced).weight(.black))
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Text(timeString)
                    .font(.system(.body, design: .monospaced).weight(.black))
                    .foregroundStyle(AppColor.textPrimary)
            }
            .padding(.horizontal, AppLayout.cardPadding)
            .padding(.vertical, 10)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
            )
        }
    }
}

// MARK: - WeekdayPicker
// Row of day chips. Values are Calendar weekdays (1 = Sunday … 7 = Saturday),
// ordered from the user's first weekday.

struct WeekdayPicker: View {
    @Binding var selection: Set<Int>
    var accent: Color = AppColor.border
    var selectedTextColor: Color = AppColor.background

    static var orderedWeekdays: [Int] {
        let first = Calendar.current.firstWeekday
        return (0..<7).map { (first - 1 + $0) % 7 + 1 }
    }

    /// "EVERY DAY", or e.g. "MON · WED · FRI".
    static func summary(_ weekdays: Set<Int>) -> String {
        guard !weekdays.isEmpty, weekdays.count < 7 else { return "EVERY DAY" }
        let symbols = Calendar.current.shortStandaloneWeekdaySymbols
        return orderedWeekdays
            .filter { weekdays.contains($0) }
            .map { symbols[$0 - 1].uppercased() }
            .joined(separator: " · ")
    }

    var body: some View {
        let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
        HStack(spacing: 6) {
            ForEach(Self.orderedWeekdays, id: \.self) { weekday in
                let isOn = selection.contains(weekday)
                Button {
                    if isOn { selection.remove(weekday) } else { selection.insert(weekday) }
                } label: {
                    Text(symbols[weekday - 1])
                        .font(.system(.subheadline, design: .monospaced).weight(.black))
                        .foregroundStyle(isOn ? selectedTextColor : AppColor.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: AppLayout.minTapTarget)
                        .background(isOn ? accent : AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                                .stroke(AppColor.border, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Calendar.current.standaloneWeekdaySymbols[weekday - 1])
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
    }
}

// MARK: - ShortcutGuideCard
// Numbered step-by-step card used by the Shortcuts / automation setup guides.

struct ShortcutGuideCard: View {
    let stepNumber: String
    let badge: String
    let badgeColor: String
    let title: String
    let description: String
    let steps: [String]
    var stepLabel: String = "STEP"

    var body: some View {
        BrutalistCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text(badge)
                        .font(.app(size: 9, weight: .black, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(hex: badgeColor))
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Spacer()

                    Text("\(stepLabel) \(stepNumber)")
                        .font(.app(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(AppColor.textSecondary)
                }

                Text(title)
                    .font(.app(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppColor.textPrimary)

                Text(description)
                    .font(.app(size: 13, weight: .medium))
                    .foregroundStyle(AppColor.textSecondary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.app(size: 12, weight: .black, design: .monospaced))
                                .foregroundStyle(AppColor.textPrimary)
                            Text(.init(step))
                                .font(.app(size: 12, weight: .medium))
                                .foregroundStyle(AppColor.textPrimary)
                        }
                    }
                }
                .padding(10)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
            }
        }
    }
}

// MARK: - HabitHistoryStrip
// Small squares for a habit's recent days: done (green), missed (red), today pending
// (outlined), unscheduled / rest / frozen (faint).

struct HabitHistoryStrip: View {
    let days: [HabitDay]
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 3) {
            ForEach(days, id: \.date) { day in
                RoundedRectangle(cornerRadius: 2)
                    .fill(fill(for: day.state))
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(day.state == .pending ? AppColor.border : .clear, lineWidth: 1.5)
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Last \(days.count) days: \(days.filter { $0.state == .done }.count) done, \(days.filter { $0.state == .missed }.count) missed")
    }

    private func fill(for state: HabitDay.State) -> Color {
        switch state {
        case .done:    return AppColor.green
        case .missed:  return AppColor.red
        case .pending: return AppColor.surface
        case .off:     return AppColor.blank.opacity(0.35)
        }
    }
}
