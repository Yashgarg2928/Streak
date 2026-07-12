// Presentation/Home/HomeView.swift

import SwiftUI

struct HomeView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    @State private var vm: HomeViewModel?

    var body: some View {
        @Bindable var router = router
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                    masterCard
                    categoriesSection
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.vertical, AppLayout.sectionSpacing)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("STREAK")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        router.present(.addCategory)
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .frame(minWidth: AppLayout.minTapTarget, minHeight: AppLayout.minTapTarget)
                }
            }
            .navigationDestination(item: $router.categoryDetailId) { id in
                CategoryDetailView(categoryId: id)
            }
        }
        .onAppear {
            if vm == nil { vm = HomeViewModel(env: env) }
            vm?.load()
        }
    }

    // MARK: - Master card

    private var masterCard: some View {
        BrutalistCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("OVERALL")
                        .font(.system(.headline).weight(.semibold))
                        .foregroundStyle(AppColor.textPrimary)
                    Spacer()
                    StreakBadgeView(count: vm?.masterStreak ?? 0)
                }
                ConsistencyGridView(entries: vm?.masterEntries ?? [:])
            }
        }
    }

    // MARK: - Categories section

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
            Text("CATEGORIES")
                .font(.system(.subheadline).weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)

            if let cats = vm?.categories, !cats.isEmpty {
                VStack(spacing: AppLayout.itemSpacing) {
                    ForEach(cats) { category in
                        categoryCard(category)
                    }
                }
            } else {
                EmptyStateView(message: "No categories yet.\nTap + to create one.")
            }
        }
    }

    // MARK: - Category card

    private func categoryCard(_ category: Category) -> some View {
        Button {
            router.showCategoryDetail(category.id)
        } label: {
            BrutalistCard(borderColor: category.color) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(category.name.uppercased())
                            .font(.system(.headline).weight(.semibold))
                            .foregroundStyle(AppColor.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        StreakBadgeView(
                            count: vm?.categoryStreaks[category.id] ?? 0,
                            color: category.color
                        )
                    }
                    ConsistencyGridView(
                        entries: vm?.categoryEntries[category.id] ?? [:],
                        categoryColor: category.color
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.name) category, \(vm?.categoryStreaks[category.id] ?? 0) day streak")
    }
}
