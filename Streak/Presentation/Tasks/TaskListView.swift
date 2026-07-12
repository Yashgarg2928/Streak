// Presentation/Tasks/TaskListView.swift

import SwiftUI

struct TaskListView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var vm: TaskViewModel?
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var newTaskTitle: String = ""
    @State private var newTaskCategoryId: UUID? = nil
    @State private var showCategoryPicker: Bool = false

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dateToggle
                    .padding(.horizontal, AppLayout.screenMargin)
                    .padding(.top, AppLayout.itemSpacing)

                taskList

                addTaskBar
                    .padding(.horizontal, AppLayout.screenMargin)
                    .padding(.vertical, AppLayout.itemSpacing)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle(isToday ? "TODAY" : "TOMORROW")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if vm == nil { vm = TaskViewModel(env: env) }
            vm?.load(for: selectedDate)
        }
        .sheet(isPresented: $showCategoryPicker) {
            categoryPickerSheet
                .presentationDetents([.fraction(0.4)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Date toggle

    private var dateToggle: some View {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
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
        let selected = Calendar.current.isDate(selectedDate, inSameDayAs: date)
        return Button {
            selectedDate = date
            vm?.load(for: date)
        } label: {
            Text(title)
                .font(.system(.subheadline).weight(.semibold))
                .foregroundStyle(selected ? AppColor.background : AppColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: AppLayout.minTapTarget)
                .background(selected ? AppColor.border : AppColor.surface)
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
                            categoryColor: vm?.color(for: task)
                        ) {
                            vm?.toggle(taskId: task.id, for: selectedDate)
                        }
                        .listRowBackground(AppColor.background)
                        .listRowSeparatorTint(AppColor.blank)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { i in
                            if let tasks = vm?.tasks {
                                vm?.delete(taskId: tasks[i].id, for: selectedDate)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .background(AppColor.background)
                .scrollContentBackground(.hidden)
            } else {
                Spacer()
                EmptyStateView(message: "No tasks for \(isToday ? "today" : "tomorrow").\nAdd one below.")
                Spacer()
            }
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

        return HStack(spacing: AppLayout.itemSpacing) {
            // Category dot button — opens sheet picker
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

            // Text field
            TextField("Add a task…", text: $newTaskTitle)
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

            // Add button
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
                    // No category row
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
        vm?.addTask(title: newTaskTitle, categoryId: newTaskCategoryId, for: selectedDate)
        newTaskTitle = ""
        newTaskCategoryId = nil
    }
}
