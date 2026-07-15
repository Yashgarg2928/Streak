// StreakWidgets/StreakWidgetsBundle.swift

import WidgetKit
import SwiftUI

@main
struct StreakWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MasterStreakWidget()
        CategoryWidget()
        TasksWidget()
        MultiCategoryWidget()
        GoalWidget()
    }
}
