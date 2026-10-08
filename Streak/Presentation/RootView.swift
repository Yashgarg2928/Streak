// Presentation/RootView.swift

import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var showOnboarding: Bool = false

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            HomeView()
                .tabItem { Label("Today", systemImage: "square.grid.2x2") }
                .tag(Tab.home)

            TaskListView()
                .tabItem { Label("Tasks", systemImage: "checkmark.square") }
                .tag(Tab.tasks)

            WorkoutMainView()
                .tabItem { Label("Fitness", systemImage: "figure.run") }
                .tag(Tab.workout)

            FinanceMainView()
                .tabItem { Label("Finance", systemImage: "indianrupeesign.circle") }
                .tag(Tab.finance)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(Tab.profile)
        }
        // When the active day rolls over while the app is open, sweep so the new day's
        // habit tasks, status, widgets and countdown appear without reopening the app.
        .task {
            var lastActiveDay = ActiveDayResolver.resolveActiveDate(for: Date(), settings: env.settingsRepository)
            while !Swift.Task.isCancelled {
                try? await Swift.Task.sleep(for: .seconds(20))
                let activeDay = ActiveDayResolver.resolveActiveDate(for: Date(), settings: env.settingsRepository)
                if activeDay != lastActiveDay {
                    lastActiveDay = activeDay
                    DaySweeper.run(env: env)
                }
            }
        }
        // AppFont sizes are resolved when views are built, so rebuild on text-size changes.
        .id(dynamicTypeSize)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
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
            case .settings:
                NavigationStack {
                    SettingsView(env: env)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { router.dismiss() }
                                    .fontWeight(.bold)
                            }
                        }
                }
            case .addTransaction:
                AddTransactionSheet(
                    onSave: { _, amount, type, category, note, date, isSplit, numPeople, names, customShare, customFriendShares in
                        let useCase = LogTransactionUseCase(financeRepository: env.financeRepository)
                        _ = try useCase.execute(
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
                        env.syncWidgets()
                    }
                )
            case .editTransaction(let id):
                if let tx = try? env.financeRepository.fetchTransaction(id: id) {
                    AddTransactionSheet(
                        transactionToEdit: tx,
                        onSave: { targetId, amount, type, category, note, date, isSplit, numPeople, names, customShare, customFriendShares in
                            if let targetId {
                                let useCase = UpdateTransactionUseCase(financeRepository: env.financeRepository)
                                _ = try useCase.execute(
                                    id: targetId,
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
                                env.syncWidgets()
                            }
                        },
                        onDelete: { deleteId in
                            let useCase = DeleteTransactionUseCase(financeRepository: env.financeRepository)
                            try useCase.execute(id: deleteId)
                            env.syncWidgets()
                        }
                    )
                } else {
                    EmptyView()
                }
            case .shortcutsGuide:
                ShortcutsSetupGuideSheet()
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
