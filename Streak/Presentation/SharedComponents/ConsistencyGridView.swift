// Presentation/SharedComponents/ConsistencyGridView.swift
// Two months side by side per page. Uses "yyyy-MM-dd" string keys to avoid
// timezone/precision issues with Date comparison.

import SwiftUI

struct ConsistencyGridView: View {
    // Key: "yyyy-MM-dd" local date string → DayStatus
    let entries: [String: DayStatus]
    var categoryColor: Color? = nil

    // Convenience init that accepts [Date: DayStatus] and converts keys
    init(entries: [Date: DayStatus], categoryColor: Color? = nil) {
        let fmt = Self.keyFormatter
        var converted: [String: DayStatus] = [:]
        for (date, status) in entries {
            converted[fmt.string(from: date)] = status
        }
        self.entries = converted
        self.categoryColor = categoryColor
    }

    // Direct string-key init (used internally / for previews)
    init(stringEntries: [String: DayStatus], categoryColor: Color? = nil) {
        self.entries = stringEntries
        self.categoryColor = categoryColor
    }

    static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private let totalPages = 6
    @State private var currentPage: Int = 5

    private let cell = AppLayout.heatmapCell
    private let gap  = AppLayout.heatmapGap

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(0..<totalPages, id: \.self) { page in
                HStack(alignment: .top, spacing: 16) {
                    monthColumn(for: monthDate(page: page, slot: 0))
                    Divider().background(AppColor.blank)
                    monthColumn(for: monthDate(page: page, slot: 1))
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .tag(page)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: pageHeight())
    }

    // MARK: - Month column

    private func monthColumn(for monthStart: Date) -> some View {
        let cal = Calendar.current
        let days = daysInMonth(for: monthStart)
        let firstWeekday = (cal.component(.weekday, from: monthStart) + 5) % 7
        let totalCells = firstWeekday + days
        let totalRows = Int(ceil(Double(totalCells) / 7.0))
        let dowLabels = ["M","Tu","W","Th","F","Sa","Su"]

        return VStack(alignment: .leading, spacing: 5) {
            Text(monthLabel(for: monthStart))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppColor.textDisabled)
                .lineLimit(1)

            HStack(spacing: gap) {
                ForEach(0..<7, id: \.self) { i in
                    Text(dowLabels[i])
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(AppColor.textDisabled)
                        .frame(width: cell)
                }
            }

            VStack(spacing: gap) {
                ForEach(0..<totalRows, id: \.self) { row in
                    HStack(spacing: gap) {
                        ForEach(0..<7, id: \.self) { col in
                            let dayIndex = row * 7 + col - firstWeekday
                            if dayIndex >= 0 && dayIndex < days {
                                let date = cal.date(byAdding: .day, value: dayIndex, to: monthStart)!
                                cellView(date: date)
                            } else {
                                Color.clear.frame(width: cell, height: cell)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Cell

    private func cellView(date: Date) -> some View {
        let key = Self.keyFormatter.string(from: date)
        let status = entries[key]
        return RoundedRectangle(cornerRadius: 2)
            .fill(fillColor(for: status, date: date))
            .frame(width: cell, height: cell)
            .accessibilityLabel(a11yLabel(status: status, date: date))
    }

    private func fillColor(for status: DayStatus?, date: Date) -> Color {
        let today = Calendar.current.startOfDay(for: Date())
        let day   = Calendar.current.startOfDay(for: date)
        if day > today { return Color.clear }
        switch status {
        case .green:  return categoryColor ?? AppColor.green
        case .red:    return AppColor.red
        default:      return AppColor.blank.opacity(0.35)
        }
    }

    // MARK: - Date helpers

    private func monthDate(page: Int, slot: Int) -> Date {
        let cal = Calendar.current
        let thisMonth = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
        let offset = (page - (totalPages - 1)) * 2 + slot - 1
        return cal.date(byAdding: .month, value: offset, to: thisMonth)!
    }

    private func daysInMonth(for date: Date) -> Int {
        Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    private func monthLabel(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: date).uppercased()
    }

    private func pageHeight() -> CGFloat {
        let label: CGFloat = 16
        let dow: CGFloat = 12
        let rows: CGFloat = 6
        return label + 5 + dow + 5 + (rows * cell) + ((rows - 1) * gap)
    }

    private func a11yLabel(status: DayStatus?, date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        let d = f.string(from: date)
        switch status {
        case .green: return "\(d), completed"
        case .red:   return "\(d), missed"
        default:     return d
        }
    }
}
