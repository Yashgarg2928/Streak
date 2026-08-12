// Presentation/Workout/MealMacroImportSheet.swift

import SwiftUI

struct MealMacroImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let onImport: (String) -> Void

    @State private var jsonText: String = ""
    @State private var errorMessage: String? = nil

    private var templateJSON: String {
        """
        [
          {
            "mealType": "Lunch",
            "title": "Grilled Chicken & Rice",
            "details": "200g chicken breast, 150g cooked rice",
            "calories": 520,
            "proteinGrams": 45.0,
            "carbGrams": 40.0,
            "fatGrams": 10.0
          }
        ]
        """
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                HStack {
                    Text("PASTE MEAL MACROS (JSON)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer()
                    Button("Load Sample") {
                        jsonText = templateJSON
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColor.green)
                }

                TextEditor(text: $jsonText)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(8)
                    .background(AppColor.blank)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))

                if let errorMessage {
                    Text("⚠️ \(errorMessage)")
                        .font(.system(.caption, weight: .bold))
                        .foregroundStyle(AppColor.red)
                }

                Button {
                    guard !jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        errorMessage = "JSON text cannot be empty."
                        return
                    }
                    onImport(jsonText)
                    dismiss()
                } label: {
                    Text("IMPORT MEALS TO ACTIVE DAY")
                        .font(.system(.subheadline, design: .monospaced).weight(.black))
                        .foregroundStyle(AppColor.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColor.green)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            .padding(AppLayout.screenMargin)
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Import Meal Macros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
    }
}
