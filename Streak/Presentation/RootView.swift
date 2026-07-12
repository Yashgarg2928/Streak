// Presentation/RootView.swift

import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "square.grid.2x2") }
                .tag(Tab.home)

            TaskListView()
                .tabItem { Label("Tasks", systemImage: "checkmark.square") }
                .tag(Tab.tasks)

            Text("Goals")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColor.background.ignoresSafeArea())
                .tabItem { Label("Goals", systemImage: "flag") }
                .tag(Tab.goals)

            Text("More")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColor.background.ignoresSafeArea())
                .tabItem { Label("More", systemImage: "ellipsis") }
                .tag(Tab.more)
        }
        .tint(AppColor.textPrimary)
        .onAppear { styleTabBar() }
        .sheet(item: $router.activeSheet) { sheet in
            switch sheet {
            case .addCategory:
                AddCategoryView()
            case .editCategory(let id):
                AddCategoryView(editingId: id)
            default:
                EmptyView()
            }
        }
    }

    private func styleTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColor.surface)
        appearance.shadowColor = UIColor(AppColor.border)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
