// Presentation/Tasks/TaskListView.swift

import SwiftUI

struct TaskListView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var vm: TaskViewModel?
    @State private var selectedTab: TaskTab = .daily
    @State private var selectedDate: Date? = nil
    @State private var newTaskTitle: String = ""
    @State private var newTaskCategoryId: UUID? = nil
    @State private var showRoutineSheet: Bool = false
    @State private var showCategoryPicker: Bool = false
    @State private var isReordering: Bool = false
    @State private var showPastTasksReviewSheet: Bool = false

    private var activeToday: Date {
        ActiveDayResolver.resolveActiveDate(for: Date(), settings: env.settingsRepository)
    }

    private var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: activeToday)!
    }

    private var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: activeToday)!
    }

    private var isToday: Bool {
        let currentSelected = selectedDate ?? activeToday
        return Calendar.current.isDate(currentSelected, inSameDayAs: activeToday)
    }

    private var isYesterday: Bool {
        let currentSelected = selectedDate ?? activeToday
        return Calendar.current.isDate(currentSelected, inSameDayAs: yesterday)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, AppLayout.screenMargin)
                    .padding(.top, AppLayout.itemSpacing)

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

                    lateTaskTemporaryBanner
                        .padding(.horizontal, AppLayout.screenMargin)
                        .padding(.top, AppLayout.itemSpacing)

                    planningDeadlineLockoutBanner
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
            .toolbar(.hidden, for: .navigationBar)
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
        .sheet(isPresented: $showRoutineSheet) {
            ManageHabitRoutinesSheet(categories: vm?.categories ?? []) {
                vm?.load(tab: selectedTab, for: selectedDate ?? activeToday)
            }
        }
        .sheet(isPresented: $showPastTasksReviewSheet) {
            if let vm {
                PastTasksReviewSheet(vm: vm, activeToday: activeToday)
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Text(navigationTitleString)
                .font(.system(.title2, design: .monospaced).weight(.black))
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            if let pastCount = vm?.pastIncompleteTasks.count, pastCount > 0 {
                Button {
                    showPastTasksReviewSheet = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppColor.orange)
                        .frame(width: 30, height: 30)
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                                .stroke(AppColor.orange, lineWidth: AppLayout.borderWidth)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Missed tasks from previous days: \(pastCount)")
            }

            if let count = vm?.tasks.filter({ !$0.isDeleted }).count, count > 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isReordering.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isReordering ? "checkmark" : "arrow.up.arrow.down")
                            .font(.system(size: 11, weight: .bold))
                        Text(isReordering ? "DONE" : "REORDER")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(isReordering ? AppColor.background : AppColor.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(isReordering ? AppColor.textPrimary : AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                            .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
                    )
                }
                .buttonStyle(.plain)
            }

            Button {
                showRoutineSheet = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("HABIT COMMITMENT")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(AppColor.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var navigationTitleString: String {
        switch selectedTab {
        case .daily:
            if isToday { return "TODAY" }
            if isYesterday { return "YESTERDAY" }
            return "TOMORROW"
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
                    isReordering = false
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
        return HStack(spacing: 0) {
            toggleButton(title: "YESTERDAY", date: yesterday)
            toggleButton(title: "TODAY",     date: activeToday)
            toggleButton(title: "TOMORROW",  date: tomorrow)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
    }

    private func toggleButton(title: String, date: Date) -> some View {
        let selected = Calendar.current.isDate(selectedDate ?? activeToday, inSameDayAs: date)
        let dateString: String = {
            let f = DateFormatter()
            f.dateFormat = "EEE, MMM d"
            return f.string(from: date)
        }()
        return Button {
            isReordering = false
            selectedDate = date
            vm?.load(tab: .daily, for: date)
        } label: {
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(.subheadline).weight(.bold))
                    .foregroundStyle(selected ? AppColor.background : AppColor.textPrimary)
                Text(dateString)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(selected ? AppColor.background.opacity(0.75) : AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppLayout.minTapTarget + 10)
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


    // MARK: - Reorder Info Banner

    private var reorderInfoBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColor.textPrimary)
            Text("Drag ≡ or tap chevrons / ︙ to reorder. Syncs to widget.")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(AppColor.border, lineWidth: 1.5)
        )
    }

    // MARK: - Task list

    private var taskList: some View {
        Group {
            if let tasks = vm?.tasks, !tasks.isEmpty {
                VStack(spacing: 6) {
                    if isReordering {
                        reorderInfoBanner
                            .padding(.horizontal, AppLayout.screenMargin)
                            .padding(.top, 4)
                    }

                    List {
                        if selectedTab == .backlog {
                            ForEach(tasks) { task in
                                TaskRowView(
                                    task: task,
                                    categoryColor: vm?.color(for: task),
                                    onToggle: {
                                        vm?.toggle(taskId: task.id, tab: selectedTab, for: selectedDate ?? activeToday)
                                    },
                                    onScheduleToday: {
                                        vm?.promoteToDaily(
                                            taskId: task.id,
                                            targetDate: activeToday,
                                            currentTab: selectedTab,
                                            for: selectedDate ?? activeToday
                                        )
                                    },
                                    onScheduleTomorrow: {
                                        vm?.promoteToDaily(
                                            taskId: task.id,
                                            targetDate: tomorrow,
                                            currentTab: selectedTab,
                                            for: selectedDate ?? activeToday
                                        )
                                    },
                                    onDelete: {
                                        vm?.delete(taskId: task.id, tab: selectedTab, for: selectedDate ?? activeToday)
                                    },
                                    isReordering: isReordering,
                                    onMoveUp: {
                                        vm?.moveTask(taskId: task.id, direction: .up, tab: selectedTab, for: selectedDate ?? activeToday)
                                    },
                                    onMoveDown: {
                                        vm?.moveTask(taskId: task.id, direction: .down, tab: selectedTab, for: selectedDate ?? activeToday)
                                    },
                                    onMoveToTop: {
                                        vm?.moveTask(taskId: task.id, direction: .toTop, tab: selectedTab, for: selectedDate ?? activeToday)
                                    },
                                    onMoveToBottom: {
                                        vm?.moveTask(taskId: task.id, direction: .toBottom, tab: selectedTab, for: selectedDate ?? activeToday)
                                    }
                                )
                                .listRowBackground(AppColor.background)
                                .listRowSeparatorTint(AppColor.blank)
                            }
                            .onDelete { offsets in
                                if let tasks = vm?.tasks {
                                    for index in offsets {
                                        if index < tasks.count {
                                            let task = tasks[index]
                                            vm?.delete(taskId: task.id, tab: selectedTab, for: selectedDate ?? activeToday)
                                        }
                                    }
                                }
                            }
                            .onMove { indices, newOffset in
                                vm?.moveTask(fromOffsets: indices, toOffset: newOffset, tab: selectedTab, for: selectedDate ?? activeToday)
                            }
                        } else {
                            ForEach(tasks) { task in
                                TaskRowView(
                                    task: task,
                                    categoryColor: vm?.color(for: task),
                                    onToggle: {
                                        vm?.toggle(taskId: task.id, tab: selectedTab, for: selectedDate ?? activeToday)
                                    },
                                    onScheduleToday: isYesterday ? {
                                        vm?.movePastTaskToToday(taskId: task.id, currentTab: selectedTab, for: selectedDate ?? activeToday)
                                    } : nil,
                                    onMoveToBacklog: {
                                        vm?.moveToBacklog(taskId: task.id, currentTab: selectedTab, for: selectedDate ?? activeToday)
                                    },
                                    isReordering: isReordering,
                                    onMoveUp: {
                                        vm?.moveTask(taskId: task.id, direction: .up, tab: selectedTab, for: selectedDate ?? activeToday)
                                    },
                                    onMoveDown: {
                                        vm?.moveTask(taskId: task.id, direction: .down, tab: selectedTab, for: selectedDate ?? activeToday)
                                    },
                                    onMoveToTop: {
                                        vm?.moveTask(taskId: task.id, direction: .toTop, tab: selectedTab, for: selectedDate ?? activeToday)
                                    },
                                    onMoveToBottom: {
                                        vm?.moveTask(taskId: task.id, direction: .toBottom, tab: selectedTab, for: selectedDate ?? activeToday)
                                    }
                                )
                                .listRowBackground(AppColor.background)
                                .listRowSeparatorTint(AppColor.blank)
                            }
                            .onMove { indices, newOffset in
                                vm?.moveTask(fromOffsets: indices, toOffset: newOffset, tab: selectedTab, for: selectedDate ?? activeToday)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(AppColor.background)
                    .scrollContentBackground(.hidden)
                    .environment(\.editMode, isReordering ? .constant(.active) : .constant(.inactive))
                }
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
            if isYesterday {
                return "No tasks recorded for yesterday."
            }
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

        return VStack(spacing: 4) {
            HStack(spacing: AppLayout.itemSpacing) {
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

            let deadline = ActiveDayResolver.planningDeadline(for: activeToday, settings: env.settingsRepository)
            let isDeadlinePassed = isToday && selectedTab == .daily && Date() > deadline
            let cutoffStr = ActiveDayResolver.formattedPlanningDeadline(settings: env.settingsRepository)

            if isDeadlinePassed {
                Text("⚠️ Cutoff (\(cutoffStr)) passed: Tasks added now will be marked [ADDED LATE] and cannot save today's streak.")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppColor.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("⚠️ Tasks cannot be edited or deleted once created.")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Temporary Late Task Warning Banner

    @ViewBuilder
    private var lateTaskTemporaryBanner: some View {
        if let warningMsg = vm?.lateTaskWarningMessage {
            BrutalistCard(borderColor: AppColor.red) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppColor.red)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("LATE TASK ADDED")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(AppColor.red)
                        Text(warningMsg)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppColor.textPrimary)
                    }

                    Spacer(minLength: 4)

                    Button {
                        vm?.dismissLateTaskWarning()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Lockout Banner

    @ViewBuilder
    private var planningDeadlineLockoutBanner: some View {
        if isToday {
            let deadline = ActiveDayResolver.planningDeadline(for: activeToday, settings: env.settingsRepository)
            let isDeadlinePassed = Date() > deadline
            let cutoffStr = ActiveDayResolver.formattedPlanningDeadline(settings: env.settingsRepository)
            let tasks = (vm?.tasks ?? []).filter { !$0.isDeleted && $0.timeframe == .daily }
            let earlyTasks = tasks.filter { $0.routineId != nil || $0.createdAt <= deadline }
            
            if isDeadlinePassed && earlyTasks.isEmpty {
                BrutalistCard(borderColor: AppColor.red) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppColor.red)
                            Text("ACTIVE DAY LOCKED (RED STATUS)")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundStyle(AppColor.red)
                        }
                        Text("Planning cutoff (\(cutoffStr)) passed with 0 tasks scheduled. Today is locked as RED. Tasks added now will be marked [ADDED LATE] and cannot save today's streak.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppColor.textPrimary)
                    }
                }
            }
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

// MARK: - Add Habit Routine Sheet

struct AddHabitRoutineSheet: View {
    @Environment(\.dismiss) private var dismiss
    let categories: [Category]
    let onSave: (String, UUID?, HabitRoutineType, Date, Date) -> Void

    @State private var title: String = ""
    @State private var selectedCategoryId: UUID? = nil
    @State private var routineType: HabitRoutineType = .monthlyFixed
    @State private var sprintDays: Int = 7

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Instruction Card
                    BrutalistCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("🔥 DAILY HABIT ROUTINE")
                                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                                .foregroundStyle(AppColor.textPrimary)
                            Text("Build consistency with recurring daily habits (e.g. 2 hrs DSA, hydration, exercise). These automatically appear in your daily task list every day.")
                                .font(.system(.caption))
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }

                    // Habit Name Input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("HABIT NAME")
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textSecondary)

                        TextField("e.g. 2 Hours of DSA, Hydrate 3L, Exercise", text: $title)
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
                    }

                    // Category Selector
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CATEGORY (OPTIONAL)")
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                categoryPill(name: "No Category", color: AppColor.neutralDot, isSelected: selectedCategoryId == nil) {
                                    selectedCategoryId = nil
                                }
                                ForEach(categories) { cat in
                                    categoryPill(name: cat.name, color: cat.color, isSelected: selectedCategoryId == cat.id) {
                                        selectedCategoryId = cat.id
                                    }
                                }
                            }
                        }
                    }

                    // Commitment Type Options
                    VStack(alignment: .leading, spacing: 10) {
                        Text("COMMITMENT TYPE")
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textSecondary)

                        VStack(spacing: 10) {
                            // Monthly Fixed Commitment (Locked)
                            Button {
                                routineType = .monthlyFixed
                            } label: {
                                BrutalistCard(borderColor: routineType == .monthlyFixed ? AppColor.border : AppColor.blank) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text("🔒 ENTIRE MONTH (FIXED & LOCKED)")
                                                .font(.system(size: 11, weight: .black))
                                                .foregroundStyle(AppColor.textPrimary)
                                            Spacer()
                                            if routineType == .monthlyFixed {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(AppColor.green)
                                            }
                                        }
                                        Text("Runs every day for the rest of this month. Once locked, this commitment cannot be edited or deleted.")
                                            .font(.system(.caption))
                                            .foregroundStyle(AppColor.textSecondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            // Custom Habit Sprint
                            Button {
                                routineType = .customRange
                            } label: {
                                BrutalistCard(borderColor: routineType == .customRange ? AppColor.border : AppColor.blank) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text("⚡️ HABIT SPRINT (CUSTOM DAYS)")
                                                .font(.system(size: 11, weight: .black))
                                                .foregroundStyle(AppColor.textPrimary)
                                            Spacer()
                                            if routineType == .customRange {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(AppColor.green)
                                            }
                                        }
                                        Text("Runs every day for a specific timeframe (e.g. 7 days or 14 days).")
                                            .font(.system(.caption))
                                            .foregroundStyle(AppColor.textSecondary)

                                        if routineType == .customRange {
                                            Picker("Duration", selection: $sprintDays) {
                                                Text("7 Days (1 Week)").tag(7)
                                                Text("14 Days (2 Weeks)").tag(14)
                                                Text("30 Days").tag(30)
                                            }
                                            .pickerStyle(.segmented)
                                            .padding(.top, 4)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Save Button
                    BrutalistButton(title: routineType == .monthlyFixed ? "LOCK IN MONTHLY COMMITMENT" : "START HABIT SPRINT") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let today = Date()
                        let endDate = Calendar.current.date(byAdding: .day, value: sprintDays - 1, to: today) ?? today
                        onSave(title, selectedCategoryId, routineType, today, endDate)
                        dismiss()
                    }
                    .padding(.top, 10)
                }
                .padding(AppLayout.screenMargin)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("NEW HABIT ROUTINE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func categoryPill(name: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 10, height: 10)
                Text(name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isSelected ? AppColor.background : AppColor.textPrimary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? AppColor.border : AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AppColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PastTasksReviewSheet

struct PastTasksReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let vm: TaskViewModel
    let activeToday: Date
    @State private var selectedTaskIds: Set<UUID> = []

    private func isSelected(_ id: UUID) -> Bool {
        selectedTaskIds.contains(id)
    }

    private func toggleSelection(_ id: UUID) {
        if selectedTaskIds.contains(id) {
            selectedTaskIds.remove(id)
        } else {
            selectedTaskIds.insert(id)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if vm.pastIncompleteTasks.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(AppColor.green)
                        Text("ALL CAUGHT UP!")
                            .font(.system(.title3, design: .monospaced).weight(.black))
                            .foregroundStyle(AppColor.textPrimary)
                        Text("No unfinished tasks remaining from previous days.")
                            .font(.system(.subheadline))
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    // Header Sub-bar
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DECIDE ON MISSED TASKS")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundStyle(AppColor.textPrimary)
                            Text("Complete past tasks, move to To-Do, or bring to Today.")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        Spacer()
                        Button {
                            if selectedTaskIds.count == vm.pastIncompleteTasks.count {
                                selectedTaskIds.removeAll()
                            } else {
                                selectedTaskIds = Set(vm.pastIncompleteTasks.map { $0.id })
                            }
                        } label: {
                            Text(selectedTaskIds.count == vm.pastIncompleteTasks.count ? "DESELECT ALL" : "SELECT ALL")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(AppColor.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(AppColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppLayout.screenMargin)
                    .padding(.vertical, 10)
                    .background(AppColor.background)

                    Divider().background(AppColor.border)

                    List {
                        ForEach(vm.pastIncompleteTasks) { task in
                            pastTaskCard(task)
                                .listRowBackground(AppColor.background)
                                .listRowSeparatorTint(AppColor.blank)
                        }
                    }
                    .listStyle(.plain)
                    .background(AppColor.background)
                    .scrollContentBackground(.hidden)

                    // Sticky Batch Actions bar
                    if !selectedTaskIds.isEmpty {
                        batchActionBar
                    }
                }
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("PREVIOUS DAYS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .font(.system(.body).weight(.bold))
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
        }
    }

    private func pastTaskCard(_ task: Task) -> some View {
        let selected = isSelected(task.id)
        let catColor = vm.color(for: task) ?? AppColor.neutralDot
        let dateString: String = {
            let cal = Calendar.current
            if cal.isDate(task.targetDate, inSameDayAs: cal.date(byAdding: .day, value: -1, to: activeToday)!) {
                return "YESTERDAY"
            }
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return f.string(from: task.targetDate).uppercased()
        }()

        return BrutalistCard(borderColor: selected ? AppColor.border : AppColor.border.opacity(0.4)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    // Checkbox for batch selection
                    Button {
                        toggleSelection(task.id)
                    } label: {
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(selected ? AppColor.green : AppColor.textSecondary)
                    }
                    .buttonStyle(.plain)

                    Circle()
                        .fill(catColor)
                        .frame(width: 8, height: 8)

                    Text(task.title)
                        .font(.system(.body).weight(.bold))
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(2)

                    Spacer()

                    Text(dateString)
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(AppColor.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(AppColor.orange.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(AppColor.orange.opacity(0.5), lineWidth: 1))
                }

                // 1-Tap Action Pills for individual task
                HStack(spacing: 6) {
                    // Complete task for past date without affecting today
                    Button {
                        vm.completePastTask(taskId: task.id, currentTab: .daily, for: activeToday)
                        selectedTaskIds.remove(task.id)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .black))
                            Text("COMPLETE")
                                .font(.system(size: 9, weight: .black))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(AppColor.green)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    // Move to To-Do List
                    Button {
                        vm.moveToBacklog(taskId: task.id, currentTab: .daily, for: activeToday)
                        selectedTaskIds.remove(task.id)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "tray.and.arrow.down")
                                .font(.system(size: 9, weight: .black))
                            Text("TO-DO")
                                .font(.system(size: 9, weight: .black))
                        }
                        .foregroundStyle(AppColor.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    // Move to Today
                    Button {
                        vm.movePastTaskToToday(taskId: task.id, currentTab: .daily, for: activeToday)
                        selectedTaskIds.remove(task.id)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 9, weight: .black))
                            Text("TODAY")
                                .font(.system(size: 9, weight: .black))
                        }
                        .foregroundStyle(AppColor.background)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(AppColor.border)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.leading, 28)
            }
        }
    }

    private var batchActionBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(selectedTaskIds.count) TASK(S) SELECTED")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
            }

            HStack(spacing: 8) {
                // Batch complete
                Button {
                    let ids = selectedTaskIds
                    selectedTaskIds.removeAll()
                    vm.batchCompletePastTasks(taskIds: ids, currentTab: .daily, for: activeToday)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                        Text("COMPLETE")
                            .font(.system(size: 10, weight: .black))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(AppColor.green)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.border, lineWidth: 1))
                }
                .buttonStyle(.plain)

                // Batch move to To-Do
                Button {
                    let ids = selectedTaskIds
                    selectedTaskIds.removeAll()
                    vm.batchMovePastTasksToBacklog(taskIds: ids, currentTab: .daily, for: activeToday)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "tray.and.arrow.down")
                            .font(.system(size: 10, weight: .black))
                        Text("TO-DO")
                            .font(.system(size: 10, weight: .black))
                    }
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.border, lineWidth: 1))
                }
                .buttonStyle(.plain)

                // Batch move to Today
                Button {
                    let ids = selectedTaskIds
                    selectedTaskIds.removeAll()
                    vm.batchMovePastTasksToToday(taskIds: ids, currentTab: .daily, for: activeToday)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10, weight: .black))
                        Text("TODAY")
                            .font(.system(size: 10, weight: .black))
                    }
                    .foregroundStyle(AppColor.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(AppColor.border)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppLayout.screenMargin)
        .background(AppColor.surface)
        .overlay(
            Rectangle()
                .frame(height: AppLayout.borderWidth)
                .foregroundColor(AppColor.border),
            alignment: .top
        )
    }
}

