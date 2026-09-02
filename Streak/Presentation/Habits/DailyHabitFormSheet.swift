// Presentation/Habits/DailyHabitFormSheet.swift

import SwiftUI

struct DailyHabitFormSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let date: Date
    @State private var routines: [HabitRoutine] = []
    @State private var habitStatuses: [UUID: HabitCheckStatus] = [:]
    @State private var categories: [Category] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                    // Header Card
                    headerCard

                    // Habit Commitments List
                    if routines.isEmpty {
                        emptyRoutinesCard
                    } else {
                        VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                            Text("MONTHLY HABIT COMMITMENTS")
                                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                                .foregroundStyle(AppColor.textSecondary)

                            ForEach(routines) { routine in
                                routineRow(routine)
                            }
                        }

                        // Save Button
                        BrutalistButton(title: "SAVE END OF DAY CHECK-IN", borderColor: AppColor.green) {
                            saveCheckIn()
                        }
                        .padding(.top, 10)
                    }
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
        let totalCount = routines.count

        return BrutalistCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DAILY HABIT REFLECTION")
                            .font(.system(.headline, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)
                        Text("Check off your monthly habit commitments for today.")
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

    private var emptyRoutinesCard: some View {
        BrutalistCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("NO ACTIVE HABIT COMMITMENTS")
                    .font(.system(.headline, design: .monospaced).weight(.bold))
                    .foregroundStyle(AppColor.textPrimary)
                Text("You haven't set your habit commitments for this month yet. Create your monthly habit commitments in the Tasks tab to fill out this end-of-day form.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }

    private func routineRow(_ routine: HabitRoutine) -> some View {
        let currentStatus = habitStatuses[routine.id] ?? .pending
        let categoryColor = categoryColor(for: routine.categoryId)

        return BrutalistCard(borderColor: currentStatus == .followed ? AppColor.green : (currentStatus == .failed ? AppColor.red : AppColor.border)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    CategoryDot(color: categoryColor)
                    Text(routine.title)
                        .font(.system(.body).weight(.bold))
                        .foregroundStyle(AppColor.textPrimary)
                }

                HStack(spacing: 12) {
                    // Tick Button (Followed)
                    Button {
                        habitStatuses[routine.id] = (currentStatus == .followed) ? .pending : .followed
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
                        habitStatuses[routine.id] = (currentStatus == .failed) ? .pending : .failed
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

    private func categoryColor(for categoryId: UUID?) -> Color {
        guard let categoryId else { return AppColor.neutralDot }
        return categories.first(where: { $0.id == categoryId })?.color ?? AppColor.neutralDot
    }

    private func loadData() {
        do {
            categories = try env.categoryRepository.fetchAll()
            routines = try env.habitRoutineRepository.fetchActive(for: date)
            let existingLogs = try env.dailyHabitLogRepository.fetchLogs(for: date)
            for log in existingLogs {
                habitStatuses[log.habitId] = log.status
            }
        } catch {
            print("Failed to load routines: \(error)")
        }
    }

    private func saveCheckIn() {
        do {
            var followedCount = 0
            let resolver = ResolveDayStatusUseCase(
                taskRepository: env.taskRepository,
                categoryRepository: env.categoryRepository,
                dayEntryRepository: env.dayEntryRepository,
                settingsRepository: env.settingsRepository
            )
            let completeUseCase = CompleteTaskUseCase(
                taskRepository: env.taskRepository,
                resolveDayStatus: resolver,
                settingsRepository: env.settingsRepository,
                playerProfileRepository: env.playerProfileRepository,
                xpTransactionRepository: env.xpTransactionRepository,
                badgeRepository: env.badgeRepository,
                goalRepository: env.goalRepository,
                habitRoutineRepository: env.habitRoutineRepository,
                dayEntryRepository: env.dayEntryRepository
            )

            // Fetch daily tasks for date to sync routine completion
            let tasksForDate = try env.taskRepository.fetchAll(for: date)

            var notFollowedCount = 0
            for routine in routines {
                let status = habitStatuses[routine.id] ?? .pending
                let log = DailyHabitLog(date: date, habitId: routine.id, status: status)
                try env.dailyHabitLogRepository.save(log)

                if status == .followed {
                    followedCount += 1

                    // Sync corresponding routine task if created
                    if let matchingTask = tasksForDate.first(where: { $0.title == routine.title && !$0.isCompleted }) {
                        try completeUseCase.execute(taskId: matchingTask.id, completed: true)
                    }
                } else if status == .failed {
                    notFollowedCount += 1
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
                    note: "End-of-day Habit Form (\(followedCount) Followed)"
                )
            }

            // Deduct XP penalty for not-followed habits
            if notFollowedCount > 0 {
                let deductUseCase = DeductXPUseCase(
                    playerProfileRepository: env.playerProfileRepository,
                    xpTransactionRepository: env.xpTransactionRepository
                )
                _ = try deductUseCase.execute(
                    penaltyAmount: notFollowedCount * 15,
                    reason: .habitMissedDecay,
                    note: "End-of-day Habit Form (\(notFollowedCount) Not Followed)"
                )
            }

            env.syncWidgets()
            dismiss()
        } catch {
            print("Failed to save habit check-in: \(error)")
        }
    }
}
