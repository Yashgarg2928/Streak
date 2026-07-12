// Presentation/SharedComponents/DesignTokens.swift
// Single source of truth for all Neo-Brutalist design values.

import SwiftUI

enum AppColor {
    static let background   = Color(hex: "#F5F0E8")
    static let surface      = Color(hex: "#EFEFDF")
    static let border       = Color(hex: "#1A1A1A")
    static let textPrimary  = Color(hex: "#1A1A1A")
    static let textSecondary = Color(hex: "#4A4A4A")
    static let textDisabled  = Color(hex: "#9A9A9A")
    static let green         = Color(hex: "#2D7A2D")
    static let red           = Color(hex: "#C0392B")
    static let blank         = Color(hex: "#D0C9B8")
    static let neutralDot    = Color(hex: "#8A8A8A")
}

enum AppLayout {
    static let screenMargin:    CGFloat = 16
    static let cardPadding:     CGFloat = 14
    static let borderWidth:     CGFloat = 2.5
    static let cornerRadius:    CGFloat = 6
    static let itemSpacing:     CGFloat = 10
    static let sectionSpacing:  CGFloat = 24
    static let dotSize:         CGFloat = 10
    static let heatmapCell:     CGFloat = 12
    static let heatmapGap:      CGFloat = 3
    static let minTapTarget:    CGFloat = 44
}

// MARK: - Color hex initialiser
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

// MARK: - Category color helper
extension Category {
    var color: Color { Color(hex: colorHex) }
}

// MARK: - DayStatus color
extension DayStatus {
    var color: Color {
        switch self {
        case .green:  return AppColor.green
        case .red:    return AppColor.red
        case .future: return AppColor.blank
        }
    }
}
