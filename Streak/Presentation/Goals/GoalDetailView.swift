// Presentation/Goals/GoalDetailView.swift
// Displays progress metrics, completion timeline, and manual logging for milestone goals.

import SwiftUI

@Observable
final class GoalDetailViewModel {
    private let env: AppEnvironment
    let goalId: UUID
    
    var goal: Goal? = nil
    var progressEntries: [GoalProgressEntry] = []
    var category: Category? = nil
    
    // Log inputs
    var logValueString = ""
    var logNote = ""
    
    init(env: AppEnvironment, goalId: UUID) {
        self.env = env
        self.goalId = goalId
    }
    
    func load() {
        do {
            goal = try env.goalRepository.fetch(id: goalId)
            if let goal {
                progressEntries = try env.goalRepository.fetchProgressEntries(goalId: goalId)
                    .sorted(by: { $0.date > $1.date }) // latest first
                
                if let catId = goal.categoryId {
                    category = try env.categoryRepository.fetch(id: catId)
                }
            }
        } catch {
            print("Failed to load goal detail: \(error)")
        }
    }
    
    func logProgress() {
        guard let value = Double(logValueString), value > 0 else { return }
        do {
            let syncUseCase = SyncGoalProgressUseCase(
                goalRepository: env.goalRepository,
                dayEntryRepository: env.dayEntryRepository,
                taskRepository: env.taskRepository
            )
            let logUseCase = LogGoalProgressUseCase(
                goalRepository: env.goalRepository,
                syncGoalProgress: syncUseCase
            )
            try logUseCase.execute(
                goalId: goalId,
                value: value,
                note: logNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : logNote
            )
            
            // Clear fields and reload
            logValueString = ""
            logNote = ""
            load()
            env.syncWidgets()
        } catch {
            print("Failed to log progress: \(error)")
        }
    }
}

struct GoalDetailView: View {
    let env: AppEnvironment
    @State private var vm: GoalDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(env: AppEnvironment, goalId: UUID) {
        self.env = env
        _vm = State(initialValue: GoalDetailViewModel(env: env, goalId: goalId))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                if let goal = vm.goal {
                    let color = vm.category.flatMap { Color(hex: $0.colorHex) } ?? AppColor.border
                    
                    // Goal Profile card
                    BrutalistCard(borderColor: color) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 8) {
                                CategoryDot(color: color)
                                Text(goal.title.uppercased())
                                    .font(.system(.headline).weight(.bold))
                                    .foregroundStyle(AppColor.textPrimary)
                                Spacer()
                            }
                            
                            Text("Goal Type: \(friendlyGoalType(goal.goalType))")
                                .font(.system(.subheadline))
                                .foregroundStyle(AppColor.textSecondary)
                            
                            ProgressBarView(
                                fraction: goal.progressFraction,
                                label: "\(formatValue(goal.currentValue)) / \(formatValue(goal.targetValue)) \(goal.unit)",
                                fillColor: color
                            )
                            
                            HStack {
                                Text("\(Int(goal.progressFraction * 100))% completed")
                                    .font(.system(.footnote, design: .monospaced).weight(.bold))
                                    .foregroundStyle(AppColor.textPrimary)
                                Spacer()
                                if let targetDate = goal.targetDate {
                                    Text("Deadline: \(formatDate(targetDate))")
                                        .font(.system(.footnote))
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                            }
                        }
                    }
                    
                    // Manual Progress Logger (Milestone-based only)
                    if goal.goalType == .milestoneBased && !goal.isCompleted {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("LOG PROGRESS")
                                .font(.system(.headline).weight(.bold))
                                .foregroundStyle(AppColor.textSecondary)
                            
                            BrutalistCard {
                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        TextField("Value (e.g. 10)", text: $vm.logValueString)
                                            .keyboardType(.decimalPad)
                                            .padding(10)
                                            .background(AppColor.background)
                                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.border, lineWidth: 1.5))
                                            .font(.system(.body))
                                        
                                        Text(goal.unit)
                                            .font(.system(.body).weight(.bold))
                                            .foregroundStyle(AppColor.textSecondary)
                                    }
                                    
                                    TextField("Note (optional)", text: $vm.logNote)
                                        .padding(10)
                                        .background(AppColor.background)
                                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.border, lineWidth: 1.5))
                                        .font(.system(.body))
                                    
                                    BrutalistButton(title: "LOG UPDATE", borderColor: AppColor.border) {
                                        vm.logProgress()
                                    }
                                }
                            }
                        }
                    }
                    
                    // Progress History Log
                    VStack(alignment: .leading, spacing: 10) {
                        Text("PROGRESS TIMELINE")
                            .font(.system(.headline).weight(.bold))
                            .foregroundStyle(AppColor.textSecondary)
                        
                        if goal.goalType == .milestoneBased {
                            if vm.progressEntries.isEmpty {
                                Text("No updates logged yet.")
                                    .font(.system(.body))
                                    .foregroundStyle(AppColor.textDisabled)
                                    .padding(.top, 4)
                            } else {
                                ForEach(vm.progressEntries) { entry in
                                    BrutalistCard {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(formatDate(entry.date).uppercased())
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundStyle(AppColor.textSecondary)
                                                
                                                if let note = entry.note {
                                                    Text(note)
                                                        .font(.system(.body))
                                                        .foregroundStyle(AppColor.textPrimary)
                                                }
                                            }
                                            Spacer()
                                            Text("+\(formatValue(entry.value)) \(goal.unit)")
                                                .font(.system(.body, design: .monospaced).weight(.bold))
                                                .foregroundStyle(AppColor.textPrimary)
                                        }
                                    }
                                }
                            }
                        } else {
                            // Automatic updates explanation
                            BrutalistCard {
                                Text(automaticSourceExplanation(goal.goalType, categoryName: vm.category?.name ?? "linked category"))
                                    .font(.system(.body))
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        }
                    }
                } else {
                    EmptyStateView(message: "Goal profile not found.")
                }
            }
            .padding(.horizontal, AppLayout.screenMargin)
            .padding(.vertical, AppLayout.sectionSpacing)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    let deleteUseCase = DeleteGoalUseCase(goalRepository: env.goalRepository)
                    try? deleteUseCase.execute(id: vm.goalId)
                    env.syncWidgets()
                    dismiss()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .onAppear {
            vm.load()
        }
    }
    
    private func friendlyGoalType(_ type: GoalType) -> String {
        switch type {
        case .consecutiveStreak: return "Active Streak"
        case .cumulativeDays: return "Total Green Days"
        case .milestoneBased: return "Manual Target"
        case .taskCounter: return "Total Tasks Done"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatValue(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", val)
        } else {
            return String(format: "%.1f", val)
        }
    }
    
    private func automaticSourceExplanation(_ type: GoalType, categoryName: String) -> String {
        switch type {
        case .consecutiveStreak:
            return "This progress bar increases automatically based on your active consecutive streak in \(categoryName). If you miss a day, the progress resets to 0%."
        case .cumulativeDays:
            return "This progress bar tracks the total count of green days in \(categoryName) since starting. Missing days will temporarily pause progress but will not reset it."
        case .taskCounter:
            return "This progress bar tracks the total number of tasks you complete under the \(categoryName) category. Tasks completed before starting the goal are not counted."
        case .milestoneBased:
            return ""
        }
    }
}
