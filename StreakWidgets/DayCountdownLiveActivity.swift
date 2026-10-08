// StreakWidgets/DayCountdownLiveActivity.swift
// Lock Screen + Dynamic Island countdown to the end of the active day.

import ActivityKit
import SwiftUI
import WidgetKit

struct DayCountdownLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DayCountdownAttributes.self) { context in
            DayCountdownLockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(WColor.background)
                .activitySystemActionForegroundColor(WColor.textPrimary)
                .widgetURL(URL(string: "streak://home"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TASKS")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Text("\(context.state.completed)/\(context.state.total)")
                            .font(.system(.title2, design: .rounded).weight(.heavy))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("DAY ENDS IN")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.secondary)
                        countdown(to: context.attributes.deadline, isDone: context.state.isDone)
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    DayProgressBar(completed: context.state.completed, total: context.state.total, tint: WColor.green)
                        .frame(height: 8)
                }
            } compactLeading: {
                Text("\(context.state.completed)/\(context.state.total)")
                    .font(.system(.caption, design: .rounded).weight(.heavy))
            } compactTrailing: {
                // Fixed width: timer text otherwise reserves too much room and truncates.
                countdown(to: context.attributes.deadline, isDone: context.state.isDone)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .frame(width: 62, alignment: .trailing)
            } minimal: {
                Text("\(context.state.total - context.state.completed)")
                    .font(.system(.caption, design: .rounded).weight(.heavy))
            }
            .widgetURL(URL(string: "streak://home"))
        }
    }
}

@ViewBuilder
private func countdown(to deadline: Date, isDone: Bool) -> some View {
    if isDone {
        Text("DONE ✅")
    } else {
        Text(timerInterval: Date()...max(deadline, Date()), countsDown: true)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
    }
}

private struct DayCountdownLockScreenView: View {
    let attributes: DayCountdownAttributes
    let state: DayCountdownAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.isDone ? "DAY COMPLETE" : "TODAY'S TASKS")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(WColor.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(state.completed)")
                            .font(.system(.title, design: .rounded).weight(.heavy))
                        Text("/ \(state.total) done")
                            .font(.system(.subheadline).weight(.semibold))
                            .foregroundStyle(WColor.textSecondary)
                    }
                    .foregroundStyle(WColor.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("🔥 \(state.streak)")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(WColor.textPrimary)
                    countdown(to: attributes.deadline, isDone: state.isDone)
                        .font(.system(.title3, design: .monospaced).weight(.bold))
                        .foregroundStyle(state.isDone ? WColor.green : WColor.red)
                }
            }
            DayProgressBar(completed: state.completed, total: state.total, tint: state.isDone ? WColor.green : WColor.border)
                .frame(height: 10)
        }
        .padding(16)
    }
}

private struct DayProgressBar: View {
    let completed: Int
    let total: Int
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            let fraction = total > 0 ? CGFloat(completed) / CGFloat(total) : 0
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3).fill(WColor.blank)
                RoundedRectangle(cornerRadius: 3).fill(tint).frame(width: geo.size.width * fraction)
            }
        }
    }
}
