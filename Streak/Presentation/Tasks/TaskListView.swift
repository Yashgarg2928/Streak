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
            AddHabitRoutineSheet(categories: vm?.categories ?? []) { title, categoryId, type, startDate, endDate in
                vm?.addHabitRoutine(
                    title: title,
                    categoryId: categoryId,
                    type: type,
                    startDate: startDate,
                    endDate: endDate,
                    for: selectedDate ?? activeToday
                )
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
        let dateString: String = {
            let f = DateFormatter()
            f.dateFormat = "EEE, MMM d"
            return f.string(from: date)
        }()
        return Button {
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
                            onScheduleToday: selectedTab == .backlog ? {
                                vm?.promoteToDaily(
                                    taskId: task.id,
                                    targetDate: activeToday,
                                    currentTab: selectedTab,
                                    for: selectedDate ?? activeToday
                                )
                            } : nil,
                            onScheduleTomorrow: selectedTab == .backlog ? {
                                vm?.promoteToDaily(
                                    taskId: task.id,
                                    targetDate: tomorrow,
                                    currentTab: selectedTab,
                                    for: selectedDate ?? activeToday
                                )
                            } : nil
                        )
                        .listRowBackground(AppColor.background)
                        .listRowSeparatorTint(AppColor.blank)
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

            Text("⚠️ Tasks cannot be edited or deleted once created.")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
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
