// Presentation/Home/OverallDetailView.swift
// Displays overall history line graph (0-100% completion) and lists tasks by category on select.

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
    
    init(env: AppEnvironment) {
        self.env = env
        self.activeDate = ActiveDayResolver.resolveActiveDate(for: Date(), settings: env.settingsRepository)
    }
    
    func load() {
        loadCategories()
        loadDataPoints()
        loadTasksForSelectedDate()
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
            // Fetch all master entries (categoryId == nil)
            let masterEntries = try env.dayEntryRepository.fetchAll(categoryId: nil)
            
            // Find start date (earliest entry) or fallback to today minus 30 days
            let earliestDate = masterEntries.map { $0.date }.min() ?? Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            let startDate = Calendar.current.startOfDay(for: earliestDate)
            let today = activeDate
            
            // Map entries by date for fast lookup
            let entriesMap = Dictionary(uniqueKeysWithValues: masterEntries.map { ($0.date, $0) })
            
            var points: [OverallDataPoint] = []
            var currentDate = startDate
            
            // Generate contiguous list of days
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
}

struct OverallDetailView: View {
    let env: AppEnvironment
    @State private var vm: OverallDetailViewModel
    
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
                    
                    Text("Completion rate across all tasks")
                        .font(.system(.subheadline))
                        .foregroundStyle(AppColor.textSecondary)
                }
                
                // Line Graph Card
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
                        // Group tasks by category
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
                                    // Category Header Row
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
    }
    
    private var selectedDateHeader: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "TASKS FOR \(formatter.string(from: vm.activeDate).uppercased())"
    }
}
