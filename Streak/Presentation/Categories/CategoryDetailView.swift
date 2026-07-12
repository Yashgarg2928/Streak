// Presentation/Categories/CategoryDetailView.swift

import SwiftUI

struct CategoryDetailView: View {
    let categoryId: UUID
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    @State private var vm: CategoryViewModel?

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                if let cat = vm?.category {

                    // Streak badge
                    StreakBadgeView(count: vm?.streak ?? 0, color: cat.color)

                    // Full consistency calendar — no clipping, full height
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CONSISTENCY")
                            .font(.system(.caption).weight(.semibold))
                            .foregroundStyle(AppColor.textSecondary)

                        BrutalistCard(borderColor: cat.color) {
                            ConsistencyGridView(
                                entries: vm?.entries ?? [:],
                                categoryColor: cat.color
                            )
                        }
                    }

                    // Linked goals
                    if let goals = vm?.linkedGoals, !goals.isEmpty {
                        VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                            Text("LINKED GOALS")
                                .font(.system(.caption).weight(.semibold))
                                .foregroundStyle(AppColor.textSecondary)

                            ForEach(goals) { goal in
                                BrutalistCard(borderColor: cat.color) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(goal.title)
                                            .font(.system(.body).weight(.medium))
                                            .foregroundStyle(AppColor.textPrimary)
                                        ProgressBarView(
                                            fraction: goal.progressFraction,
                                            label: "\(Int(goal.currentValue)) / \(Int(goal.targetValue)) \(goal.unit)",
                                            fillColor: cat.color
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Task history
                    taskHistorySection(cat: cat)

                } else {
                    EmptyStateView(message: "Category not found.")
                }
            }
            .padding(.horizontal, AppLayout.screenMargin)
            .padding(.vertical, AppLayout.sectionSpacing)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle(vm?.category?.name.uppercased() ?? "")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit") { router.present(.editCategory(categoryId)) }
                    Button("Archive", role: .destructive) { vm?.archive() }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(AppColor.textPrimary)
                        .frame(minWidth: AppLayout.minTapTarget, minHeight: AppLayout.minTapTarget)
                }
            }
        }
        .onAppear {
            if vm == nil { vm = CategoryViewModel(env: env) }
            vm?.load(categoryId: categoryId)
        }
    }

    // MARK: - Task history section

    @ViewBuilder
    private func taskHistorySection(cat: Category) -> some View {
        let dates = vm?.historyDates ?? []

        VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
            Text("HISTORY")
                .font(.system(.caption).weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)

            if dates.isEmpty {
                EmptyStateView(message: "No tasks yet for this category.")
            } else {
                ForEach(dates, id: \.self) { date in
                    let tasks = vm?.taskHistory[date] ?? []
                    let status = vm?.entries[date]

                    BrutalistCard(borderColor: dayBorderColor(status: status, cat: cat)) {
                        VStack(alignment: .leading, spacing: 8) {
                            // Date header + status dot
                            HStack {
                                Text(dateFormatter.string(from: date).uppercased())
                                    .font(.system(.caption).weight(.semibold))
                                    .foregroundStyle(AppColor.textSecondary)
                                Spacer()
                                Circle()
                                    .fill(statusDotColor(status: status, cat: cat))
                                    .frame(width: 8, height: 8)
                            }

                            // Tasks for this date
                            ForEach(tasks) { task in
                                HStack(spacing: 8) {
                                    Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 16))
                                        .foregroundStyle(task.isCompleted ? AppColor.green : AppColor.textDisabled)
                                    Text(task.title)
                                        .font(.system(.subheadline))
                                        .foregroundStyle(task.isCompleted ? AppColor.textSecondary : AppColor.textPrimary)
                                        .strikethrough(task.isCompleted, color: AppColor.textDisabled)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func dayBorderColor(status: DayStatus?, cat: Category) -> Color {
        switch status {
        case .green: return cat.color
        case .red:   return AppColor.red
        default:     return AppColor.border
        }
    }

    private func statusDotColor(status: DayStatus?, cat: Category) -> Color {
        switch status {
        case .green: return AppColor.green
        case .red:   return AppColor.red
        default:     return AppColor.blank
        }
    }
}
