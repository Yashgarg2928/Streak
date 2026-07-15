// Presentation/Goals/GoalListView.swift
// Displays the list of active/completed goals with progress indicators.

import SwiftUI

struct GoalListView: View {
    let env: AppEnvironment
    @State private var vm: GoalsViewModel
    @State private var showAddSheet = false
    @State private var selectedGoalId: UUID? = nil
    
    init(env: AppEnvironment) {
        self.env = env
        _vm = State(initialValue: GoalsViewModel(env: env))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                    if vm.goals.isEmpty {
                        VStack {
                            Spacer().frame(height: 50)
                            EmptyStateView(message: "No goals created yet. Set one up to start tracking your progress!")
                        }
                    } else {
                        // Active Goals Section
                        let activeGoals = vm.goals.filter { !$0.isCompleted }
                        if !activeGoals.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("ACTIVE GOALS")
                                    .font(.system(.headline).weight(.bold))
                                    .foregroundStyle(AppColor.textSecondary)
                                
                                ForEach(activeGoals) { goal in
                                    goalCard(goal)
                                }
                            }
                        }
                        
                        // Completed Goals Section
                        let completedGoals = vm.goals.filter { $0.isCompleted }
                        if !completedGoals.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("COMPLETED GOALS")
                                    .font(.system(.headline).weight(.bold))
                                    .foregroundStyle(AppColor.textSecondary)
                                    .padding(.top, 10)
                                
                                ForEach(completedGoals) { goal in
                                    goalCard(goal)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.vertical, AppLayout.sectionSpacing)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("GOALS")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .frame(minWidth: AppLayout.minTapTarget, minHeight: AppLayout.minTapTarget)
                }
            }
            .navigationDestination(item: $selectedGoalId) { id in
                GoalDetailView(env: env, goalId: id)
            }
            .sheet(isPresented: $showAddSheet) {
                AddGoalView(env: env, vm: vm)
            }
            .onAppear {
                vm.load()
            }
        }
    }
    
    private func goalCard(_ goal: Goal) -> some View {
        let category = vm.categories.first { $0.id == goal.categoryId }
        let color = category.flatMap { Color(hex: $0.colorHex) } ?? AppColor.border
        
        return Button {
            selectedGoalId = goal.id
        } label: {
            BrutalistCard(borderColor: color) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        CategoryDot(color: color)
                        
                        Text(goal.title.uppercased())
                            .font(.system(.body).weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if goal.isCompleted {
                            Text("COMPLETED")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(AppColor.green)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                    
                    ProgressBarView(
                        fraction: goal.progressFraction,
                        label: "\(formatProgress(goal.currentValue)) / \(formatProgress(goal.targetValue)) \(goal.unit)",
                        fillColor: color
                    )
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func formatProgress(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", val)
        } else {
            return String(format: "%.1f", val)
        }
    }
}
