// Presentation/Goals/AddGoalView.swift
// Create Goal form sheet with options for tracking types, deadlines, and category linkage.

import SwiftUI

struct AddGoalView: View {
    let env: AppEnvironment
    let vm: GoalsViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    // Form inputs
    @State private var title: String = ""
    @State private var goalType: GoalType = .consecutiveStreak
    @State private var categoryId: UUID? = nil
    @State private var targetValueString: String = ""
    @State private var unit: String = "days"
    @State private var targetDate: Date = Date().addingTimeInterval(3600 * 24 * 30) // +30 days
    @State private var enableTargetDate: Bool = false
    
    @State private var validationError: String? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Goal Title (e.g. Gym 60 Days)", text: $title)
                        .font(.system(.body))
                } header: {
                    Text("TITLE")
                }
                
                Section {
                    Picker("Goal Type", selection: $goalType) {
                        Text("Active Streak").tag(GoalType.consecutiveStreak)
                        Text("Total Green Days").tag(GoalType.cumulativeDays)
                        Text("Manual Target").tag(GoalType.milestoneBased)
                        Text("Total Tasks Done").tag(GoalType.taskCounter)
                    }
                    .pickerStyle(.menu)
                    
                    if goalType != .milestoneBased {
                        Picker("Link Category", selection: $categoryId) {
                            Text("Select Category...").tag(nil as UUID?)
                            ForEach(vm.categories) { cat in
                                Text(cat.name).tag(cat.id as UUID?)
                            }
                        }
                    }
                } header: {
                    Text("TRACKING TYPE")
                } footer: {
                    Text(goalTypeExplanation(goalType))
                        .font(.system(.footnote))
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.top, 4)
                }
                
                Section {
                    TextField("Target Value (e.g. 90)", text: $targetValueString)
                        .keyboardType(.decimalPad)
                    
                    TextField("Unit Symbol (e.g. days, ₹, km)", text: $unit)
                } header: {
                    Text("TARGET VALUE & UNIT")
                }
                
                Section {
                    Toggle("Set Completion Deadline", isOn: $enableTargetDate)
                    if enableTargetDate {
                        DatePicker("Deadline", selection: $targetDate, displayedComponents: .date)
                    }
                } header: {
                    Text("TIMELINE")
                }
                
                if let validationError {
                    Section {
                        Text(validationError)
                            .foregroundStyle(.red)
                            .font(.system(.footnote))
                    }
                }
            }
            .navigationTitle("NEW GOAL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                }
            }
            .onAppear {
                // Pre-select first category if available
                if categoryId == nil {
                    categoryId = vm.categories.first?.id
                }
            }
        }
    }
    
    private func saveGoal() {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationError = "Title cannot be empty."
            return
        }
        guard let targetValue = Double(targetValueString), targetValue > 0 else {
            validationError = "Target value must be greater than zero."
            return
        }
        if goalType != .milestoneBased && categoryId == nil {
            validationError = "Automatic goals require a linked category."
            return
        }
        
        let targetDeadline = enableTargetDate ? targetDate : nil
        let success = vm.createGoal(
            title: title,
            goalType: goalType,
            categoryId: categoryId,
            targetValue: targetValue,
            unit: unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "units" : unit,
            targetDate: targetDeadline
        )
        
        if success {
            dismiss()
        } else {
            validationError = vm.errorMessage ?? "Failed to save goal."
        }
    }
    
    private func goalTypeExplanation(_ type: GoalType) -> String {
        switch type {
        case .consecutiveStreak:
            return "Active Streak: Tracks your active daily streak. Resets to 0 if you miss a day."
        case .cumulativeDays:
            return "Total Green Days: Counts the total days you completed tasks. Missing days pauses progress (does not reset)."
        case .milestoneBased:
            return "Manual Target: Enter progress manually over time (e.g. money saved, books read)."
        case .taskCounter:
            return "Total Tasks Done: Counts every single completed task inside this category."
        }
    }
}
