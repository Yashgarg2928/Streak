// Presentation/Profile/ProfileView.swift

import SwiftUI

enum ProfileTabSection: String, CaseIterable, Identifiable {
    case shop = "REWARD SHOP"
    case badges = "BADGES"
    case log = "XP LOG"

    var id: String { rawValue }
}

struct ProfileView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var vm: ProfileViewModel?
    @State private var selectedSection: ProfileTabSection = .shop
    @State private var showAddRewardSheet: Bool = false
    @State private var showSettingsSheet: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, AppLayout.screenMargin)
                    .padding(.top, AppLayout.itemSpacing)

                ScrollView {
                    VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                        if let vm {
                            // Header Profile Card
                            headerProfileCard(vm: vm)

                            // Segmented Switcher
                            sectionControl

                            // Content Section
                            switch selectedSection {
                            case .shop:
                                shopContent(vm: vm)
                            case .badges:
                                badgesContent(vm: vm)
                            case .log:
                                xpLogContent(vm: vm)
                            }
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .padding(.horizontal, AppLayout.screenMargin)
                    .padding(.vertical, AppLayout.sectionSpacing)
                }
            }
            .background(AppColor.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if vm == nil { vm = ProfileViewModel(env: env) }
                vm?.load()
            }
            .sheet(isPresented: $showSettingsSheet) {
                NavigationStack {
                    SettingsView(env: env)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showSettingsSheet = false
                                }
                                .fontWeight(.bold)
                            }
                        }
                }
            }
            .sheet(isPresented: $showAddRewardSheet) {
                if let vm {
                    AddCustomRewardSheet(categories: vm.categories) { title, desc, catId, tier in
                        vm.addCustomReward(title: title, description: desc, categoryId: catId, tier: tier)
                    }
                }
            }
            .alert("Notice", isPresented: Binding(
                get: { vm?.errorMessage != nil || vm?.successMessage != nil },
                set: { _ in
                    // Dismiss alert
                }
            )) {
                Button("OK", role: .cancel) {
                    // Clear messages
                }
            } message: {
                if let err = vm?.errorMessage {
                    Text(err)
                } else if let succ = vm?.successMessage {
                    Text(succ)
                }
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Text("PROFILE & SHOP")
                .font(.system(.title2, design: .monospaced).weight(.black))
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            Button {
                showSettingsSheet = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("SETTINGS")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(AppColor.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Header Profile Card

    private func headerProfileCard(vm: ProfileViewModel) -> some View {
        let level = vm.profile.currentLevel
        let title = vm.profile.currentTitle
        let (currentXP, requiredXP, fraction) = PlayerLevelResolver.levelProgress(totalXP: vm.profile.totalXP)

        return BrutalistCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    // Level badge
                    HStack(spacing: 4) {
                        Text("LVL")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                        Text("\(level)")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                    }
                    .foregroundStyle(AppColor.background)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColor.border)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(title.emoji)
                            Text(title.name.uppercased())
                                .font(.system(.headline).weight(.black))
                                .foregroundStyle(AppColor.textPrimary)
                        }
                        Text(title.subtitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    Spacer()

                    // XP Counter
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(vm.profile.totalXP) XP")
                            .font(.system(.title3, design: .monospaced).weight(.black))
                            .foregroundStyle(AppColor.textPrimary)
                        Text("TOTAL EARNED")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }

                // Level Progress Bar
                ProgressBarView(
                    fraction: fraction,
                    label: "LEVEL PROGRESS: \(currentXP) / \(requiredXP) XP",
                    fillColor: AppColor.green
                )

                // Inventory / Status Row
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("⛄")
                        Text("STREAK FREEZES: \(vm.profile.streakFreezes)/2")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.border, lineWidth: 1.5))

                    if let expiry = vm.profile.activeBoostExpiry, expiry > Date() {
                        HStack(spacing: 4) {
                            Text("⚡ 2× XP ACTIVE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppColor.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.green, lineWidth: 1.5))
                    }
                }
            }
        }
    }

    // MARK: - Section Control Switcher

    private var sectionControl: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTabSection.allCases) { section in
                let selected = selectedSection == section
                Button {
                    selectedSection = section
                } label: {
                    Text(section.rawValue)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(selected ? AppColor.background : AppColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(selected ? AppColor.border : AppColor.surface)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
    }

    // MARK: - Shop Content

    private func shopContent(vm: ProfileViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
            // User-Defined Custom Monthly Rewards
            VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MONTHLY CUSTOM REWARDS")
                            .font(.system(.subheadline).weight(.semibold))
                            .foregroundStyle(AppColor.textSecondary)
                        Text("Category-linked rewards defined by you")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Spacer()
                    Button {
                        showAddRewardSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .black))
                            Text("ADD REWARD")
                                .font(.system(size: 10, weight: .black))
                        }
                        .foregroundStyle(AppColor.background)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColor.border)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }

                if vm.customRewards.isEmpty {
                    BrutalistCard {
                        Text("No custom rewards configured for this month.\nTap + ADD REWARD to set your monthly rewards.")
                            .font(.system(.subheadline))
                            .foregroundStyle(AppColor.textDisabled)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                } else {
                    ForEach(vm.customRewards) { reward in
                        customRewardCard(reward: reward, vm: vm)
                    }
                }
            }

            // Fixed System Shop Items
            VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                Text("SYSTEM SHOP ITEMS")
                    .font(.system(.subheadline).weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)

                ForEach(FixedShopItemType.allCases) { itemType in
                    fixedShopItemCard(itemType: itemType, vm: vm)
                }
            }
        }
    }

    private func customRewardCard(reward: CustomReward, vm: ProfileViewModel) -> some View {
        let isRedeemed = reward.isRedeemed
        let canAfford = vm.profile.totalXP >= reward.xpCost
        let catColor = vm.color(for: reward.categoryId)
        let catName = vm.categoryName(for: reward.categoryId)

        return BrutalistCard(borderColor: isRedeemed ? AppColor.green : AppColor.border) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        CategoryDot(color: catColor ?? AppColor.neutralDot)
                        Text(catName)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text(reward.tier.emoji)
                        Text("\(reward.xpCost) XP")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.border, lineWidth: 1.5))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(reward.title)
                        .font(.system(.headline).weight(.bold))
                        .foregroundStyle(AppColor.textPrimary)
                        .strikethrough(isRedeemed)

                    if !reward.rewardDescription.isEmpty {
                        Text(reward.rewardDescription)
                            .font(.system(.caption))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }

                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: reward.isLocked ? "lock.fill" : "lock.open.fill")
                            .font(.system(size: 10))
                        Text(reward.isLocked ? "LOCKED FOR MONTH" : "EDITABLE")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(AppColor.textDisabled)

                    Spacer()

                    if isRedeemed {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("REDEEMED")
                                .font(.system(size: 10, weight: .black))
                        }
                        .foregroundStyle(AppColor.green)
                    } else {
                        Button {
                            vm.redeemCustomReward(reward)
                        } label: {
                            Text("REDEEM (\(reward.xpCost) XP)")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(canAfford ? AppColor.background : AppColor.textDisabled)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(canAfford ? AppColor.green : AppColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .disabled(!canAfford)
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func fixedShopItemCard(itemType: FixedShopItemType, vm: ProfileViewModel) -> some View {
        let isLevelUnlocked = vm.profile.currentLevel >= itemType.minLevel
        let canAfford = vm.profile.totalXP >= itemType.xpCost

        return BrutalistCard {
            HStack(spacing: 12) {
                Text(itemType.emoji)
                    .font(.system(size: 26))

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(itemType.title.uppercased())
                            .font(.system(.subheadline).weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)
                        
                        if !isLevelUnlocked {
                            Text("REQ LVL \(itemType.minLevel)")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(AppColor.red)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(AppColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.red, lineWidth: 1))
                        }
                    }

                    Text(itemType.effectDescription)
                        .font(.system(size: 11))
                        .foregroundStyle(AppColor.textSecondary)
                }

                Spacer()

                Button {
                    vm.buyFixedItem(itemType)
                } label: {
                    VStack(spacing: 2) {
                        Text("BUY")
                            .font(.system(size: 10, weight: .black))
                        Text("\(itemType.xpCost) XP")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(isLevelUnlocked && canAfford ? AppColor.background : AppColor.textDisabled)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isLevelUnlocked && canAfford ? AppColor.border : AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .disabled(!isLevelUnlocked || !canAfford)
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Badges Content

    private func badgesContent(vm: ProfileViewModel) -> some View {
        let earnedKeys = Set(vm.badges.map(\.badgeKey))
        let grouped = Dictionary(grouping: BadgeDefinition.allBadges, by: \.category)

        return VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
            ForEach(BadgeCategory.allCases, id: \.self) { category in
                if let definitions = grouped[category], !definitions.isEmpty {
                    VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                        Text(category.rawValue.uppercased())
                            .font(.system(.subheadline).weight(.semibold))
                            .foregroundStyle(AppColor.textSecondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppLayout.itemSpacing) {
                            ForEach(definitions) { def in
                                let isEarned = earnedKeys.contains(def.key)
                                badgeCard(def: def, isEarned: isEarned)
                            }
                        }
                    }
                }
            }
        }
    }

    private func badgeCard(def: BadgeDefinition, isEarned: Bool) -> some View {
        BrutalistCard(borderColor: isEarned ? AppColor.green : AppColor.border.opacity(0.4)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: def.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(isEarned ? AppColor.green : AppColor.textDisabled)

                    Spacer()

                    if isEarned {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColor.green)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColor.textDisabled)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(def.title.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isEarned ? AppColor.textPrimary : AppColor.textDisabled)

                    Text(def.description)
                        .font(.system(size: 10))
                        .foregroundStyle(isEarned ? AppColor.textSecondary : AppColor.textDisabled)
                        .lineLimit(2)
                }
            }
        }
    }

    // MARK: - XP Log Content

    private func xpLogContent(vm: ProfileViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
            Text("RECENT XP TRANSACTIONS")
                .font(.system(.subheadline).weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)

            if vm.transactions.isEmpty {
                BrutalistCard {
                    Text("No transactions logged yet.")
                        .font(.system(.subheadline))
                        .foregroundStyle(AppColor.textDisabled)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            } else {
                ForEach(vm.transactions) { tx in
                    BrutalistCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tx.reason.rawValue.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(AppColor.textPrimary)
                                if let note = tx.note {
                                    Text(note)
                                        .font(.system(size: 10))
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                            }

                            Spacer()

                            Text(tx.amount >= 0 ? "+\(tx.amount) XP" : "\(tx.amount) XP")
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                                .foregroundStyle(tx.amount >= 0 ? AppColor.green : AppColor.red)
                        }
                    }
                }
            }
        }
    }
}
