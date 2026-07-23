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
                .font(.system(size: 16))
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

    private var isFuture: Bool {
        let activeToday = env.settingsRepository.isOnboardingCompleted
            ? ActiveDayResolver.resolveActiveDate(for: Date(), settings: env.settingsRepository)
            : Calendar.current.startOfDay(for: Date())
        return Calendar.current.startOfDay(for: task.targetDate) > Calendar.current.startOfDay(for: activeToday)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Button(action: { if !isFuture { onToggle() } }) {
                    HStack(spacing: 10) {
                        // Checkbox — greyed out for future tasks
                        Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                            .font(.system(size: 22, weight: .medium))
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
                                        .font(.system(size: 9, weight: .bold))
                                    Text("LOCKED")
                                        .font(.system(size: 9, weight: .black))
                                }
                                .foregroundStyle(AppColor.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(AppColor.blank)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }

                        Spacer(minLength: 4)
                    }
                    .frame(minHeight: AppLayout.minTapTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            // Promotion pills: [⚡ TODAY] [📅 TOMORROW] — only shown for backlog/weekly/monthly tasks
            if !task.isCompleted && (onScheduleToday != nil || onScheduleTomorrow != nil) {
                HStack(spacing: 8) {
                    if let onScheduleToday {
                        Button(action: onScheduleToday) {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 9, weight: .black))
                                Text("ADD TO TODAY")
                                    .font(.system(size: 9, weight: .black))
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
                                    .font(.system(size: 9, weight: .bold))
                                Text("ADD TO TOMORROW")
                                    .font(.system(size: 9, weight: .black))
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
                    .font(.system(size: 14))
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
