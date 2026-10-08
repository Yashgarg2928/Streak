// App/AppRouter.swift
// Central navigation state. Drives tab selection and sheet/push destinations.
// Only AppRouter and AppEnvironment are modified when adding new feature modules.

import Foundation

/// Five tabs — iOS shows at most five before collapsing the rest into "More".
enum Tab: Hashable {
    case home
    case tasks
    case workout
    case finance
    case profile
}

enum Sheet: Hashable, Identifiable {
    case addCategory
    case editCategory(UUID)
    case settings
    case addTransaction
    case editTransaction(UUID)
    case shortcutsGuide

    var id: String {
        switch self {
        case .addCategory:         return "addCategory"
        case .editCategory(let id): return "editCategory-\(id)"
        case .settings:            return "settings"
        case .addTransaction:      return "addTransaction"
        case .editTransaction(let id): return "editTransaction-\(id)"
        case .shortcutsGuide:      return "shortcutsGuide"
        }
    }
}

@Observable
final class AppRouter {
    var selectedTab: Tab = .home
    var activeSheet: Sheet? = nil
    var categoryDetailId: UUID? = nil   // nil = no detail pushed
    var showOverallDetail: Bool = false
    var showGoals: Bool = false         // Goals list pushed from Home

    func present(_ sheet: Sheet) {
        activeSheet = sheet
    }

    func dismiss() {
        activeSheet = nil
    }

    func showCategoryDetail(_ id: UUID) {
        categoryDetailId = id
    }
}
