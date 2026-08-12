// Presentation/Workout/AddMealSheet.swift

import SwiftUI
import PhotosUI

struct AddMealSheet: View {
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let onSave: (MealLog) -> Void

    @State private var mealType: MealType = .breakfast
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var caloriesStr: String = ""
    @State private var proteinStr: String = ""
    @State private var carbStr: String = ""
    @State private var fatStr: String = ""

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("MEAL DETAILS") {
                    Picker("Meal Category", selection: $mealType) {
                        ForEach(MealType.allCases) { type in
                            Text("\(type.emoji) \(type.rawValue)").tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("Meal Name (e.g. Omelette & Toast)", text: $title)

                    TextField("Details / Ingredients (optional)", text: $details)
                }

                Section("MEAL PHOTO (OPTIONAL)") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .foregroundStyle(AppColor.green)
                            Text(selectedPhotoData == nil ? "Select Meal Photo" : "Change Meal Photo")
                                .font(.system(.subheadline, weight: .bold))
                                .foregroundStyle(AppColor.textPrimary)
                            Spacer()
                            if selectedPhotoData != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppColor.green)
                            }
                        }
                    }

                    if let photoData = selectedPhotoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColor.border, lineWidth: 1))
                    }
                }

                Section("MACRONUTRIENTS") {
                    HStack {
                        Text("🔥 Calories")
                        Spacer()
                        TextField("0", text: $caloriesStr)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kcal")
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    HStack {
                        Text("🥩 Protein")
                        Spacer()
                        TextField("0", text: $proteinStr)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    HStack {
                        Text("🌾 Carbs")
                        Spacer()
                        TextField("0", text: $carbStr)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    HStack {
                        Text("🥑 Fat")
                        Spacer()
                        TextField("0", text: $fatStr)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColor.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Meal") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let meal = MealLog(
                            date: date,
                            mealType: mealType,
                            title: title.trimmingCharacters(in: .whitespaces),
                            details: details.trimmingCharacters(in: .whitespaces),
                            calories: Int(caloriesStr) ?? 0,
                            proteinGrams: Double(proteinStr) ?? 0.0,
                            carbGrams: Double(carbStr) ?? 0.0,
                            fatGrams: Double(fatStr) ?? 0.0,
                            photoData: selectedPhotoData
                        )
                        onSave(meal)
                        dismiss()
                    }
                    .font(.system(.body, weight: .bold))
                    .foregroundStyle(AppColor.green)
                }
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Swift.Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedPhotoData = data
                    }
                }
            }
        }
    }
}
