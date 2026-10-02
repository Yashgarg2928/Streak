// Presentation/Finance/ShortcutsSetupGuideSheet.swift

import SwiftUI

struct ShortcutsSetupGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    init() {}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Banner
                    BrutalistCard {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text("⚡")
                                    .font(.system(size: 24))
                                Text("INSTANT PAYMENT TRACKING")
                                    .font(.system(size: 15, weight: .black, design: .monospaced))
                                    .foregroundStyle(AppColor.textPrimary)
                            }
                            Text("Track expenses directly from the top of your iPhone screen without opening the Streak app.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }

                    // Feature 1: Auto-popup on closing payment apps
                    guideCard(
                        stepNumber: "1",
                        badge: "AUTO POP-UP",
                        badgeColor: "#E67E22",
                        title: "Prompt When Closing Payment Apps",
                        description: "Whenever you pay with Google Pay, Paytm, PhonePe, CRED, or Bank apps, a popup automatically drops from the top of your screen asking for the amount!",
                        steps: [
                            "Open the Apple **Shortcuts** app on your iPhone.",
                            "Tap the **Automation** tab at the bottom, then tap **+** (New Automation).",
                            "Choose **App** from the list of triggers.",
                            "Tap **Choose** and select all your payment apps: *Google Pay, Paytm, PhonePe, CRED, etc.*",
                            "Check **Is Closed** (uncheck 'Is Opened').",
                            "Select **Run Immediately** (turn off 'Notify When Run').",
                            "Tap **Next**, then choose **Quick Log Expense** from Streak."
                        ]
                    )

                    // Feature 2: Double-Tap Back of iPhone (Back Tap)
                    guideCard(
                        stepNumber: "2",
                        badge: "DOUBLE-TAP",
                        badgeColor: "#2980B9",
                        title: "Double-Tap Back of iPhone (Back Tap)",
                        description: "Double-tap the back of your phone at any time to open the payment input window at the top of your screen.",
                        steps: [
                            "Open iPhone **Settings** > **Accessibility**.",
                            "Tap **Touch** > scroll down to **Back Tap**.",
                            "Select **Double Tap** (or Triple Tap).",
                            "Scroll down to the **Shortcuts** section and select **Log Expense** or **Quick Expense**.",
                            "Now, whenever you double-tap the back of your iPhone, the top input banner will instantly open!"
                        ]
                    )

                    // Feature 3: Action Button (iPhone 15 Pro / 16 / 17)
                    guideCard(
                        stepNumber: "3",
                        badge: "ACTION BUTTON",
                        badgeColor: "#27AE60",
                        title: "iPhone Action Button",
                        description: "If your iPhone has an Action Button, you can log expenses with a single press.",
                        steps: [
                            "Open iPhone **Settings** > **Action Button**.",
                            "Swipe across to the **Shortcut** option.",
                            "Tap the selector and pick **Log Expense in Streak**.",
                            "Press and hold the Action button anytime to log an expense!"
                        ]
                    )

                    // Done Button
                    Button {
                        dismiss()
                    } label: {
                        Text("GOT IT, CLOSE GUIDE")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColor.border)
                            .foregroundStyle(AppColor.background)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.vertical, AppLayout.sectionSpacing)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("SHORTCUTS & AUTOMATION")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
    }

    private func guideCard(
        stepNumber: String,
        badge: String,
        badgeColor: String,
        title: String,
        description: String,
        steps: [String]
    ) -> some View {
        BrutalistCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text(badge)
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(hex: badgeColor))
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Spacer()

                    Text("METHOD \(stepNumber)")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(AppColor.textSecondary)
                }

                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppColor.textPrimary)

                Text(description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColor.textSecondary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundStyle(AppColor.textPrimary)
                            Text(.init(step))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppColor.textPrimary)
                        }
                    }
                }
                .padding(10)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
            }
        }
    }
}
