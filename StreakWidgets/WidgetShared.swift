// StreakWidgets/WidgetShared.swift
// Shared colors, helpers, and mini heatmap used across all widgets.

import SwiftUI
import WidgetKit

// MARK: - Colors (duplicated from main app — widgets can't import main target)

enum WColor {
    static let background  = Color(hex: "#F5F0E8")
    static let surface     = Color(hex: "#EFEFDF")
    static let border      = Color(hex: "#1A1A1A")
    static let textPrimary = Color(hex: "#1A1A1A")
    static let textSecondary = Color(hex: "#4A4A4A")
    static let textDisabled  = Color(hex: "#9A9A9A")
    static let green         = Color(hex: "#2D7A2D")
    static let red           = Color(hex: "#C0392B")
    static let blank         = Color(hex: "#D0C9B8")
}

extension Color {
    init(hex: String) {
        let clean = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var rgb: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8)  & 0xFF) / 255
        let b = Double(rgb & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Widget Color Theme for Accented/Tinted Mode (iOS 18)

struct WidgetColorTheme {
    let background: Color
    let surface: Color
    let border: Color
    let textPrimary: Color
    let textSecondary: Color
    let textDisabled: Color
    let blank: Color
    
    static func theme(for mode: WidgetRenderingMode) -> WidgetColorTheme {
        switch mode {
        case .accented, .vibrant:
            return WidgetColorTheme(
                background: .clear,
                surface: Color.white.opacity(0.15),
                border: .white,
                textPrimary: .white,
                textSecondary: .white.opacity(0.7),
                textDisabled: .white.opacity(0.4),
                blank: .white.opacity(0.2)
            )
        default:
            return WidgetColorTheme(
                background: WColor.background,
                surface: WColor.surface,
                border: WColor.border,
                textPrimary: WColor.textPrimary,
                textSecondary: WColor.textSecondary,
                textDisabled: WColor.textDisabled,
                blank: WColor.blank
            )
        }
    }
}

// MARK: - Status dot

struct StatusDot: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let status: String   // "green" | "red" | "future"
    let size: CGFloat

    var color: Color {
        let theme = WidgetColorTheme.theme(for: renderingMode)
        switch status {
        case "green":
            return renderingMode == .fullColor ? WColor.green : .white
        case "red":
            return renderingMode == .fullColor ? WColor.red : .white.opacity(0.5)
        default:
            return theme.blank
        }
    }

    var body: some View {
        Circle().fill(color).frame(width: size, height: size)
    }
}

// MARK: - Mini heatmap (last 4 weeks, 7 rows × 4 cols)

struct MiniHeatmap: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let recentDays: [String: String]
    var categoryColor: Color = WColor.green

    private let cols = 8
    private let rows = 7
    private let cell: CGFloat = 7
    private let gap:  CGFloat = 2

    static let keyFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    var body: some View {
        HStack(spacing: gap) {
            ForEach(0..<cols, id: \.self) { col in
                VStack(spacing: gap) {
                    ForEach(0..<rows, id: \.self) { row in
                        let date = dateFor(col: col, row: row)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(cellColor(for: date))
                            .frame(width: cell, height: cell)
                    }
                }
            }
        }
    }

    private func cellColor(for date: Date) -> Color {
        let today = Calendar.current.startOfDay(for: Date())
        let day   = Calendar.current.startOfDay(for: date)
        if day > today { return Color.clear }
        let key = Self.keyFmt.string(from: day)
        
        switch recentDays[key] {
        case "green":
            return renderingMode == .fullColor ? WColor.green : .white
        case "red":
            return renderingMode == .fullColor ? WColor.red : .white.opacity(0.3)
        default:
            return renderingMode == .fullColor ? WColor.blank.opacity(0.4) : .white.opacity(0.1)
        }
    }

    private func dateFor(col: Int, row: Int) -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        let thisMonday = cal.date(byAdding: .day, value: -daysFromMonday, to: today)!
        let weekOffset = cols - 1 - col
        let weekStart = cal.date(byAdding: .day, value: -weekOffset * 7, to: thisMonday)!
        return cal.date(byAdding: .day, value: row, to: weekStart)!
    }
}

// MARK: - Streak label

struct WStreakLabel: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    let count: Int
    var size: Font = .title2

    var body: some View {
        let theme = WidgetColorTheme.theme(for: renderingMode)
        HStack(spacing: 3) {
            Text("🔥").font(.system(size: 14))
            Text("\(count)")
                .font(size.weight(.heavy))
                .foregroundStyle(theme.textPrimary)
        }
    }
}
