// App/AppRouter.swift
// Central navigation state. Drives tab selection and sheet/push destinations.
// Only AppRouter and AppEnvironment are modified when adding new feature modules.

import Foundation

enum Tab: Hashable {
    case home
    case tasks
    case goals
    case more
}

enum Sheet: Hashable, Identifiable {
    case addCategory
    case editCategory(UUID)
    case addTask(Date)
    case addGoal
    case editGoal(UUID)
    case dailyAssist(Date)
    case settings
    case exportData
    case importData

    var id: String {
        switch self {
        case .addCategory:         return "addCategory"
        case .editCategory(let id): return "editCategory-\(id)"
        case .addTask(let d):      return "addTask-\(d.timeIntervalSince1970)"
        case .addGoal:             return "addGoal"
        case .editGoal(let id):    return "editGoal-\(id)"
        case .dailyAssist(let d):  return "dailyAssist-\(d.timeIntervalSince1970)"
        case .settings:            return "settings"
        case .exportData:          return "exportData"
        case .importData:          return "importData"
        }
    }
}

@Observable
final class AppRouter {
    var selectedTab: Tab = .home
    var activeSheet: Sheet? = nil
    var categoryDetailId: UUID? = nil   // nil = no detail pushed
    var goalDetailId: UUID? = nil
    var showOverallDetail: Bool = false

    func present(_ sheet: Sheet) {
        activeSheet = sheet
    }

    func dismiss() {
        activeSheet = nil
    }

    func showCategoryDetail(_ id: UUID) {
        categoryDetailId = id
    }

    func showGoalDetail(_ id: UUID) {
        goalDetailId = id
    }
}
