// Presentation/Home/OverallDetailView.swift
// Displays overall history matrix (Daily Tasks x Year Overview) and line graph trend.

import SwiftUI
import Charts

struct OverallDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let percentage: Double // 0.0 to 1.0
}

@Observable
final class OverallDetailViewModel {
    private let env: AppEnvironment
    
    var dataPoints: [OverallDataPoint] = []
    var selectedDate: Date? = nil
    var activeDate: Date
    var tasksForSelectedDate: [Task] = []
    var categoriesMap: [UUID: Category] = [:]
    
    // Habit routines data for matrix
    var routines: [HabitRoutine] = []
    var allDailyTasks: [Task] = []
    
    // Month selector state for matrix view
    var focusedMonth: Date = Date()
    
    // Timeline variables
    var monthsInYear: [Date] = []
    private var weeksByMonth: [Date: [Date]] = [:]
    
    var focusedMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM - yyyy"
        return formatter.string(from: focusedMonth).uppercased()
    }
    
    init(env: AppEnvironment) {
        self.env = env
        self.activeDate = ActiveDayResolver.resolveActiveDate(for: Date(), settings: env.settingsRepository)
        self.focusedMonth = firstDayOfMonth(for: activeDate)
    }
    
    func load() {
        loadCategories()
        loadDataPoints()
        loadTasksForSelectedDate()
        loadRoutinesAndAllTasks()
        generateYearTimeline()
    }
    
    private func loadCategories() {
        do {
            let cats = try env.categoryRepository.fetchAll()
            categoriesMap = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0) })
        } catch {
            print("Failed to load categories: \(error)")
        }
    }
    
    private func loadDataPoints() {
        do {
            let masterEntries = try env.dayEntryRepository.fetchAll(categoryId: nil)
            let earliestDate = masterEntries.map { $0.date }.min() ?? Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            let startDate = Calendar.current.startOfDay(for: earliestDate)
            let today = activeDate
            
            let entriesMap = Dictionary(uniqueKeysWithValues: masterEntries.map { ($0.date, $0) })
            
            var points: [OverallDataPoint] = []
            var currentDate = startDate
            
            while currentDate <= today {
                let percentage: Double
                if let entry = entriesMap[currentDate] {
                    percentage = entry.taskCount > 0 ? Double(entry.completedCount) / Double(entry.taskCount) : 0.0
                } else {
                    percentage = 0.0
                }
                
                points.append(OverallDataPoint(date: currentDate, percentage: percentage))
                
                guard let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = nextDate
            }
            
            self.dataPoints = points
        } catch {
            print("Failed to load overall data points: \(error)")
        }
    }
    
    func loadTasksForSelectedDate() {
        do {
            tasksForSelectedDate = try env.taskRepository.fetchAll(for: activeDate)
        } catch {
            print("Failed to load tasks: \(error)")
        }
    }
    
    private func loadRoutinesAndAllTasks() {
        do {
            routines = try env.habitRoutineRepository.fetchAll()
            allDailyTasks = try env.taskRepository.fetchAll().filter { $0.timeframe == .daily }
        } catch {
            print("Failed to load routines or all tasks: \(error)")
        }
    }
    
    func addHabitRoutine(
        title: String,
        categoryId: UUID?,
        type: HabitRoutineType,
        startDate: Date = Date(),
        endDate: Date = Date()
    ) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            let cal = Calendar.current
            let start: Date
            let end: Date
            let isLocked: Bool
            
            switch type {
            case .monthlyFixed:
                let comps = cal.dateComponents([.year, .month], from: activeDate)
                start = cal.date(from: comps) ?? activeDate
                let range = cal.range(of: .day, in: .month, for: activeDate)?.count ?? 30
                end = cal.date(byAdding: .day, value: range - 1, to: start) ?? activeDate
                isLocked = true
            case .customRange:
                start = cal.startOfDay(for: startDate)
                end = cal.startOfDay(for: endDate)
                isLocked = false
            }
            
            let routine = HabitRoutine(
                title: title,
                categoryId: categoryId,
                type: type,
                startDate: start,
                endDate: end,
                isLocked: isLocked
            )
            try env.habitRoutineRepository.save(routine)
            
            let generator = GenerateRoutineTasksUseCase(
                habitRoutineRepository: env.habitRoutineRepository,
                taskRepository: env.taskRepository
            )
            _ = try generator.execute(for: activeDate)
            
            load()
        } catch {
            print("Failed to add routine: \(error)")
        }
    }
    
    func generateYearTimeline() {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: activeDate)
        
        var months: [Date] = []
        for m in 1...12 {
            var comps = DateComponents()
            comps.year = currentYear
            comps.month = m
            comps.day = 1
            if let monthDate = calendar.date(from: comps) {
                months.append(monthDate)
            }
        }
        self.monthsInYear = months
        
        var weeksMap: [Date: [Date]] = [:]
        
        var comps = DateComponents()
        comps.year = currentYear
        comps.month = 1
        comps.day = 1
        guard var date = calendar.date(from: comps) else { return }
        
        let weekday = calendar.component(.weekday, from: date)
        let daysToSubtract = (weekday - 2 + 7) % 7
        if daysToSubtract > 0 {
            date = calendar.date(byAdding: .day, value: -daysToSubtract, to: date) ?? date
        }
        
        while calendar.component(.year, from: date) <= currentYear {
            let monthStart = firstDayOfMonth(for: date)
            weeksMap[monthStart, default: []].append(date)
            
            guard let nextMonday = calendar.date(byAdding: .day, value: 7, to: date) else { break }
            date = nextMonday
        }
        
        self.weeksByMonth = weeksMap
    }
    
    func weeks(for monthStart: Date) -> [Date] {
        return weeksByMonth[monthStart] ?? []
    }
    
    func firstDayOfMonth(for date: Date) -> Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: date)
        return Calendar.current.date(from: comps) ?? date
    }
    
    func monthAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }
    
    func status(for routine: HabitRoutine, on date: Date) -> DayStatus {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let active = calendar.startOfDay(for: activeDate)
        
        if day > active {
            return .future
        }
        
        let routineStart = calendar.startOfDay(for: routine.startDate)
        let routineEnd = calendar.startOfDay(for: routine.endDate)
        
        guard day >= routineStart, day <= routineEnd else {
            return .future
        }
        
        if let task = allDailyTasks.first(where: { $0.routineId == routine.id && calendar.isDate($0.targetDate, inSameDayAs: day) }) {
            if task.isCompleted {
                return .green
            } else if day < active {
                return .red
            } else {
                return .future
            }
        } else {
            if day < active {
                return .red
            } else {
                return .future
            }
        }
    }
}

struct OverallDetailView: View {
    let env: AppEnvironment
    @State private var vm: OverallDetailViewModel
    @State private var showAddRoutine = false
    
    private let rowHeight: CGFloat = 26
    
    init(env: AppEnvironment) {
        self.env = env
        _vm = State(initialValue: OverallDetailViewModel(env: env))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                // Header Details
                VStack(alignment: .leading, spacing: 6) {
                    Text("OVERALL HISTORY")
                        .font(.system(.title, design: .default).weight(.black))
                        .foregroundStyle(AppColor.textPrimary)
                    
                    Text("Daily tasks and routine consistency overview")
                        .font(.system(.subheadline))
                        .foregroundStyle(AppColor.textSecondary)
                }
                
                // Month Selector Navigation Header
                monthNavigationHeader
                
                // Matrix/Grid Heatmap Card
                BrutalistCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 0) {
                            // Left Column: Task Titles
                            VStack(alignment: .leading, spacing: 0) {
                                // Column header placeholder aligning with month & date row
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("TASKS")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundStyle(AppColor.textSecondary)
                                        .frame(height: 16, alignment: .bottom)
                                    Spacer().frame(height: 14)
                                }
                                .frame(height: 38)
                                .padding(.bottom, 8)
                                
                                Divider()
                                    .background(AppColor.border)
                                
                                ForEach(vm.routines) { routine in
                                    HStack {
                                        Text(routine.title)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(AppColor.textPrimary)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .frame(height: rowHeight)
                                }
                                
                                // [+ Add Task] Button
                                Button {
                                    showAddRoutine = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 8, weight: .black))
                                        Text("ADD HABIT")
                                            .font(.system(size: 8, weight: .black))
                                    }
                                    .foregroundStyle(AppColor.textPrimary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppColor.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(AppColor.border, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                                .frame(height: 32)
                                .padding(.top, 8)
                            }
                            .frame(width: 90)
                            
                            // Vertical Divider
                            Rectangle()
                                .fill(AppColor.border)
                                .frame(width: 2.5)
                                .padding(.vertical, -AppLayout.cardPadding)
                                .padding(.horizontal, 8)
                            
                            // Right Scrollable Grid Area
                            ScrollViewReader { proxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        // Header Row: Months & Dates (Mondays)
                                        HStack(spacing: 8) {
                                            ForEach(vm.monthsInYear, id: \.self) { monthStart in
                                                let weeksInMonth = vm.weeks(for: monthStart)
                                                let width = CGFloat(weeksInMonth.count) * 96 + CGFloat(weeksInMonth.count - 1) * 6
                                                
                                                VStack(alignment: .center, spacing: 4) {
                                                    Text(vm.monthAbbreviation(for: monthStart))
                                                        .font(.system(size: 10, weight: .black, design: .monospaced))
                                                        .foregroundStyle(AppColor.textPrimary)
                                                        .frame(height: 16)
                                                    
                                                    HStack(spacing: 6) {
                                                        ForEach(weeksInMonth, id: \.self) { monday in
                                                            Text("\(Calendar.current.component(.day, from: monday))")
                                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                                .foregroundStyle(AppColor.textSecondary)
                                                                .frame(width: 96, alignment: .center)
                                                        }
                                                    }
                                                    .frame(height: 14)
                                                }
                                                .id(monthStart)
                                                .frame(width: width)
                                            }
                                        }
                                        .padding(.bottom, 8)
                                        
                                        Divider()
                                            .background(AppColor.border)
                                        
                                        // Task rows containing heatmap columns
                                        ForEach(vm.routines) { routine in
                                            HStack(spacing: 8) {
                                                ForEach(vm.monthsInYear, id: \.self) { monthStart in
                                                    let weeksInMonth = vm.weeks(for: monthStart)
                                                    HStack(spacing: 6) {
                                                        ForEach(weeksInMonth, id: \.self) { monday in
                                                            HStack(spacing: 3) {
                                                                ForEach(0..<7) { offset in
                                                                    let date = Calendar.current.date(byAdding: .day, value: offset, to: monday)!
                                                                    let status = vm.status(for: routine, on: date)
                                                                    CellView(date: date, routineTitle: routine.title, status: status)
                                                                }
                                                            }
                                                            .frame(width: 96)
                                                        }
                                                    }
                                                }
                                            }
                                            .frame(height: rowHeight)
                                        }
                                    }
                                }
                                .onAppear {
                                    let currentMonth = vm.firstDayOfMonth(for: vm.activeDate)
                                    proxy.scrollTo(currentMonth, anchor: .center)
                                }
                                .onChange(of: vm.focusedMonth) {
                                    let targetMonth = vm.firstDayOfMonth(for: vm.focusedMonth)
                                    withAnimation {
                                        proxy.scrollTo(targetMonth, anchor: .center)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                            .background(AppColor.border)
                        
                        // Legend
                        HStack(spacing: 16) {
                            LegendItem(color: AppColor.green, label: "Completed")
                            LegendItem(color: AppColor.red, label: "Missed")
                            LegendItem(color: AppColor.blank, label: "Future / No Data")
                        }
                        .padding(.top, 4)
                    }
                }
                
                // Line Graph Card (Overall Progress Trend)
                VStack(alignment: .leading, spacing: 12) {
                    Text("OVERALL TREND")
                        .font(.system(.headline).weight(.bold))
                        .foregroundStyle(AppColor.textPrimary)
                    
                    BrutalistCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("COMPLETION RATE (0% - 100%)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppColor.textSecondary)
                            
                            if vm.dataPoints.isEmpty {
                                Text("No history recorded yet.")
                                    .font(.system(.body))
                                    .foregroundStyle(AppColor.textDisabled)
                                    .frame(height: 200)
                            } else {
                                Chart {
                                    ForEach(vm.dataPoints) { point in
                                        LineMark(
                                            x: .value("Day", point.date, unit: .day),
                                            y: .value("Completion", point.percentage)
                                        )
                                        .foregroundStyle(AppColor.border)
                                        .lineStyle(StrokeStyle(lineWidth: 3))
                                        .interpolationMethod(.monotone)
                                        
                                        PointMark(
                                            x: .value("Day", point.date, unit: .day),
                                            y: .value("Completion", point.percentage)
                                        )
                                        .foregroundStyle(AppColor.border)
                                        .symbolSize(vm.activeDate == point.date ? 120 : 40)
                                    }
                                    
                                    if let selected = vm.selectedDate {
                                        RuleMark(
                                            x: .value("Selected", selected)
                                        )
                                        .foregroundStyle(AppColor.border.opacity(0.3))
                                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [3]))
                                    }
                                }
                                .chartScrollableAxes(.horizontal)
                                .chartXVisibleDomain(length: 3600 * 24 * 30) // Show exactly 1 month
                                .chartXSelection(value: $vm.selectedDate)
                                .chartYScale(domain: 0...1.1)
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day, count: 5)) { value in
                                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1.5, dash: [3]))
                                            .foregroundStyle(AppColor.border.opacity(0.15))
                                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                            .foregroundStyle(AppColor.textSecondary)
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks(values: [0.0, 0.25, 0.5, 0.75, 1.0]) { value in
                                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1.5, dash: [3]))
                                            .foregroundStyle(AppColor.border.opacity(0.15))
                                        AxisValueLabel {
                                            if let val = value.as(Double.self) {
                                                Text("\(Int(val * 100))%")
                                                    .foregroundStyle(AppColor.textSecondary)
                                            }
                                        }
                                    }
                                }
                                .frame(height: 220)
                            }
                        }
                    }
                }
                
                // Tasks for Selected Date
                VStack(alignment: .leading, spacing: 12) {
                    Text(selectedDateHeader)
                        .font(.system(.headline).weight(.bold))
                        .foregroundStyle(AppColor.textPrimary)
                    
                    if vm.tasksForSelectedDate.isEmpty {
                        BrutalistCard {
                            Text("No tasks recorded for this day.")
                                .font(.system(.body))
                                .foregroundStyle(AppColor.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        }
                    } else {
                        let groupedTasks = Dictionary(grouping: vm.tasksForSelectedDate) { $0.categoryId }
                        
                        ForEach(groupedTasks.keys.sorted(by: { (a: UUID?, b: UUID?) -> Bool in
                            let nameA = a.flatMap { vm.categoriesMap[$0]?.name } ?? "Uncategorized"
                            let nameB = b.flatMap { vm.categoriesMap[$0]?.name } ?? "Uncategorized"
                            return nameA < nameB
                        }), id: \.self) { categoryId in
                            let tasks = groupedTasks[categoryId] ?? []
                            let category = categoryId.flatMap { vm.categoriesMap[$0] }
                            
                            BrutalistCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color(hex: category?.colorHex ?? "#9A9A9A"))
                                            .frame(width: 8, height: 8)
                                        
                                        Text(category?.name.uppercased() ?? "UNCATEGORIZED")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(AppColor.textPrimary)
                                    }
                                    .padding(.bottom, 4)
                                    
                                    ForEach(tasks) { task in
                                        HStack(spacing: 10) {
                                            Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                                                .foregroundStyle(task.isCompleted ? AppColor.green : AppColor.textSecondary)
                                                .font(.system(size: 18))
                                            
                                            Text(task.title)
                                                .font(.system(.body))
                                                .foregroundStyle(AppColor.textPrimary)
                                                .strikethrough(task.isCompleted)
                                            
                                            Spacer()
                                        }
                                        .frame(minHeight: 30)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppLayout.screenMargin)
            .padding(.vertical, AppLayout.sectionSpacing)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.load()
        }
        .onChange(of: vm.selectedDate) {
            if let date = vm.selectedDate {
                vm.activeDate = Calendar.current.startOfDay(for: date)
                vm.loadTasksForSelectedDate()
            }
        }
        .sheet(isPresented: $showAddRoutine) {
            AddHabitRoutineSheet(categories: Array(vm.categoriesMap.values).sorted(by: { $0.name < $1.name })) { title, categoryId, type, startDate, endDate in
                vm.addHabitRoutine(
                    title: title,
                    categoryId: categoryId,
                    type: type,
                    startDate: startDate,
                    endDate: endDate
                )
            }
        }
    }
    
    private var monthNavigationHeader: some View {
        HStack {
            Button {
                if let prev = Calendar.current.date(byAdding: .month, value: -1, to: vm.focusedMonth) {
                    vm.focusedMonth = prev
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(8)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppColor.border, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text(vm.focusedMonthString)
                .font(.system(.body, design: .monospaced).weight(.black))
                .foregroundStyle(AppColor.textPrimary)
            
            Spacer()
            
            Button {
                if let next = Calendar.current.date(byAdding: .month, value: 1, to: vm.focusedMonth) {
                    vm.focusedMonth = next
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(8)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppColor.border, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }
    
    private var selectedDateHeader: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "TASKS FOR \(formatter.string(from: vm.activeDate).uppercased())"
    }
}

struct CellView: View {
    let date: Date
    let routineTitle: String
    let status: DayStatus
    @State private var showDetails = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(status.color)
            .frame(width: 12, height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(AppColor.border.opacity(0.15), lineWidth: 0.5)
            )
            .onTapGesture {
                showDetails = true
            }
            .popover(isPresented: $showDetails) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(routineTitle)
                        .font(.system(.headline, design: .monospaced).weight(.bold))
                        .foregroundStyle(AppColor.textPrimary)
                    
                    Text("Date: \(formattedDate)")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(AppColor.textSecondary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(status.color)
                            .frame(width: 8, height: 8)
                        Text(statusText)
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)
                    }
                }
                .padding()
                .presentationDetents([.fraction(0.2)])
            }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private var statusText: String {
        switch status {
        case .green: return "COMPLETED"
        case .red: return "MISSED"
        default: return "NO DATA"
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(AppColor.border.opacity(0.15), lineWidth: 0.5)
                )
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}
