// Presentation/Habits/DailyHabitFormSheet.swift

import SwiftUI

struct DailyHabitFormSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let date: Date
    @State private var habits: [CoreHabit] = []
    @State private var habitStatuses: [UUID: HabitCheckStatus] = [:]
    @State private var showAddHabitField: Bool = false
    @State private var newHabitTitle: String = ""
    @State private var isSaved: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                    // Header Banner Card
                    headerCard

                    // Habits List with Tick & Cross Buttons
                    VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                        Text("TODAY'S HABITS CHECK-IN")
                            .font(.system(.subheadline, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textSecondary)

                        ForEach(habits) { habit in
                            habitRow(habit)
                        }
                    }

                    // Add New Core Habit
                    addHabitSection

                    // Save Button
                    BrutalistButton(title: "SAVE END OF DAY CHECK-IN", borderColor: AppColor.green) {
                        saveCheckIn()
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.vertical, AppLayout.sectionSpacing)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("END-OF-DAY HABIT FORM")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                loadData()
            }
        }
    }

    private var headerCard: some View {
        let followedCount = habitStatuses.values.filter { $0 == .followed }.count
        let failedCount = habitStatuses.values.filter { $0 == .failed }.count
        let totalCount = habits.count

        return BrutalistCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DAILY HABIT REFLECTION")
                            .font(.system(.headline, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)
                        Text("Be honest with yourself. Small daily habits shape your life.")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Spacer()
                }

                Divider().background(AppColor.border)

                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Text("✅")
                        Text("\(followedCount) FOLLOWED")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(AppColor.green)
                    }

                    HStack(spacing: 6) {
                        Text("❌")
                        Text("\(failedCount) FAILED")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(AppColor.red)
                    }

                    Spacer()

                    Text("\(followedCount)/\(totalCount)")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
        }
    }

    private func habitRow(_ habit: CoreHabit) -> some View {
        let currentStatus = habitStatuses[habit.id] ?? .pending

        return BrutalistCard(borderColor: currentStatus == .followed ? AppColor.green : (currentStatus == .failed ? AppColor.red : AppColor.border)) {
            VStack(alignment: .leading, spacing: 10) {
                Text(habit.title)
                    .font(.system(.body).weight(.bold))
                    .foregroundStyle(AppColor.textPrimary)

                HStack(spacing: 12) {
                    // Tick Button (Followed)
                    Button {
                        habitStatuses[habit.id] = (currentStatus == .followed) ? .pending : .followed
                    } label: {
                        HStack(spacing: 6) {
                            Text("✅")
                            Text("FOLLOWED")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                        }
                        .foregroundStyle(currentStatus == .followed ? .white : AppColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(currentStatus == .followed ? AppColor.green : AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(currentStatus == .followed ? AppColor.green : AppColor.border, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)

                    // Cross Button (Not Followed / Failed)
                    Button {
                        habitStatuses[habit.id] = (currentStatus == .failed) ? .pending : .failed
                    } label: {
                        HStack(spacing: 6) {
                            Text("❌")
                            Text("NOT FOLLOWED")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                        }
                        .foregroundStyle(currentStatus == .failed ? .white : AppColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(currentStatus == .failed ? AppColor.red : AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(currentStatus == .failed ? AppColor.red : AppColor.border, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var addHabitSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showAddHabitField {
                BrutalistCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ADD NEW HABIT")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColor.textSecondary)

                        TextField("e.g., No Masturbation, Cold Shower...", text: $newHabitTitle)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))

                        HStack {
                            Button("Cancel") {
                                showAddHabitField = false
                                newHabitTitle = ""
                            }
                            .foregroundStyle(AppColor.textSecondary)
                            .font(.system(size: 11, weight: .bold))

                            Spacer()

                            Button("Add Habit") {
                                addHabit()
                            }
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(AppColor.background)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppColor.border)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .disabled(newHabitTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
            } else {
                Button {
                    showAddHabitField = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("ADD CUSTOM LIFELONG HABIT")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                            .stroke(AppColor.border, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func loadData() {
        do {
            habits = try env.coreHabitRepository.fetchAllActive()
            let existingLogs = try env.dailyHabitLogRepository.fetchLogs(for: date)
            for log in existingLogs {
                habitStatuses[log.habitId] = log.status
            }
        } catch {
            print("Failed to load habits: \(error)")
        }
    }

    private func addHabit() {
        let trimmed = newHabitTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        do {
            let newHabit = CoreHabit(title: trimmed)
            try env.coreHabitRepository.save(newHabit)
            newHabitTitle = ""
            showAddHabitField = false
            loadData()
        } catch {
            print("Failed to save core habit: \(error)")
        }
    }

    private func saveCheckIn() {
        do {
            var followedCount = 0
            for habit in habits {
                let status = habitStatuses[habit.id] ?? .pending
                let log = DailyHabitLog(date: date, habitId: habit.id, status: status)
                try env.dailyHabitLogRepository.save(log)
                if status == .followed {
                    followedCount += 1
                }
            }

            // Award XP for followed habits
            if followedCount > 0 {
                let awardUseCase = AwardXPUseCase(
                    playerProfileRepository: env.playerProfileRepository,
                    xpTransactionRepository: env.xpTransactionRepository,
                    badgeRepository: env.badgeRepository,
                    dayEntryRepository: env.dayEntryRepository,
                    taskRepository: env.taskRepository,
                    goalRepository: env.goalRepository,
                    habitRoutineRepository: env.habitRoutineRepository
                )
                _ = try awardUseCase.execute(
                    amount: followedCount * 15,
                    reason: .habitCompleted,
                    note: "Daily Habit Check-in (\(followedCount) Followed)"
                )
            }

            dismiss()
        } catch {
            print("Failed to save habit check-in: \(error)")
        }
    }
}
