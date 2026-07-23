// Presentation/Tasks/TaskListView.swift

import SwiftUI

struct TaskListView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var vm: TaskViewModel?
    @State private var selectedTab: TaskTab = .daily
    @State private var selectedDate: Date? = nil
    @State private var newTaskTitle: String = ""
    @State private var newTaskCategoryId: UUID? = nil
    @State private var showCategoryPicker: Bool = false

    private var activeToday: Date {
        ActiveDayResolver.resolveActiveDate(for: Date(), settings: env.settingsRepository)
    }

    private var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: activeToday)!
    }

    private var isToday: Bool {
        let currentSelected = selectedDate ?? activeToday
        return Calendar.current.isDate(currentSelected, inSameDayAs: activeToday)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mainTabControl
                    .padding(.horizontal, AppLayout.screenMargin)
                    .padding(.top, AppLayout.itemSpacing)

                switch selectedTab {
                case .daily:
                    ActiveDayCountdownView(settings: env.settingsRepository)
                        .padding(.horizontal, AppLayout.screenMargin)
                        .padding(.top, AppLayout.itemSpacing)
                    
                    dateToggle
                        .padding(.horizontal, AppLayout.screenMargin)
                        .padding(.top, AppLayout.itemSpacing)
                case .weekly:
                    weeklyHeaderCard
                        .padding(.horizontal, AppLayout.screenMargin)
                        .padding(.top, AppLayout.itemSpacing)
                case .monthly:
                    monthlyHeaderCard
                        .padding(.horizontal, AppLayout.screenMargin)
                        .padding(.top, AppLayout.itemSpacing)
                case .backlog:
                    backlogHeaderCard
                        .padding(.horizontal, AppLayout.screenMargin)
                        .padding(.top, AppLayout.itemSpacing)
                }

                taskList

                addTaskBar
                    .padding(.horizontal, AppLayout.screenMargin)
                    .padding(.vertical, AppLayout.itemSpacing)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle(navigationTitleString)
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            let today = activeToday
            if selectedDate == nil { selectedDate = today }
            if vm == nil { vm = TaskViewModel(env: env) }
            vm?.load(tab: selectedTab, for: selectedDate ?? today)
        }
        .sheet(isPresented: $showCategoryPicker) {
            categoryPickerSheet
                .presentationDetents([.fraction(0.4)])
                .presentationDragIndicator(.visible)
        }
    }

    private var navigationTitleString: String {
        switch selectedTab {
        case .daily:
            return isToday ? "TODAY" : "TOMORROW"
        case .weekly:
            return "WEEKLY PLAN"
        case .monthly:
            return "MONTHLY PLAN"
        case .backlog:
            return "TO-DO LIST"
        }
    }

    // MARK: - Main Tab Control

    private var mainTabControl: some View {
        HStack(spacing: 0) {
            ForEach(TaskTab.allCases) { tab in
                Button {
                    selectedTab = tab
                    vm?.load(tab: tab, for: selectedDate ?? activeToday)
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(selectedTab == tab ? AppColor.background : AppColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(selectedTab == tab ? AppColor.border : AppColor.surface)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
    }

    // MARK: - Date toggle for Daily tab

    private var dateToggle: some View {
        let today = activeToday
        return HStack(spacing: 0) {
            toggleButton(title: "TODAY",    date: today)
            toggleButton(title: "TOMORROW", date: tomorrow)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
    }

    private func toggleButton(title: String, date: Date) -> some View {
        let selected = Calendar.current.isDate(selectedDate ?? activeToday, inSameDayAs: date)
        return Button {
            selectedDate = date
            vm?.load(tab: .daily, for: date)
        } label: {
            Text(title)
                .font(.system(.subheadline).weight(.semibold))
                .foregroundStyle(selected ? AppColor.background : AppColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: AppLayout.minTapTarget)
                .background(selected ? AppColor.border : AppColor.surface)
        }
    }

    // MARK: - Header Cards for Non-Daily Tabs

    private var weeklyHeaderCard: some View {
        let activeTasks = (vm?.tasks ?? []).filter { !$0.isDeleted }
        let completedCount = activeTasks.filter { $0.isCompleted }.count
        let totalCount = activeTasks.count
        let fraction = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
        
        return BrutalistCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("THIS WEEK")
                            .font(.system(.headline).weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)
                        Text("Weekly Goals & Tasks")
                            .font(.system(.caption).weight(.medium))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Spacer()
                    Text("\(completedCount)/\(totalCount) DONE")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColor.border)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                ProgressBarView(
                    fraction: fraction,
                    label: "\(Int(fraction * 100))% Weekly Progress",
                    fillColor: AppColor.green
                )
            }
        }
    }

    private var monthlyHeaderCard: some View {
        let activeTasks = (vm?.tasks ?? []).filter { !$0.isDeleted }
        let completedCount = activeTasks.filter { $0.isCompleted }.count
        let totalCount = activeTasks.count
        let fraction = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM yyyy"
        let monthString = monthFormatter.string(from: Date()).uppercased()
        
        return BrutalistCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(monthString)
                            .font(.system(.headline).weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)
                        Text("Monthly Call & Major Targets")
                            .font(.system(.caption).weight(.medium))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Spacer()
                    Text("\(completedCount)/\(totalCount) DONE")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColor.border)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                ProgressBarView(
                    fraction: fraction,
                    label: "\(Int(fraction * 100))% Monthly Progress",
                    fillColor: AppColor.green
                )
            }
        }
    }

    private var backlogHeaderCard: some View {
        let activeTasks = (vm?.tasks ?? []).filter { !$0.isDeleted }
        let count = activeTasks.filter { !$0.isCompleted }.count
        
        return BrutalistCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TO-DO LIST")
                        .font(.system(.headline).weight(.bold))
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Timeline-free reminders & backlog ideas")
                        .font(.system(.caption).weight(.medium))
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                Text("\(count) PENDING")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColor.textSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    // MARK: - Task list

    private var taskList: some View {
        Group {
            if let tasks = vm?.tasks, !tasks.isEmpty {
                List {
                    ForEach(tasks) { task in
                        TaskRowView(
                            task: task,
                            categoryColor: vm?.color(for: task),
                            onToggle: {
                                vm?.toggle(taskId: task.id, tab: selectedTab, for: selectedDate ?? activeToday)
                            },
                            onScheduleToday: selectedTab == .daily ? nil : {
                                vm?.scheduleTask(taskId: task.id, to: activeToday, timeframe: .daily, tab: selectedTab, for: selectedDate ?? activeToday)
                            },
                            onScheduleTomorrow: selectedTab == .daily ? nil : {
                                vm?.scheduleTask(taskId: task.id, to: tomorrow, timeframe: .daily, tab: selectedTab, for: selectedDate ?? activeToday)
                            },
                            onMoveToTimeframe: { targetTimeframe in
                                vm?.scheduleTask(taskId: task.id, to: activeToday, timeframe: targetTimeframe, tab: selectedTab, for: selectedDate ?? activeToday)
                            }
                        )
                        .listRowBackground(AppColor.background)
                        .listRowSeparatorTint(AppColor.blank)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { i in
                            if let tasks = vm?.tasks {
                                vm?.delete(taskId: tasks[i].id, tab: selectedTab, for: selectedDate ?? activeToday)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .background(AppColor.background)
                .scrollContentBackground(.hidden)
            } else {
                Spacer()
                EmptyStateView(message: emptyStateMessage)
                Spacer()
            }
        }
    }

    private var emptyStateMessage: String {
        switch selectedTab {
        case .daily:
            return "No tasks for \(isToday ? "today" : "tomorrow").\nAdd one below."
        case .weekly:
            return "No tasks set for this week.\nAdd your weekly goals below."
        case .monthly:
            return "No tasks set for this month.\nAdd your monthly targets below."
        case .backlog:
            return "Your To-Do list is empty.\nAdd any task or reminder below."
        }
    }

    // MARK: - Add task bar

    private var addTaskBar: some View {
        let categories = vm?.categories ?? []
        let dotColor: Color = {
            guard let id = newTaskCategoryId,
                  let cat = categories.first(where: { $0.id == id }) else {
                return AppColor.neutralDot
            }
            return cat.color
        }()

        let placeholder: String = {
            switch selectedTab {
            case .daily: return "Add a daily task…"
            case .weekly: return "Add a weekly goal/task…"
            case .monthly: return "Add a monthly goal/task…"
            case .backlog: return "Add to To-Do list…"
            }
        }()

        return HStack(spacing: AppLayout.itemSpacing) {
            Button { showCategoryPicker = true } label: {
                CategoryDot(color: dotColor)
                    .frame(width: AppLayout.minTapTarget, height: AppLayout.minTapTarget)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                            .stroke(
                                newTaskCategoryId != nil ? dotColor : AppColor.border,
                                lineWidth: AppLayout.borderWidth
                            )
                    )
            }
            .buttonStyle(.plain)

            TextField(placeholder, text: $newTaskTitle)
                .font(.system(.body))
                .foregroundStyle(AppColor.textPrimary)
                .frame(minHeight: AppLayout.minTapTarget)
                .padding(.horizontal, 10)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
                )
                .onSubmit { addTask() }

            Button { addTask() } label: {
                Image(systemName: "plus")
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.background)
                    .frame(width: AppLayout.minTapTarget, height: AppLayout.minTapTarget)
                    .background(AppColor.border)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Category picker sheet

    private var categoryPickerSheet: some View {
        let categories = vm?.categories ?? []
        return VStack(alignment: .leading, spacing: 0) {
            Text("CATEGORY")
                .font(.system(.caption).weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.top, 20)
                .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 0) {
                    categoryRow(
                        color: AppColor.neutralDot,
                        name: "No category",
                        isSelected: newTaskCategoryId == nil
                    ) {
                        newTaskCategoryId = nil
                        showCategoryPicker = false
                    }

                    Divider().padding(.leading, 52)

                    ForEach(categories) { cat in
                        categoryRow(
                            color: cat.color,
                            name: cat.name,
                            isSelected: newTaskCategoryId == cat.id
                        ) {
                            newTaskCategoryId = cat.id
                            showCategoryPicker = false
                        }
                        if cat.id != categories.last?.id {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
            )
            .padding(.horizontal, AppLayout.screenMargin)
            .padding(.bottom, 20)
        }
        .background(AppColor.background.ignoresSafeArea())
    }

    private func categoryRow(color: Color, name: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(color)
                    .frame(width: 14, height: 14)
                    .padding(.leading, AppLayout.screenMargin)

                Text(name)
                    .font(.system(.body).weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(AppColor.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(.subheadline).weight(.semibold))
                        .foregroundStyle(AppColor.textPrimary)
                        .padding(.trailing, AppLayout.screenMargin)
                }
            }
            .frame(minHeight: AppLayout.minTapTarget)
            .background(AppColor.surface)
        }
        .buttonStyle(.plain)
    }

    private func addTask() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let timeframe: TaskTimeframe
        switch selectedTab {
        case .daily: timeframe = .daily
        case .weekly: timeframe = .weekly
        case .monthly: timeframe = .monthly
        case .backlog: timeframe = .backlog
        }
        
        vm?.addTask(
            title: newTaskTitle,
            categoryId: newTaskCategoryId,
            timeframe: timeframe,
            for: selectedDate ?? activeToday
        )
        newTaskTitle = ""
        newTaskCategoryId = nil
    }
}
