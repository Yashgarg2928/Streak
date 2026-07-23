// Presentation/SharedComponents/DesignTokens.swift
// Single source of truth for all Neo-Brutalist design values.

import SwiftUI

import UIKit

enum AppColor {
    static let background = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#121212")) : UIColor(Color(hex: "#F5F0E8"))
    })

    static let surface = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#1E1E1E")) : UIColor(Color(hex: "#EFEFDF"))
    })

    static let border = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#F5F0E8")) : UIColor(Color(hex: "#1A1A1A"))
    })

    static let textPrimary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#F5F0E8")) : UIColor(Color(hex: "#1A1A1A"))
    })

    static let textSecondary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#A0A0A0")) : UIColor(Color(hex: "#4A4A4A"))
    })

    static let textDisabled = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#666666")) : UIColor(Color(hex: "#9A9A9A"))
    })

    static let green = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#34C759")) : UIColor(Color(hex: "#2D7A2D"))
    })

    static let red = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#FF3B30")) : UIColor(Color(hex: "#C0392B"))
    })

    static let blank = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#2C2C2E")) : UIColor(Color(hex: "#D0C9B8"))
    })

    static let neutralDot = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#999999")) : UIColor(Color(hex: "#8A8A8A"))
    })
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
