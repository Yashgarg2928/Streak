// Presentation/Profile/ProfileViewModel.swift

import Foundation
import SwiftUI

@Observable
final class ProfileViewModel {
    private(set) var profile: PlayerProfile = PlayerProfile()
    private(set) var badges: [Badge] = []
    private(set) var customRewards: [CustomReward] = []
    private(set) var categories: [Category] = []
    private(set) var transactions: [XPTransaction] = []
    private(set) var shopItems: [ShopItem] = []
    private(set) var errorMessage: String? = nil
    private(set) var successMessage: String? = nil

    private let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    func load() {
        do {
            profile = try env.playerProfileRepository.fetchProfile()
            badges = try env.badgeRepository.fetchAll()
            customRewards = try env.customRewardRepository.fetchAll()
            categories = try env.categoryRepository.fetchAll()
            transactions = try env.xpTransactionRepository.fetchRecent(limit: 30)
            shopItems = try env.shopItemRepository.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func buyFixedItem(_ itemType: FixedShopItemType) {
        do {
            let useCase = ShopPurchaseUseCase(
                playerProfileRepository: env.playerProfileRepository,
                xpTransactionRepository: env.xpTransactionRepository,
                shopItemRepository: env.shopItemRepository,
                customRewardRepository: env.customRewardRepository,
                badgeRepository: env.badgeRepository
            )
            try useCase.purchaseFixedItem(itemType)
            successMessage = "Successfully purchased \(itemType.title)!"
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func redeemCustomReward(_ reward: CustomReward) {
        do {
            let useCase = ShopPurchaseUseCase(
                playerProfileRepository: env.playerProfileRepository,
                xpTransactionRepository: env.xpTransactionRepository,
                shopItemRepository: env.shopItemRepository,
                customRewardRepository: env.customRewardRepository,
                badgeRepository: env.badgeRepository
            )
            try useCase.redeemCustomReward(id: reward.id)
            successMessage = "Successfully redeemed \(reward.title)!"
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addCustomReward(title: String, description: String, categoryId: UUID?, tier: CustomRewardTier) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            let now = Date()
            let isCurrentMonthLocked = true // Locked for active month
            let reward = CustomReward(
                title: title,
                rewardDescription: description,
                categoryId: categoryId,
                tier: tier,
                targetMonth: now,
                isLocked: isCurrentMonthLocked
            )
            try env.customRewardRepository.save(reward)
            successMessage = "Custom reward '\(title)' added for this month!"
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteCustomReward(id: UUID) {
        do {
            try env.customRewardRepository.delete(id: id)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func color(for categoryId: UUID?) -> Color? {
        guard let categoryId, let cat = categories.first(where: { $0.id == categoryId }) else { return nil }
        return cat.color
    }

    func categoryName(for categoryId: UUID?) -> String {
        guard let categoryId, let cat = categories.first(where: { $0.id == categoryId }) else { return "OVERALL" }
        return cat.name.uppercased()
    }
}
