// Presentation/RootView.swift

import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    
    @State private var showOnboarding: Bool = false

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "square.grid.2x2") }
                .tag(Tab.home)

            TaskListView()
                .tabItem { Label("Tasks", systemImage: "checkmark.square") }
                .tag(Tab.tasks)

            WorkoutMainView()
                .tabItem { Label("Workout", systemImage: "figure.run") }
                .tag(Tab.workout)

            FinanceMainView()
                .tabItem { Label("Finance", systemImage: "indianrupeesign.circle") }
                .tag(Tab.finance)

            GoalListView(env: env)
                .tabItem { Label("Goals", systemImage: "flag") }
                .tag(Tab.goals)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(Tab.profile)
        }
        .tint(AppColor.textPrimary)
        .onAppear {
            styleTabBar()
            showOnboarding = !env.settingsRepository.isOnboardingCompleted
            UIApplication.shared.addTapGestureToDismissKeyboard()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(settings: env.settingsRepository) {
                showOnboarding = false
            }
        }
        .sheet(item: $router.activeSheet) { sheet in
            switch sheet {
            case .addCategory:
                AddCategoryView()
            case .editCategory(let id):
                AddCategoryView(editingId: id)
            case .addTransaction:
                AddTransactionSheet { amount, type, category, note, date, isSplit, numPeople, names, customShare, customFriendShares in
                    let useCase = LogTransactionUseCase(financeRepository: env.financeRepository)
                    try? useCase.execute(
                        amount: amount,
                        type: type,
                        category: category,
                        note: note,
                        date: date,
                        isSplit: isSplit,
                        numberOfPeople: numPeople,
                        friendNames: names,
                        customMyShare: customShare,
                        customFriendShares: customFriendShares
                    )
                }
            case .shortcutsGuide:
                ShortcutsSetupGuideSheet()
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
