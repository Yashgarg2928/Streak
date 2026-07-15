// StreakWidgets/GoalWidget.swift
// Displays a selected goal's progress bar and metrics inside a medium-sized Widget.

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Goal App Entity

struct GoalAppEntity: AppEntity {
    let id: String          // UUID string
    let title: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Goal"
    static var defaultQuery = GoalEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct GoalEntityQuery: EntityQuery {
    static var cache: [GoalAppEntity] = []

    func entities(for identifiers: [String]) async throws -> [GoalAppEntity] {
        let all = allEntities()
        if !all.isEmpty {
            Self.cache = all
        }
        let resolvedAll = all.isEmpty ? Self.cache : all
        
        guard !identifiers.isEmpty else { return resolvedAll }
        let lowercasedIds = identifiers.map { $0.lowercased() }
        return resolvedAll.filter { lowercasedIds.contains($0.id.lowercased()) }
    }

    func suggestedEntities() async throws -> [GoalAppEntity] {
        let all = allEntities()
        if !all.isEmpty {
            Self.cache = all
        }
        return all
    }

    func defaultResult() async -> GoalAppEntity? {
        let all = allEntities()
        if !all.isEmpty {
            Self.cache = all
        }
        return all.first
    }

    private func allEntities() -> [GoalAppEntity] {
        guard let data = WidgetDataStore.load() else { return [] }
        return data.goals.map {
            GoalAppEntity(id: $0.id, title: $0.title)
        }
    }
}

// MARK: - Configuration Intent

struct GoalIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Goal"
    static var description = IntentDescription("Choose which goal to display.")

    @Parameter(title: "Goal")
    var goal: GoalAppEntity?
}

// MARK: - Entry

struct GoalEntry: TimelineEntry {
    let date: Date
    let title: String
    let colorHex: String
    let currentValue: Double
    let targetValue: Double
    let unit: String
    let progressFraction: Double
    let isCompleted: Bool
    let targetDate: Date?
    let isEmptyState: Bool
}

// MARK: - Provider

struct GoalProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> GoalEntry {
        GoalEntry(
            date: Date(),
            title: "Gym Streak",
            colorHex: "#2D7A2D",
            currentValue: 67,
            targetValue: 90,
            unit: "days",
            progressFraction: 0.74,
            isCompleted: false,
            targetDate: Date().addingTimeInterval(3600 * 24 * 30),
            isEmptyState: false
        )
    }

    func snapshot(for config: GoalIntent, in context: Context) async -> GoalEntry {
        entry(for: config)
    }

    func timeline(for config: GoalIntent, in context: Context) async -> Timeline<GoalEntry> {
        let e = entry(for: config)
        let midnight = Calendar.current.startOfDay(for: Date())
        let nextUpdate = Calendar.current.date(byAdding: .day, value: 1, to: midnight) ?? Date().addingTimeInterval(3600 * 24)
        return Timeline(entries: [e], policy: .after(nextUpdate))
    }

    private func entry(for config: GoalIntent) -> GoalEntry {
        guard let data = WidgetDataStore.load(), !data.goals.isEmpty else {
            return GoalEntry(
                date: Date(), title: "", colorHex: "#1A1A1A",
                currentValue: 0, targetValue: 1, unit: "",
                progressFraction: 0, isCompleted: false, targetDate: nil,
                isEmptyState: true
            )
        }

        // Find the user-configured goal, or default to the first active goal
        let selectedGoal: WidgetData.GoalWidgetData?
        if let configGoalId = config.goal?.id {
            selectedGoal = data.goals.first { $0.id.lowercased() == configGoalId.lowercased() }
        } else {
            selectedGoal = data.goals.first { !$0.isCompleted } ?? data.goals.first
        }

        guard let goal = selectedGoal else {
            return GoalEntry(
                date: Date(), title: "", colorHex: "#1A1A1A",
                currentValue: 0, targetValue: 1, unit: "",
                progressFraction: 0, isCompleted: false, targetDate: nil,
                isEmptyState: true
            )
        }

        return GoalEntry(
            date: Date(),
            title: goal.title,
            colorHex: goal.categoryColorHex ?? "#1A1A1A",
            currentValue: goal.currentValue,
            targetValue: goal.targetValue,
            unit: goal.unit,
            progressFraction: goal.progressFraction,
            isCompleted: goal.isCompleted,
            targetDate: goal.targetDate,
            isEmptyState: false
        )
    }
}

// MARK: - Medium View

struct GoalWidgetMedium: View {
    let entry: GoalEntry

    var body: some View {
        if entry.isEmptyState {
            VStack {
                Text("NO GOALS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(WColor.textSecondary)
                Text("Open the app to create a new goal.")
                    .font(.system(size: 11))
                    .foregroundStyle(WColor.textDisabled)
                    .multilineTextAlignment(.center)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(WColor.background)
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(WColor.border, lineWidth: 2).padding(1))
        } else {
            let color = Color(hex: entry.colorHex)
            
            VStack(alignment: .leading, spacing: 10) {
                // Header Title + Category Dot
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    
                    Text(entry.title.uppercased())
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(WColor.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if entry.isCompleted {
                        Text("COMPLETED")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(WColor.green)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                }
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(WColor.blank)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(color)
                                .frame(width: geo.size.width * CGFloat(max(0, min(entry.progressFraction, 1.0))))
                        }
                    }
                    .frame(height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(WColor.border, lineWidth: 1.5)
                    )
                    
                    Text("\(formatValue(entry.currentValue)) / \(formatValue(entry.targetValue)) \(entry.unit)")
                        .font(.system(size: 9, design: .monospaced).weight(.bold))
                        .foregroundStyle(WColor.textSecondary)
                }
                
                Spacer().frame(height: 0)
                
                // Footer completed fraction + target date
                HStack {
                    Text("\(Int(entry.progressFraction * 100))% completed")
                        .font(.system(size: 9, design: .monospaced).weight(.bold))
                        .foregroundStyle(WColor.textPrimary)
                    
                    Spacer()
                    
                    if let targetDate = entry.targetDate {
                        Text("Deadline: \(formatDate(targetDate))")
                            .font(.system(size: 9))
                            .foregroundStyle(WColor.textSecondary)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(WColor.background)
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(color, lineWidth: 2).padding(1))
        }
    }

    private func formatValue(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", val)
        } else {
            return String(format: "%.1f", val)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Widget Definition

struct GoalWidget: Widget {
    let kind = "GoalWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: GoalIntent.self,
            provider: GoalProvider()
        ) { entry in
            GoalWidgetMedium(entry: entry)
                .containerBackground(WColor.background, for: .widget)
        }
        .configurationDisplayName("Goal Progress")
        .description("Track the completion metrics of a selected goal.")
        .supportedFamilies([.systemMedium]) // systemMedium size only!
    }
}
