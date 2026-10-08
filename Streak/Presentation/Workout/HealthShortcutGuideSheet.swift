// Presentation/Workout/HealthShortcutGuideSheet.swift
// One-time setup for syncing Apple Health into Streak through a Shortcuts automation.

import SwiftUI

struct HealthShortcutGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    BrutalistCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("APPLE HEALTH → STREAK")
                                .font(.app(size: 15, weight: .black, design: .monospaced))
                                .foregroundStyle(AppColor.textPrimary)
                            Text("Sideloaded apps on a free Apple ID can't read Health directly, so a Shortcuts automation reads it for Streak. You set it up once (about 3 minutes); after that, steps, exercise and workouts arrive on their own and can tick your habits.")
                                .font(.app(size: 13, weight: .medium))
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }

                    ShortcutGuideCard(
                        stepNumber: "1",
                        badge: "BUILD THE SHORTCUT",
                        badgeColor: "#27AE60",
                        title: "Create “Streak Health Sync”",
                        description: "This shortcut adds up today's Health numbers and hands them to Streak.",
                        steps: [
                            "Open **Shortcuts**, tap **+** and name the shortcut **Streak Health Sync**.",
                            "Add **Find Health Samples**. Set *Type* to **Steps** and add the filter **Start Date is Today**.",
                            "Add **Calculate Statistics** and pick **Sum**.",
                            "Repeat the two actions above for **Active Energy** and **Exercise Minutes**.",
                            "Add **Find Health Samples** with *Type* **Workouts** and **Start Date is Today**, then add **Count**.",
                            "Add **Log Health Data in Streak**. Fill each field with the matching result: Steps, Active Energy and Exercise Minutes from the three *Statistics* results, Workouts from *Count*.",
                            "Tap ▶︎ to test it and allow Shortcuts to read Health when asked. You should see “Synced to Streak…”."
                        ]
                    )

                    ShortcutGuideCard(
                        stepNumber: "2",
                        badge: "AUTOMATE IT",
                        badgeColor: "#2980B9",
                        title: "Run it every day",
                        description: "An automation keeps Streak up to date without opening anything.",
                        steps: [
                            "In Shortcuts, open the **Automation** tab and tap **+**.",
                            "Choose **Time of Day**, pick a time 1–2 hours before your day ends, set **Daily**, and select **Run Immediately**.",
                            "Pick **Streak Health Sync** as the shortcut to run.",
                            "Optional: add more automations (e.g. **2:00 PM**, or **Apple Watch Workout → Ends**) so habits tick sooner."
                        ]
                    )

                    ShortcutGuideCard(
                        stepNumber: "3",
                        badge: "LINK HABITS",
                        badgeColor: "#E67E22",
                        title: "Let Health tick your habits",
                        description: "A habit linked to Apple Health is ticked as soon as a sync meets its target. You can still tick it yourself.",
                        steps: [
                            "Go to **Tasks → ⋯ → Habit commitments → +**.",
                            "Under **Auto-complete from Apple Health**, choose a metric and target (e.g. **10,000 steps** or **1 workout**).",
                            "Save. The next sync that meets the target ticks that day's habit."
                        ]
                    )

                    Button {
                        dismiss()
                    } label: {
                        Text("GOT IT, CLOSE GUIDE")
                            .font(.app(size: 13, weight: .black, design: .monospaced))
                            .frame(maxWidth: .infinity, minHeight: AppLayout.minTapTarget)
                            .background(AppColor.border)
                            .foregroundStyle(AppColor.background)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.vertical, AppLayout.sectionSpacing)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("APPLE HEALTH SYNC")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
