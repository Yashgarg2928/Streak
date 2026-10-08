// Presentation/Home/HomeView.swift
// "Today" screen: what's left today and how much time remains, with tap-to-complete
// tasks, then the overall streak, goals and categories.

import SwiftUI

struct HomeView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    @State private var vm: HomeViewModel?
    @State private var showCheckInSheet: Bool = false
    @State private var showHabitsSheet: Bool = false
    @State private var selectedGoalId: UUID? = nil

    var body: some View {
        @Bindable var router = router
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                    ActiveDayCountdownView(settings: env.settingsRepository)

                    if let vm {
                        todayCard(vm)

                        if vm.needsBackup {
                            backupNudge(vm)
                        }

                        Button {
                            router.showOverallDetail = true
                        } label: {
                            masterCard(vm)
                        }
                        .buttonStyle(.plain)

                        habitsSection(vm)

                        goalsSection(vm)

                        categoriesSection(vm)
                    }
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.vertical, AppLayout.sectionSpacing)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("TODAY")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCheckInSheet) {
                EndOfDayCheckInSheet(date: vm?.today ?? Calendar.current.startOfDay(for: Date()))
            }
            .sheet(isPresented: $showHabitsSheet) {
                ManageHabitRoutinesSheet(categories: vm?.categories ?? []) {
                    vm?.load()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        router.present(.settings)
                    } label: {
                        Image(systemName: "gearshape")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .frame(minWidth: AppLayout.minTapTarget, minHeight: AppLayout.minTapTarget)
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        router.present(.addCategory)
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .frame(minWidth: AppLayout.minTapTarget, minHeight: AppLayout.minTapTarget)
                    .accessibilityLabel("New category")
                }
            }
            .navigationDestination(item: $router.categoryDetailId) { id in
                CategoryDetailView(categoryId: id)
            }
            .navigationDestination(isPresented: $router.showOverallDetail) {
                OverallDetailView(env: env)
            }
            .navigationDestination(isPresented: $router.showGoals) {
                GoalListView(env: env, embedInNavigationStack: false)
            }
            .navigationDestination(item: $selectedGoalId) { id in
                GoalDetailView(env: env, goalId: id)
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { vm?.errorMessage != nil },
                set: { if !$0 { vm?.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { vm?.errorMessage = nil }
            } message: {
                Text(vm?.errorMessage ?? "")
            }
        }
        .onChange(of: env.dataVersion) {
            vm?.load()
        }
        .onChange(of: router.activeSheet) { _, newValue in
            if newValue == nil { vm?.load() }
        }
        .onAppear {
            if vm == nil { vm = HomeViewModel(env: env) }
            vm?.load()
        }
    }

    // MARK: - Today card

    private func todayCard(_ vm: HomeViewModel) -> some View {
        let planned = vm.plannedTasks
        let fraction = planned.isEmpty ? 0 : Double(vm.plannedDoneCount) / Double(planned.count)

        return BrutalistCard(borderColor: vm.todayStatus == .green ? AppColor.green : AppColor.border) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(vm.today.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()).uppercased())
                        .font(.system(.subheadline, design: .monospaced).weight(.bold))
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer()
                    statusChip(vm)
                }

                if !planned.isEmpty {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(vm.plannedDoneCount)")
                            .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                            .foregroundStyle(AppColor.textPrimary)
                        Text("/ \(planned.count) planned done")
                            .font(.system(.subheadline).weight(.semibold))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    ProgressBarView(
                        fraction: fraction,
                        label: progressLabel(vm),
                        fillColor: vm.todayStatus == .green ? AppColor.green : AppColor.border
                    )
                } else {
                    Text(emptyTodayMessage(vm))
                        .font(.system(.subheadline))
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !vm.todayTasks.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(vm.todayTasks) { task in
                            todayTaskRow(task, vm: vm)
                            if task.id != vm.todayTasks.last?.id {
                                Divider().background(AppColor.blank)
                            }
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        router.selectedTab = .tasks
                    } label: {
                        Label(vm.todayTasks.isEmpty ? "PLAN TODAY" : "ADD TASK", systemImage: "plus")
                            .font(.system(.footnote, design: .monospaced).weight(.black))
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: AppLayout.minTapTarget)
                            .background(AppColor.background)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                                    .stroke(AppColor.border, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        showCheckInSheet = true
                    } label: {
                        Label("CHECK-IN", systemImage: "moon.stars")
                            .font(.system(.footnote, design: .monospaced).weight(.black))
                            .foregroundStyle(AppColor.background)
                            .frame(maxWidth: .infinity, minHeight: AppLayout.minTapTarget)
                            .background(AppColor.border)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("End-of-day check-in")
                }
            }
        }
    }

    private func todayTaskRow(_ task: Task, vm: HomeViewModel) -> some View {
        let category = vm.color(for: task.categoryId)
        return Button {
            vm.toggle(task)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(.title3).weight(.medium))
                    .foregroundStyle(task.isCompleted ? AppColor.green : AppColor.textSecondary)
                    .frame(width: 28)
                CategoryDot(color: category?.color ?? AppColor.neutralDot)
                Text(task.title)
                    .font(.system(.body).weight(.medium))
                    .foregroundStyle(task.isCompleted ? AppColor.textDisabled : AppColor.textPrimary)
                    .strikethrough(task.isCompleted, color: AppColor.textDisabled)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 4)
                if vm.isBonus(task) {
                    Text("BONUS")
                        .font(.system(.caption2, design: .monospaced).weight(.black))
                        .foregroundStyle(AppColor.orange)
                } else if vm.isHealthLinked(task) {
                    Image(systemName: "heart.fill")
                        .font(.system(.caption))
                        .foregroundStyle(Color(hex: "#E74C3C"))
                        .accessibilityLabel("Habit commitment, ticked automatically from Apple Health")
                } else if task.routineId != nil {
                    Image(systemName: "flame.fill")
                        .font(.system(.caption))
                        .foregroundStyle(AppColor.textSecondary)
                        .accessibilityLabel("Habit commitment")
                }
            }
            .frame(minHeight: AppLayout.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(task.title), \(task.isCompleted ? "done" : "not done")")
        .accessibilityHint("Double-tap to toggle")
    }

    private func statusChip(_ vm: HomeViewModel) -> some View {
        let (text, color): (String, Color) = {
            switch vm.todayStatus {
            case .green:  return ("DONE ✅", AppColor.green)
            case .red:    return ("LOCKED", AppColor.red)
            case .frozen: return ("PROTECTED ❄️", AppColor.frozen)
            case .rest:   return ("REST DAY", AppColor.rest)
            case .future: return (vm.isRestDay ? "REST DAY" : "IN PROGRESS", vm.isRestDay ? AppColor.rest : AppColor.textSecondary)
            }
        }()
        return Text(text)
            .font(.system(.caption, design: .monospaced).weight(.black))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(color, lineWidth: 1.5))
    }

    private func progressLabel(_ vm: HomeViewModel) -> String {
        let remaining = vm.plannedTasks.count - vm.plannedDoneCount
        if remaining == 0 { return "All planned tasks done. Streak secured." }
        return "\(remaining) left to keep your streak"
    }

    private func emptyTodayMessage(_ vm: HomeViewModel) -> String {
        if vm.isRestDay { return "Rest day. Nothing planned, and your streak is safe." }
        if vm.todayStatus == .red { return "Planning cutoff passed with nothing planned. Today is locked as RED." }
        let cutoff = ActiveDayResolver.formattedPlanningDeadline(settings: env.settingsRepository)
        return "Nothing planned yet. Add at least one task before \(cutoff) or today turns RED."
    }

    // MARK: - Backup nudge

    private func backupNudge(_ vm: HomeViewModel) -> some View {
        Button {
            router.present(.settings)
        } label: {
            BrutalistCard(borderColor: AppColor.orange) {
                HStack(spacing: 10) {
                    Image(systemName: "tray.and.arrow.up.fill")
                        .font(.system(.title3))
                        .foregroundStyle(AppColor.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BACK UP YOUR DATA")
                            .font(.system(.subheadline, design: .monospaced).weight(.black))
                            .foregroundStyle(AppColor.textPrimary)
                        Text(vm.daysSinceBackup.map { "Last backup was \($0) days ago." } ?? "Your streaks only live on this phone. Save a copy to Files.")
                            .font(.system(.caption))
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Master card

    private func masterCard(_ vm: HomeViewModel) -> some View {
        BrutalistCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("OVERALL")
                            .font(.system(.headline).weight(.semibold))
                            .foregroundStyle(AppColor.textPrimary)
                        if vm.streakFreezes > 0 {
                            Text("❄️ \(vm.streakFreezes) freeze\(vm.streakFreezes == 1 ? "" : "s") ready")
                                .font(.system(.caption, design: .monospaced).weight(.bold))
                                .foregroundStyle(AppColor.frozen)
                        }
                    }
                    Spacer()
                    StreakBadgeView(count: vm.masterStreak)
                }
                ConsistencyGridView(entries: vm.masterEntries)
            }
        }
    }

    // MARK: - Habits section

    private func habitsSection(_ vm: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
            HStack {
                Text("HABITS")
                    .font(.system(.subheadline).weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Button {
                    showHabitsSheet = true
                } label: {
                    Text(vm.habits.isEmpty ? "NEW HABIT →" : "MANAGE →")
                        .font(.system(.caption, design: .monospaced).weight(.black))
                        .foregroundStyle(AppColor.textPrimary)
                        .frame(minHeight: AppLayout.minTapTarget)
                }
                .buttonStyle(.plain)
            }

            if vm.habits.isEmpty {
                Text("No habit commitments yet. Habits repeat on the days you choose and keep their own streaks.")
                    .font(.system(.subheadline))
                    .foregroundStyle(AppColor.textDisabled)
            } else {
                Button {
                    showHabitsSheet = true
                } label: {
                    BrutalistCard {
                        VStack(spacing: 10) {
                            ForEach(vm.habits) { habit in
                                habitRow(habit, vm: vm)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func habitRow(_ habit: HabitRoutine, vm: HomeViewModel) -> some View {
        let progress = vm.habitProgress[habit.id]
        return HStack(spacing: 8) {
            CategoryDot(color: vm.color(for: habit.categoryId)?.color ?? AppColor.neutralDot)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(habit.title)
                        .font(.system(.subheadline).weight(.bold))
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                    if habit.healthRule != nil {
                        Image(systemName: "heart.fill")
                            .font(.system(.caption2))
                            .foregroundStyle(Color(hex: "#E74C3C"))
                    }
                }
                if let progress {
                    HabitHistoryStrip(days: progress.recent, size: 10)
                }
            }
            Spacer()
            Text("🔥 \(progress?.streak ?? 0)")
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(AppColor.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Goals section

    private func goalsSection(_ vm: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
            HStack {
                Text("GOALS")
                    .font(.system(.subheadline).weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Button {
                    router.showGoals = true
                } label: {
                    Text(vm.activeGoals.isEmpty ? "NEW GOAL →" : "ALL GOALS →")
                        .font(.system(.caption, design: .monospaced).weight(.black))
                        .foregroundStyle(AppColor.textPrimary)
                        .frame(minHeight: AppLayout.minTapTarget)
                }
                .buttonStyle(.plain)
            }

            if vm.activeGoals.isEmpty {
                Text("No active goals. Set one to track a streak target, a day count or a milestone.")
                    .font(.system(.subheadline))
                    .foregroundStyle(AppColor.textDisabled)
            } else {
                ForEach(vm.activeGoals) { goal in
                    let color = vm.color(for: goal.categoryId)?.color ?? AppColor.border
                    Button {
                        selectedGoalId = goal.id
                    } label: {
                        BrutalistCard(borderColor: color) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(goal.title.uppercased())
                                    .font(.system(.subheadline).weight(.bold))
                                    .foregroundStyle(AppColor.textPrimary)
                                    .lineLimit(2)
                                ProgressBarView(
                                    fraction: goal.progressFraction,
                                    label: "\(formatted(goal.currentValue)) / \(formatted(goal.targetValue)) \(goal.unit)",
                                    fillColor: color
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }

    // MARK: - Categories section

    private func categoriesSection(_ vm: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
            Text("CATEGORIES")
                .font(.system(.subheadline).weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)

            if !vm.categories.isEmpty {
                VStack(spacing: AppLayout.itemSpacing) {
                    ForEach(vm.categories) { category in
                        categoryCard(category, vm: vm)
                    }
                }
            } else {
                EmptyStateView(message: "No categories yet.\nTap + to create one.")
            }
        }
    }

    // MARK: - Category card

    private func categoryCard(_ category: Category, vm: HomeViewModel) -> some View {
        Button {
            router.showCategoryDetail(category.id)
        } label: {
            BrutalistCard(borderColor: category.color) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(category.name.uppercased())
                            .font(.system(.headline).weight(.semibold))
                            .foregroundStyle(AppColor.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        StreakBadgeView(
                            count: vm.categoryStreaks[category.id] ?? 0,
                            color: category.color
                        )
                    }
                    ConsistencyGridView(
                        entries: vm.categoryEntries[category.id] ?? [:],
                        categoryColor: category.color
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.name) category, \(vm.categoryStreaks[category.id] ?? 0) day streak")
    }
}
