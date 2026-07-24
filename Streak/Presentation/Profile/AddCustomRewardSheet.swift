// Presentation/Profile/AddCustomRewardSheet.swift

import SwiftUI

struct AddCustomRewardSheet: View {
    let categories: [Category]
    let onSave: (String, String, UUID?, CustomRewardTier) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var rewardDescription: String = ""
    @State private var selectedCategoryId: UUID? = nil
    @State private var selectedTier: CustomRewardTier = .leisure

    var body: some View {
        NavigationStack {
            Form {
                Section("Reward Details") {
                    TextField("Reward Title (e.g., Weekend Gaming)", text: $title)
                    TextField("Description (optional)", text: $rewardDescription)
                }

                Section("Category Linkage") {
                    Picker("Associated Category", selection: $selectedCategoryId) {
                        Text("OVERALL / ALL CATEGORIES").tag(UUID?.none)
                        ForEach(categories) { cat in
                            HStack {
                                Circle().fill(cat.color).frame(width: 8, height: 8)
                                Text(cat.name.uppercased())
                            }
                            .tag(UUID?.some(cat.id))
                        }
                    }
                }

                Section("Fixed Price Tier") {
                    Picker("Reward Tier", selection: $selectedTier) {
                        ForEach(CustomRewardTier.allCases) { tier in
                            HStack {
                                Text("\(tier.emoji) \(tier.rawValue)")
                                Spacer()
                                Text("\(tier.xpCost) XP")
                            }
                            .tag(tier)
                        }
                    }
                    .pickerStyle(.menu)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("TIER PRICE: \(selectedTier.xpCost) XP")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColor.textPrimary)
                        Text(selectedTier.intendedDescription)
                            .font(.system(size: 11))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("MONTHLY LOCK & PERSISTENCE RULE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(AppColor.textPrimary)

                        Text("Custom rewards configured for this month stay locked during the month and cannot be edited mid-month. Unredeemed rewards do NOT reset next month — they persist until redeemed.")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add Monthly Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Reward") {
                        onSave(title, rewardDescription, selectedCategoryId, selectedTier)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }
}
