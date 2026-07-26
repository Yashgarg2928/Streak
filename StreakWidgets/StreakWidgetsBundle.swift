// StreakWidgets/StreakWidgetsBundle.swift

import WidgetKit
import SwiftUI

@main
struct StreakWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MasterStreakWidget()
        HabitChartWidget()
        CategoryWidget()
        TasksWidget()
        MultiCategoryWidget()
        GoalWidget()
    }
}
