// StreakWidgets/MonthlyExpenseWidget.swift
// Shows total personal money spent in the current month.
// Tapping opens the Finance tracker in the main app.

import WidgetKit
import SwiftUI

// MARK: - Entry

struct MonthlyExpenseEntry: TimelineEntry {
    let date: Date
    let totalSpentThisMonth: Double
    let currencySymbol: String
    let monthName: String
    let year: Int
}

// MARK: - Provider

struct MonthlyExpenseProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthlyExpenseEntry {
        let (month, year) = currentMonthAndYear()
        return MonthlyExpenseEntry(
            date: Date(),
            totalSpentThisMonth: 12450.0,
            currencySymbol: "₹",
            monthName: month,
            year: year
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthlyExpenseEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthlyExpenseEntry>) -> Void) {
        let e = entry()
        // Refresh after midnight (to roll over month if month changes) or after 1 hour
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        let nextHour = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? midnight
        let refreshDate = min(midnight, nextHour)
        completion(Timeline(entries: [e], policy: .after(refreshDate)))
    }

    private func entry() -> MonthlyExpenseEntry {
        let data = WidgetDataStore.load()
        let expense = data?.monthlyExpense
        let (fallbackMonth, fallbackYear) = currentMonthAndYear()

        return MonthlyExpenseEntry(
            date: Date(),
            totalSpentThisMonth: expense?.totalSpentThisMonth ?? 0.0,
            currencySymbol: expense?.currencySymbol ?? "₹",
            monthName: expense?.monthName ?? fallbackMonth,
            year: expense?.year ?? fallbackYear
        )
    }

    private func currentMonthAndYear() -> (month: String, year: Int) {
        let now = Date()
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        let month = f.string(from: now).uppercased()
        let year = Calendar.current.component(.year, from: now)
        return (month, year)
    }
}

// MARK: - Helper Formatter

private func formatCurrency(amount: Double, symbol: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = amount.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
    formatter.minimumFractionDigits = 0
    let formattedNum = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount)
    return "\(symbol)\(formattedNum)"
}

// MARK: - Views

// Small widget: Focused, bold, minimal
struct MonthlyExpenseWidgetSmall: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let entry: MonthlyExpenseEntry

    var body: some View {
        let theme = WidgetColorTheme.theme(for: renderingMode)
        let formatted = formatCurrency(amount: entry.totalSpentThisMonth, symbol: entry.currencySymbol)

        VStack(alignment: .leading, spacing: 0) {
            // Month Header Tag
            HStack(spacing: 4) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 9, weight: .bold))
                Text(entry.monthName)
                    .font(.system(size: 9, weight: .black, design: .monospaced))
            }
            .foregroundStyle(theme.textPrimary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(theme.border, lineWidth: 1)
            )

            Spacer()

            // Large Hero Spending Number
            Text(formatted)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.textPrimary)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .allowsTightening(true)

            // Minimalist Label
            Text("SPENT THIS MONTH")
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundStyle(theme.textSecondary)
                .padding(.top, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(URL(string: "streak://finance"))
    }
}

// Medium widget: Clean minimal layout
struct MonthlyExpenseWidgetMedium: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let entry: MonthlyExpenseEntry

    var body: some View {
        let theme = WidgetColorTheme.theme(for: renderingMode)
        let formatted = formatCurrency(amount: entry.totalSpentThisMonth, symbol: entry.currencySymbol)

        HStack(spacing: 16) {
            // Left: Key Metric
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(entry.monthName) \(String(entry.year))")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                }
                .foregroundStyle(theme.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(theme.border, lineWidth: 1)
                )

                Spacer()

                Text(formatted)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .allowsTightening(true)

                Text("SPENT THIS MONTH")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(theme.textSecondary)
                    .padding(.top, 4)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right: Clean Neo-Brutalist card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(renderingMode == .fullColor ? WColor.green : theme.textPrimary)
                    Text("FINANCE")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(theme.textPrimary)
                }

                Text("Personal monthly outflow tracked in Streak.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(2)

                Spacer()

                HStack(spacing: 4) {
                    Text("VIEW LOG")
                        .font(.system(size: 9, weight: .black))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundStyle(theme.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(theme.border, lineWidth: 1)
                )
            }
            .padding(10)
            .frame(maxWidth: 140, maxHeight: .infinity)
            .background(theme.surface.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(theme.border, lineWidth: 1.5)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "streak://finance"))
    }
}

// Lock screen: Rectangular
struct MonthlyExpenseLockRectangular: View {
    let entry: MonthlyExpenseEntry

    var body: some View {
        let formatted = formatCurrency(amount: entry.totalSpentThisMonth, symbol: entry.currencySymbol)
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 9))
                Text("\(entry.monthName) SPENT")
                    .font(.system(size: 9, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(.white)

            Text(formatted)
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .allowsTightening(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(URL(string: "streak://finance"))
    }
}

// Lock screen: Inline
struct MonthlyExpenseLockInline: View {
    let entry: MonthlyExpenseEntry

    var body: some View {
        let formatted = formatCurrency(amount: entry.totalSpentThisMonth, symbol: entry.currencySymbol)
        Text("💳 \(entry.monthName.prefix(3)): \(formatted)")
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .widgetURL(URL(string: "streak://finance"))
    }
}

// Lock screen: Circular
struct MonthlyExpenseLockCircular: View {
    let entry: MonthlyExpenseEntry

    var compactAmount: String {
        if entry.totalSpentThisMonth >= 1_000_000 {
            return String(format: "%.1fM", entry.totalSpentThisMonth / 1_000_000)
        } else if entry.totalSpentThisMonth >= 100_000 {
            return String(format: "%.0fk", entry.totalSpentThisMonth / 1000)
        } else if entry.totalSpentThisMonth >= 1000 {
            return String(format: "%.1fk", entry.totalSpentThisMonth / 1000)
        } else {
            return String(format: "%.0f", entry.totalSpentThisMonth)
        }
    }

    var body: some View {
        VStack(spacing: 1) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 11))
                .foregroundStyle(.white)
            Text("\(entry.currencySymbol)\(compactAmount)")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .allowsTightening(true)
                .foregroundStyle(.white)
            Text(entry.monthName.prefix(3))
                .font(.system(size: 8, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(.white)
        }
        .widgetURL(URL(string: "streak://finance"))
    }
}

// MARK: - Widget Definition

struct MonthlyExpenseWidget: Widget {
    let kind = "MonthlyExpenseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthlyExpenseProvider()) { entry in
            MonthlyExpenseWidgetEntryView(entry: entry)
                .environment(\.colorScheme, .light)
                .containerBackground(WColor.background, for: .widget)
        }
        .configurationDisplayName("Monthly Spending")
        .description("Shows total personal money spent in the current month.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular
        ])
    }
}

struct MonthlyExpenseWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MonthlyExpenseEntry

    var body: some View {
        switch family {
        case .systemSmall:          MonthlyExpenseWidgetSmall(entry: entry)
        case .systemMedium:         MonthlyExpenseWidgetMedium(entry: entry)
        case .accessoryRectangular: MonthlyExpenseLockRectangular(entry: entry)
        case .accessoryInline:      MonthlyExpenseLockInline(entry: entry)
        case .accessoryCircular:    MonthlyExpenseLockCircular(entry: entry)
        default:                    MonthlyExpenseWidgetSmall(entry: entry)
        }
    }
}
