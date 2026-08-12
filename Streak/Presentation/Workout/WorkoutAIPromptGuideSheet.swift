// Presentation/Workout/WorkoutAIPromptGuideSheet.swift

import SwiftUI

struct WorkoutAIPromptGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var copiedWorkoutPrompt: Bool = false
    @State private var copiedMealPrompt: Bool = false

    private var workoutPromptText: String {
        """
        Generate a weekly workout plan for me in JSON format.
        Please structure your response ONLY as valid JSON (no markdown formatting, no extra text) matching this schema:

        {
          "title": "My Weekly Workout Plan",
          "days": [
            {
              "dayName": "Monday",
              "dayOfWeek": 2,
              "title": "Push Day - Chest & Triceps",
              "exercises": [
                {
                  "name": "Barbell Bench Press",
                  "category": "Chest",
                  "targetSets": 4,
                  "targetRepsOrDuration": "8-10 reps",
                  "youtubeUrl": "https://www.youtube.com/watch?v=rT7DgCr-3pg",
                  "notes": "Retract shoulder blades, touch chest gently"
                },
                {
                  "name": "Incline Dumbbell Press",
                  "category": "Chest",
                  "targetSets": 3,
                  "targetRepsOrDuration": "10-12 reps",
                  "youtubeUrl": "https://www.youtube.com/watch?v=8iPEnn-ltC8"
                }
              ]
            },
            {
              "dayName": "Tuesday",
              "dayOfWeek": 3,
              "title": "Pull Day - Back & Biceps",
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

        My Fitness Goal: Build Muscle & Strength
        Split Type: 6-Day Push Pull Legs (or customize as requested)
        Include YouTube exercise tutorial links for proper form.
        """
    }

    private var mealPromptText: String {
        """
        Calculate the macros for the following meal(s) and provide the output ONLY in valid JSON format (no extra text):

        [
          {
            "mealType": "Lunch",
            "title": "Chicken Breast with Rice & Broccoli",
            "details": "200g grilled chicken, 150g cooked white rice, 100g steamed broccoli",
            "calories": 550,
            "proteinGrams": 48.0,
            "carbGrams": 45.0,
            "fatGrams": 12.0
          }
        ]
        """
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                    BrutalistCard(borderColor: AppColor.green) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("🤖 AI WORKOUT & NUTRITION GUIDE")
                                    .font(.system(.subheadline, design: .monospaced).weight(.black))
                                    .foregroundStyle(AppColor.textPrimary)
                                Spacer()
                            }
                            Text("Copy these prompts to ChatGPT, Gemini, or Claude to generate AI-crafted weekly workout plans and meal macro data in seconds!")
                                .font(.system(.caption))
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }

                    // Workout Prompt Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("🏋️ WEEKLY WORKOUT PLAN PROMPT")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppColor.textSecondary)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = workoutPromptText
                                copiedWorkoutPrompt = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedWorkoutPrompt = false
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: copiedWorkoutPrompt ? "checkmark" : "doc.on.doc")
                                    Text(copiedWorkoutPrompt ? "COPIED!" : "COPY PROMPT")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(copiedWorkoutPrompt ? AppColor.green : AppColor.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
                            }
                        }

                        Text(workoutPromptText)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(AppColor.textPrimary)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColor.blank)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1))
                    }

                    // Meal Prompt Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("🥗 MEAL MACRO JSON PROMPT")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppColor.textSecondary)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = mealPromptText
                                copiedMealPrompt = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedMealPrompt = false
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: copiedMealPrompt ? "checkmark" : "doc.on.doc")
                                    Text(copiedMealPrompt ? "COPIED!" : "COPY PROMPT")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(copiedMealPrompt ? AppColor.green : AppColor.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
                            }
                        }

                        Text(mealPromptText)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(AppColor.textPrimary)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColor.blank)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1))
                    }
                }
                .padding(AppLayout.screenMargin)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("AI Prompt Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
    }
}
