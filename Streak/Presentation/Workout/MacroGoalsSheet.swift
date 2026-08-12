// Presentation/Workout/MacroGoalsSheet.swift

import SwiftUI

struct MacroGoalsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let currentGoals: MacroGoals
    let onSave: (MacroGoals) -> Void

    @State private var targetCaloriesStr: String = ""
    @State private var targetProteinStr: String = ""
    @State private var targetCarbsStr: String = ""
    @State private var targetFatStr: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("DAILY TARGET MACRONUTRIENTS") {
                    HStack {
                        Text("🔥 Calories (kcal)")
                            .font(.system(.subheadline, weight: .bold))
                        Spacer()
                        TextField("2200", text: $targetCaloriesStr)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("🥩 Protein (g)")
                            .font(.system(.subheadline, weight: .bold))
                        Spacer()
                        TextField("150", text: $targetProteinStr)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("🌾 Carbohydrates (g)")
                            .font(.system(.subheadline, weight: .bold))
                        Spacer()
                        TextField("220", text: $targetCarbsStr)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("🥑 Healthy Fats (g)")
                            .font(.system(.subheadline, weight: .bold))
                        Spacer()
                        TextField("65", text: $targetFatStr)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
            }
            .navigationTitle("Set Daily Macro Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColor.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Goals") {
                        let calories = Int(targetCaloriesStr) ?? currentGoals.targetCalories
                        let protein = Double(targetProteinStr) ?? currentGoals.targetProteinGrams
                        let carbs = Double(targetCarbsStr) ?? currentGoals.targetCarbGrams
                        let fat = Double(targetFatStr) ?? currentGoals.targetFatGrams

                        let updated = MacroGoals(
                            targetCalories: calories,
                            targetProteinGrams: protein,
                            targetCarbGrams: carbs,
                            targetFatGrams: fat
                        )
                        onSave(updated)
                        dismiss()
                    }
                    .font(.system(.body, weight: .bold))
                    .foregroundStyle(AppColor.green)
                }
            }
            .onAppear {
                targetCaloriesStr = "\(currentGoals.targetCalories)"
                targetProteinStr = String(format: "%.0f", currentGoals.targetProteinGrams)
                targetCarbsStr = String(format: "%.0f", currentGoals.targetCarbGrams)
                targetFatStr = String(format: "%.0f", currentGoals.targetFatGrams)
            }
        }
    }
}
