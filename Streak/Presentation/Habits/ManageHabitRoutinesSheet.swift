// Presentation/Habits/ManageHabitRoutinesSheet.swift

import SwiftUI

struct ManageHabitRoutinesSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let categories: [Category]
    let onRoutineChanged: () -> Void

    @State private var routines: [HabitRoutine] = []
    @State private var progress: [UUID: HabitProgress] = [:]
    @State private var showAddSheet: Bool = false
    @State private var routineToDelete: HabitRoutine? = nil
    @State private var errorMessage: String? = nil

    /// Running now or starting later; ended sprints are listed separately.
    private var activeRoutines: [HabitRoutine] {
        routines.filter { $0.isInDateRange(activeToday) || Calendar.current.startOfDay(for: $0.startDate) > activeToday }
    }

    private var endedRoutines: [HabitRoutine] {
        routines.filter { !($0.isInDateRange(activeToday) || Calendar.current.startOfDay(for: $0.startDate) > activeToday) }
    }

    private var activeToday: Date {
        ActiveDayResolver.resolveActiveDate(for: Date(), settings: env.settingsRepository)
    }

    private var isDay1: Bool {
        Calendar.current.component(.day, from: activeToday) == 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Day 1 Reset Window Banner
                    if isDay1 {
                        BrutalistCard(borderColor: AppColor.green) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundStyle(AppColor.green)
                                    Text("MONTHLY RESET WINDOW (DAY 1)")
                                        .font(.system(.subheadline, design: .monospaced).weight(.black))
                                        .foregroundStyle(AppColor.green)
                                }
                                Text("Today is the 1st of the month! You can add new habits, or delete/modify any existing monthly habit commitments for the new month.")
                                    .font(.system(.caption))
                                    .foregroundStyle(AppColor.textPrimary)
                            }
                        }
                    } else {
                        BrutalistCard {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(AppColor.textSecondary)
                                    Text("LOCKED FOR THE MONTH")
                                        .font(.system(.caption, design: .monospaced).weight(.bold))
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                                Text("Monthly habit commitments are locked to enforce consistency. You can add new habits anytime, but existing monthly habits can only be deleted or modified on Day 1 of every month.")
                                    .font(.system(.caption))
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.app(size: 11, weight: .bold))
                            .foregroundStyle(AppColor.red)
                    }

                    // Existing Habits List
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ACTIVE HABIT COMMITMENTS")
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textSecondary)

                        if activeRoutines.isEmpty {
                            BrutalistCard {
                                Text("No active habit commitments. Tap below to create one.")
                                    .font(.system(.subheadline))
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        } else {
                            ForEach(activeRoutines) { routine in
                                habitRow(routine)
                            }
                        }
                    }

                    if !endedRoutines.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ENDED SPRINTS")
                                .font(.system(.caption, design: .monospaced).weight(.bold))
                                .foregroundStyle(AppColor.textSecondary)
                            ForEach(endedRoutines) { routine in
                                habitRow(routine)
                                    .opacity(0.7)
                            }
                        }
                    }

                    // Add Habit Button
                    BrutalistButton(title: "+ ADD NEW HABIT COMMITMENT") {
                        showAddSheet = true
                    }
                    .padding(.top, 10)
                }
                .padding(AppLayout.screenMargin)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("HABIT COMMITMENTS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                loadRoutines()
            }
            .confirmationDialog(
                "Delete this habit?",
                isPresented: Binding(get: { routineToDelete != nil }, set: { if !$0 { routineToDelete = nil } }),
                titleVisibility: .visible,
                presenting: routineToDelete
            ) { routine in
                Button("Delete \(routine.title)", role: .destructive) {
                    deleteRoutine(routine)
                }
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("Its past days stay in your history. It stops appearing in your daily list from tomorrow.")
            }
            .sheet(isPresented: $showAddSheet) {
                AddHabitRoutineSheet(categories: categories) { title, categoryId, type, startDate, endDate, weekdays, healthRule in
                    addRoutine(title: title, categoryId: categoryId, type: type, startDate: startDate, endDate: endDate, weekdays: weekdays, healthRule: healthRule)
                }
            }
        }
    }

    private func habitRow(_ routine: HabitRoutine) -> some View {
        let cat = categories.first(where: { $0.id == routine.categoryId })
        let isDeletable = isDay1 || routine.type == .customRange
        let habitProgress = progress[routine.id]

        return BrutalistCard(borderColor: cat?.color ?? AppColor.border) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    CategoryDot(color: cat?.color ?? AppColor.neutralDot)
                        .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.title)
                            .font(.system(.body).weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)

                        Text(detailLine(routine, category: cat))
                            .font(.app(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColor.textSecondary)

                        if let rule = routine.healthRule {
                            Text("❤️ AUTO-TICK FROM HEALTH: \(rule.summary.uppercased())")
                                .font(.app(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(Color(hex: "#E74C3C"))
                        }
                    }

                    Spacer()

                    if let habitProgress {
                        Text("🔥 \(habitProgress.streak)")
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                            .foregroundStyle(AppColor.textPrimary)
                            .accessibilityLabel("\(habitProgress.streak) day habit streak")
                    }
                }

                HStack(alignment: .center) {
                    if let habitProgress {
                        HabitHistoryStrip(days: habitProgress.recent, size: 11)
                    }
                    Spacer()
                    if isDeletable {
                        Button {
                            routineToDelete = routine
                        } label: {
                            Image(systemName: "trash")
                                .font(.app(size: 14, weight: .bold))
                                .foregroundStyle(AppColor.red)
                                .frame(width: AppLayout.minTapTarget, height: AppLayout.minTapTarget)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Delete \(routine.title)")
                    } else {
                        HStack(spacing: 3) {
                            Image(systemName: "lock.fill")
                                .font(.app(size: 10, weight: .bold))
                            Text("LOCKED")
                                .font(.app(size: 9, weight: .bold))
                        }
                        .foregroundStyle(AppColor.textDisabled)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(AppColor.blank)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
    }

    private func detailLine(_ routine: HabitRoutine, category: Category?) -> String {
        var parts: [String] = [routine.type == .monthlyFixed ? "🔒 MONTHLY" : "⚡️ SPRINT"]
        if routine.type == .customRange {
            parts.append("ENDS \(routine.endDate.formatted(.dateTime.month(.abbreviated).day()).uppercased())")
        }
        parts.append(WeekdayPicker.summary(routine.weekdays))
        if let category { parts.append(category.name.uppercased()) }
        return parts.joined(separator: " · ")
    }

    private func loadRoutines() {
        do {
            routines = try env.habitRoutineRepository.fetchAll()
            let habitTasks = try env.taskRepository.fetchAll().filter { $0.routineId != nil && $0.timeframe == .daily }
            let protectedDays = Set(try env.dayEntryRepository.fetchAll(categoryId: nil)
                .filter { $0.status.isStreakNeutral }
                .map { Calendar.current.startOfDay(for: $0.date) })
            let calculator = CalculateHabitStreakUseCase(settingsRepository: env.settingsRepository)
            progress = Dictionary(uniqueKeysWithValues: routines.map { routine in
                (routine.id, calculator.execute(routine: routine, tasks: habitTasks, protectedDays: protectedDays))
            })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func addRoutine(title: String, categoryId: UUID?, type: HabitRoutineType, startDate: Date, endDate: Date, weekdays: Set<Int>, healthRule: HealthRule?) {
        do {
            let cal = Calendar.current
            let start: Date
            let end: Date
            let isLocked: Bool

            switch type {
            case .monthlyFixed:
                let comps = cal.dateComponents([.year, .month], from: activeToday)
                start = cal.date(from: comps) ?? activeToday
                let range = cal.range(of: .day, in: .month, for: activeToday)?.count ?? 30
                end = cal.date(byAdding: .day, value: range - 1, to: start) ?? activeToday
                isLocked = true
            case .customRange:
                start = cal.startOfDay(for: startDate)
                end = cal.startOfDay(for: endDate)
                isLocked = false
            }

            let routine = HabitRoutine(
                title: title,
                categoryId: categoryId,
                type: type,
                startDate: start,
                endDate: end,
                isLocked: isLocked,
                weekdays: weekdays,
                healthRule: healthRule
            )
            try env.habitRoutineRepository.save(routine)

            let generator = GenerateRoutineTasksUseCase(
                habitRoutineRepository: env.habitRoutineRepository,
                taskRepository: env.taskRepository
            )
            try generator.execute(for: activeToday)

            loadRoutines()
            onRoutineChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteRoutine(_ routine: HabitRoutine) {
        do {
            try env.habitRoutineRepository.delete(id: routine.id)
            loadRoutines()
            onRoutineChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
