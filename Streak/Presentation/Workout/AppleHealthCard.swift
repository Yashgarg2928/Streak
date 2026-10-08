// Presentation/Workout/AppleHealthCard.swift
// Fitness tab card: the day's synced Apple Health totals and the habits they drive.

import SwiftUI

struct AppleHealthCard: View {
    @Environment(AppEnvironment.self) private var env
    let date: Date

    @State private var snapshot: HealthSnapshot? = nil
    @State private var linkedHabits: [HabitRoutine] = []
    @State private var showGuide = false

    var body: some View {
        BrutalistCard(borderColor: Color(hex: "#E74C3C")) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("❤️ APPLE HEALTH")
                            .font(.app(size: 14, weight: .black, design: .monospaced))
                            .foregroundStyle(AppColor.textPrimary)
                        Text(syncLabel)
                            .font(.app(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Spacer()
                    Button {
                        showGuide = true
                    } label: {
                        Text(snapshot == nil ? "SET UP" : "GUIDE")
                            .font(.app(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(AppColor.background)
                            .padding(.horizontal, 12)
                            .frame(minHeight: AppLayout.minTapTarget)
                            .background(AppColor.border)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                    }
                    .buttonStyle(.plain)
                }

                if let snapshot {
                    HStack(spacing: 8) {
                        metric("STEPS", snapshot.steps.formatted())
                        metric("EXERCISE", "\(snapshot.exerciseMinutes) min")
                    }
                    HStack(spacing: 8) {
                        metric("ACTIVE", "\(snapshot.activeEnergyKcal) kcal")
                        metric("WORKOUTS", "\(snapshot.workoutCount)\(snapshot.workoutMinutes > 0 ? " · \(snapshot.workoutMinutes)m" : "")")
                    }
                } else {
                    Text("No Health data for this day yet. Set up the Shortcuts sync once and your steps, exercise and workouts show up here automatically.")
                        .font(.app(size: 12, weight: .medium))
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !linkedHabits.isEmpty {
                    Divider().background(AppColor.border)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("AUTO-TICKED HABITS")
                            .font(.app(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(AppColor.textSecondary)
                        ForEach(linkedHabits) { habit in
                            if let rule = habit.healthRule {
                                let met = snapshot.map { rule.isMet(by: $0) } ?? false
                                HStack(spacing: 8) {
                                    Image(systemName: met ? "checkmark.square.fill" : "square")
                                        .foregroundStyle(met ? AppColor.green : AppColor.textSecondary)
                                    Text(habit.title)
                                        .font(.app(size: 13, weight: .bold))
                                        .foregroundStyle(AppColor.textPrimary)
                                    Spacer()
                                    Text(progressText(rule))
                                        .font(.app(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(met ? AppColor.green : AppColor.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showGuide) {
            HealthShortcutGuideSheet()
        }
        .onAppear(perform: load)
        .onChange(of: date) { load() }
        .onChange(of: env.dataVersion) { load() }
    }

    private var syncLabel: String {
        guard let snapshot else { return "via Shortcuts automation" }
        return "Synced \(snapshot.updatedAt.formatted(date: .omitted, time: .shortened)) via Shortcuts"
    }

    private func progressText(_ rule: HealthRule) -> String {
        let current = snapshot.map { rule.metric.value(in: $0) } ?? 0
        return "\(current.formatted()) / \(rule.target.formatted()) \(rule.metric.unit)"
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.app(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(AppColor.textSecondary)
            Text(value)
                .font(.app(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppColor.background)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: AppLayout.cornerRadius).stroke(AppColor.border, lineWidth: 1.5))
    }

    private func load() {
        snapshot = try? env.healthSnapshotRepository.fetch(date: date)
        linkedHabits = ((try? env.habitRoutineRepository.fetchActive(for: date)) ?? []).filter { $0.healthRule != nil }
    }
}
