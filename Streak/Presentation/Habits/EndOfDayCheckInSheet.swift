// Presentation/Habits/EndOfDayCheckInSheet.swift
// One end-of-day flow: mark each habit commitment followed / not followed (kept in sync
// with its task in the Today list) and write a short reflection for the day.

import SwiftUI

struct EndOfDayCheckInSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let date: Date
    @State private var routines: [HabitRoutine] = []
    @State private var routineTasks: [UUID: Task] = [:]
    @State private var savedStatuses: [UUID: HabitCheckStatus] = [:]
    @State private var habitStatuses: [UUID: HabitCheckStatus] = [:]
    @State private var categories: [Category] = []

    @State private var reflection: ReflectionEntry
    @State private var errorMessage: String? = nil

    init(date: Date) {
        self.date = date
        _reflection = State(initialValue: ReflectionEntry(date: date))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                    habitsSection
                    reflectionSection

                    BrutalistButton(title: "SAVE CHECK-IN", borderColor: AppColor.green) {
                        saveCheckIn()
                    }

                    NavigationLink {
                        ReflectionLogView()
                    } label: {
                        HStack {
                            Text("PAST CHECK-INS")
                                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(minHeight: AppLayout.minTapTarget)
                    }
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.vertical, AppLayout.sectionSpacing)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("END-OF-DAY CHECK-IN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Couldn't save", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear { loadData() }
        }
    }

    // MARK: - Habits

    private var habitsSection: some View {
        let followedCount = habitStatuses.values.filter { $0 == .followed }.count
        return VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
            HStack {
                Text("HABIT COMMITMENTS")
                    .font(.system(.subheadline, design: .monospaced).weight(.bold))
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                if !routines.isEmpty {
                    Text("\(followedCount)/\(routines.count) FOLLOWED")
                        .font(.system(.caption, design: .monospaced).weight(.black))
                        .foregroundStyle(followedCount == routines.count ? AppColor.green : AppColor.textPrimary)
                }
            }

            if routines.isEmpty {
                Text("No habit commitments scheduled today. Add them from Tasks → Habit commitments.")
                    .font(.system(.subheadline))
                    .foregroundStyle(AppColor.textSecondary)
            } else {
                ForEach(routines) { routine in
                    routineRow(routine)
                }
            }
        }
    }

    private func routineRow(_ routine: HabitRoutine) -> some View {
        let currentStatus = habitStatuses[routine.id] ?? .pending
        let color = categories.first { $0.id == routine.categoryId }?.color ?? AppColor.neutralDot

        return BrutalistCard(borderColor: currentStatus == .followed ? AppColor.green : (currentStatus == .failed ? AppColor.red : AppColor.border)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    CategoryDot(color: color)
                    Text(routine.title)
                        .font(.system(.body).weight(.bold))
                        .foregroundStyle(AppColor.textPrimary)
                }

                HStack(spacing: 12) {
                    checkButton("FOLLOWED", symbol: "checkmark", isOn: currentStatus == .followed, tint: AppColor.green) {
                        habitStatuses[routine.id] = currentStatus == .followed ? .pending : .followed
                    }
                    checkButton("NOT FOLLOWED", symbol: "xmark", isOn: currentStatus == .failed, tint: AppColor.red) {
                        habitStatuses[routine.id] = currentStatus == .failed ? .pending : .failed
                    }
                }
            }
        }
    }

    private func checkButton(_ title: String, symbol: String, isOn: Bool, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(.caption, design: .monospaced).weight(.black))
                .foregroundStyle(isOn ? .white : AppColor.textPrimary)
                .frame(maxWidth: .infinity, minHeight: AppLayout.minTapTarget)
                .background(isOn ? tint : AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(isOn ? tint : AppColor.border, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reflection

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
            Text("REFLECTION")
                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                .foregroundStyle(AppColor.textSecondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("HOW DID TODAY GO?")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(AppColor.textSecondary)
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { rating in
                        Button {
                            reflection.consistencyRating = reflection.consistencyRating == rating ? 0 : rating
                        } label: {
                            Text("\(rating)")
                                .font(.system(.headline, design: .monospaced).weight(.black))
                                .foregroundStyle(reflection.consistencyRating >= rating ? AppColor.background : AppColor.textPrimary)
                                .frame(maxWidth: .infinity, minHeight: AppLayout.minTapTarget)
                                .background(reflection.consistencyRating >= rating ? AppColor.border : AppColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                                .overlay(RoundedRectangle(cornerRadius: AppLayout.cornerRadius).stroke(AppColor.border, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Rate today \(rating) out of 5")
                    }
                }
            }

            reflectionField("WINS", prompt: "What went well?", text: $reflection.accomplishments)
            reflectionField("WHAT SLIPPED", prompt: "What got missed, and why?", text: $reflection.missedItems)
            reflectionField("TOMORROW'S TOP PRIORITIES", prompt: "1–3 things that matter most", text: $reflection.tomorrowPriorities)
        }
    }

    private func reflectionField(_ title: String, prompt: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .foregroundStyle(AppColor.textSecondary)
            TextField(prompt, text: text, axis: .vertical)
                .lineLimit(2...6)
                .font(.system(.body))
                .foregroundStyle(AppColor.textPrimary)
                .padding(10)
                .frame(minHeight: AppLayout.minTapTarget)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(AppColor.border, lineWidth: 1.5)
                )
        }
    }

    // MARK: - Data

    private func loadData() {
        do {
            categories = try env.categoryRepository.fetchAll()
            routines = try env.habitRoutineRepository.fetchActive(for: date)
            let tasks = try GenerateRoutineTasksUseCase(
                habitRoutineRepository: env.habitRoutineRepository,
                taskRepository: env.taskRepository
            ).execute(for: date)
            routineTasks = Dictionary(
                tasks.compactMap { task in task.routineId.map { ($0, task) } }.filter { !$1.isDeleted },
                uniquingKeysWith: { first, _ in first }
            )

            var logged: [UUID: HabitCheckStatus] = [:]
            for log in try env.dailyHabitLogRepository.fetchLogs(for: date) {
                logged[log.habitId] = log.status
            }
            savedStatuses = logged
            // The habit's task is the source of truth: ticked = followed. A saved
            // "not followed" only applies while the task is still unticked.
            var statuses: [UUID: HabitCheckStatus] = [:]
            for routine in routines {
                if routineTasks[routine.id]?.isCompleted == true {
                    statuses[routine.id] = .followed
                } else if logged[routine.id] == .failed {
                    statuses[routine.id] = .failed
                }
            }
            habitStatuses = statuses

            if let existing = try env.reflectionRepository.fetch(date: date) {
                reflection = existing
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveCheckIn() {
        do {
            var newlyMissed = 0
            for routine in routines {
                let status = habitStatuses[routine.id] ?? .pending
                try env.dailyHabitLogRepository.save(DailyHabitLog(date: date, habitId: routine.id, status: status))

                guard let task = routineTasks[routine.id] else { continue }
                switch status {
                case .followed where !task.isCompleted:
                    // Completing the task awards the habit XP and updates the day status.
                    try env.setTaskCompleted(task.id, completed: true, syncAfterwards: false)
                case .failed:
                    if task.isCompleted {
                        try env.setTaskCompleted(task.id, completed: false, syncAfterwards: false)
                    }
                    if savedStatuses[routine.id] != .failed { newlyMissed += 1 }
                case .pending where task.isCompleted:
                    // "Followed" was deselected, so the habit isn't done after all.
                    try env.setTaskCompleted(task.id, completed: false, syncAfterwards: false)
                default:
                    break
                }
            }

            if newlyMissed > 0 {
                _ = try DeductXPUseCase(
                    playerProfileRepository: env.playerProfileRepository,
                    xpTransactionRepository: env.xpTransactionRepository
                ).execute(
                    penaltyAmount: newlyMissed * 15,
                    reason: .habitMissedDecay,
                    note: "End-of-day check-in (\(newlyMissed) not followed)"
                )
            }

            let hasReflection = reflection.consistencyRating > 0
                || ![reflection.accomplishments, reflection.missedItems, reflection.tomorrowPriorities]
                    .allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if hasReflection {
                try SaveReflectionUseCase(repository: env.reflectionRepository).execute(reflection)
            }

            try SyncGoalProgressUseCase(
                goalRepository: env.goalRepository,
                dayEntryRepository: env.dayEntryRepository,
                taskRepository: env.taskRepository,
                settingsRepository: env.settingsRepository
            ).execute()
            env.syncWidgets()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Reflection log

struct ReflectionLogView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var entries: [ReflectionEntry] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                if entries.isEmpty {
                    EmptyStateView(message: "No check-ins yet.\nYour reflections will show up here.")
                        .frame(maxWidth: .infinity)
                }
                ForEach(entries) { entry in
                    BrutalistCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(entry.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year()).uppercased())
                                    .font(.system(.subheadline, design: .monospaced).weight(.black))
                                    .foregroundStyle(AppColor.textPrimary)
                                Spacer()
                                if entry.consistencyRating > 0 {
                                    Text("\(entry.consistencyRating)/5")
                                        .font(.system(.subheadline, design: .monospaced).weight(.black))
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                            }
                            logLine("WINS", entry.accomplishments)
                            logLine("SLIPPED", entry.missedItems)
                            logLine("NEXT", entry.tomorrowPriorities)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(AppLayout.screenMargin)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("PAST CHECK-INS")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            entries = (try? env.reflectionRepository.fetchAll()) ?? []
        }
    }

    @ViewBuilder
    private func logLine(_ label: String, _ text: String) -> some View {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(AppColor.textSecondary)
                Text(trimmed)
                    .font(.system(.subheadline))
                    .foregroundStyle(AppColor.textPrimary)
            }
        }
    }
}
