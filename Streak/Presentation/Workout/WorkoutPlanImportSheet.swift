// Presentation/Workout/WorkoutPlanImportSheet.swift

import SwiftUI

struct WorkoutPlanImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onImport: (String) throws -> Void

    @State private var jsonText: String = ""
    @State private var errorMessage: String? = nil

    private var sampleJSONTemplate: String {
        """
        {
          "title": "Hypertrophy Push/Pull/Legs",
          "days": [
            {
              "dayName": "Monday",
              "dayOfWeek": 2,
              "title": "Push Day (Chest, Shoulders, Triceps)",
              "exercises": [
                {
                  "name": "Barbell Bench Press",
                  "category": "Chest",
                  "targetSets": 4,
                  "targetRepsOrDuration": "8-10 reps",
                  "youtubeUrl": "https://www.youtube.com/watch?v=rT7DgCr-3pg",
                  "notes": "Keep shoulder blades retracted"
                },
                {
                  "name": "Incline Dumbbell Press",
                  "category": "Chest",
                  "targetSets": 3,
                  "targetRepsOrDuration": "10-12 reps"
                }
              ]
            },
            {
              "dayName": "Tuesday",
              "dayOfWeek": 3,
              "title": "Pull Day (Back, Rear Delt, Biceps)",
              "exercises": [
                {
                  "name": "Lat Pulldown",
                  "category": "Back",
                  "targetSets": 4,
                  "targetRepsOrDuration": "10-12 reps"
                }
              ]
            }
          ]
        }
        """
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                HStack {
                    Text("PASTE WEEKLY WORKOUT PLAN (JSON)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer()
                    Button("Load Template") {
                        jsonText = sampleJSONTemplate
                        errorMessage = nil
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
                    let cleaned = jsonText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !cleaned.isEmpty else {
                        errorMessage = "JSON text cannot be empty."
                        return
                    }
                    do {
                        try onImport(cleaned)
                        dismiss()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                } label: {
                    Text("IMPORT WORKOUT PLAN")
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
            .navigationTitle("Import Workout Plan")
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
