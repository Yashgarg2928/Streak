// Presentation/Habits/ManageHabitRoutinesSheet.swift

import SwiftUI

struct ManageHabitRoutinesSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    let categories: [Category]
    let onRoutineChanged: () -> Void

    @State private var routines: [HabitRoutine] = []
    @State private var showAddSheet: Bool = false
    @State private var errorMessage: String? = nil

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
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppColor.red)
                    }

                    // Existing Habits List
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ACTIVE HABIT COMMITMENTS")
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textSecondary)

                        if routines.isEmpty {
                            BrutalistCard {
                                Text("No active habit commitments. Tap below to create one.")
                                    .font(.system(.subheadline))
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        } else {
                            ForEach(routines) { routine in
                                habitRow(routine)
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
            .onAppear { loadRoutines() }
            .sheet(isPresented: $showAddSheet) {
                AddHabitRoutineSheet(categories: categories) { title, categoryId, type, startDate, endDate in
                    addRoutine(title: title, categoryId: categoryId, type: type, startDate: startDate, endDate: endDate)
                }
            }
        }
    }

    private func habitRow(_ routine: HabitRoutine) -> some View {
        let cat = categories.first(where: { $0.id == routine.categoryId })
        let isDeletable = isDay1 || routine.type == .customRange

        return BrutalistCard {
            HStack(spacing: 12) {
                CategoryDot(color: cat?.color ?? AppColor.neutralDot)

                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.title)
                        .font(.system(.body).weight(.bold))
                        .foregroundStyle(AppColor.textPrimary)

                    HStack(spacing: 6) {
                        Text(routine.type == .monthlyFixed ? "🔒 MONTHLY COMMITMENT" : "⚡️ HABIT SPRINT")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(AppColor.textSecondary)

                        if let cat {
                            Text("• \(cat.name.uppercased())")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(cat.color)
                        }
                    }
                }

                Spacer()

                if isDeletable {
                    Button {
                        deleteRoutine(routine)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColor.red)
                            .frame(width: 32, height: 32)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.red, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 3) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("LOCKED")
                            .font(.system(size: 9, weight: .bold))
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

    private func loadRoutines() {
        do {
            routines = try env.habitRoutineRepository.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func addRoutine(title: String, categoryId: UUID?, type: HabitRoutineType, startDate: Date, endDate: Date) {
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
                isLocked: isLocked
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
