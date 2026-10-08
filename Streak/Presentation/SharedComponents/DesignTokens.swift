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

    static let orange = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#FF9F0A")) : UIColor(Color(hex: "#D35400"))
    })

    static let blank = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#2C2C2E")) : UIColor(Color(hex: "#D0C9B8"))
    })

    /// Frozen (streak-freeze protected) day.
    static let frozen = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#64B5F6")) : UIColor(Color(hex: "#2E86C1"))
    })

    /// Scheduled rest day.
    static let rest = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#5C6B7A")) : UIColor(Color(hex: "#A9B7C6"))
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

// MARK: - Typography
// Fixed-size fonts throughout the app go through `.app(size:)`, which scales with the
// user's text-size setting and never drops below a readable minimum.

enum AppFont {
    static let minimumSize: CGFloat = 11
    /// Large accessibility sizes are capped so dense layouts stay usable.
    static let maximumScale: CGFloat = 1.6

    static func scaled(_ size: CGFloat) -> CGFloat {
        let base = max(size, minimumSize)
        return min(UIFontMetrics.default.scaledValue(for: base), base * maximumScale)
    }
}

extension Font {
    static func app(size: CGFloat, weight: Font.Weight? = nil, design: Font.Design? = nil) -> Font {
        .system(size: AppFont.scaled(size), weight: weight, design: design)
    }
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
        case .rest:   return AppColor.rest
        case .frozen: return AppColor.frozen
        }
    }
}

// MARK: - Global Keyboard Dismissal
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension UIApplication {
    func addTapGestureToDismissKeyboard() {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let tapGesture = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing))
        tapGesture.requiresExclusiveTouchType = false
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = GlobalKeyboardDismissalDelegate.shared
        window.addGestureRecognizer(tapGesture)
    }
}

final class GlobalKeyboardDismissalDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = GlobalKeyboardDismissalDelegate()

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
