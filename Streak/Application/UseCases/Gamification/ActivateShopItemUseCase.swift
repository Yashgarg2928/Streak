// Application/UseCases/Gamification/ActivateShopItemUseCase.swift

import Foundation

enum ActivateShopItemError: LocalizedError {
    case itemAlreadyUsed
    case itemNotFound
    
    var errorDescription: String? {
        switch self {
        case .itemAlreadyUsed:
            return "This item has already been activated."
        case .itemNotFound:
            return "Item not found in inventory."
        }
    }
}

struct ActivateShopItemUseCase {
    let playerProfileRepository: any PlayerProfileRepository
    let shopItemRepository: any ShopItemRepository
    let dayEntryRepository: any DayEntryRepository
    let settingsRepository: any SettingsRepository

    init(
        playerProfileRepository: any PlayerProfileRepository,
        shopItemRepository: any ShopItemRepository,
        dayEntryRepository: any DayEntryRepository,
        settingsRepository: any SettingsRepository
    ) {
        self.playerProfileRepository = playerProfileRepository
        self.shopItemRepository = shopItemRepository
        self.dayEntryRepository = dayEntryRepository
        self.settingsRepository = settingsRepository
    }

    func execute(itemId: UUID) throws {
        let items = try shopItemRepository.fetchAll()
        guard let index = items.firstIndex(where: { $0.id == itemId }) else {
            throw ActivateShopItemError.itemNotFound
        }
        
        var item = items[index]
        guard item.usedAt == nil else {
            throw ActivateShopItemError.itemAlreadyUsed
        }

        let now = Date()
        item.usedAt = now

        var profile = try playerProfileRepository.fetchProfile()

        switch item.itemType {
        case .streakFreeze:
            // Manually activating a Streak Freeze applies a freeze shield to protect active day status!
            let activeDate = ActiveDayResolver.resolveActiveDate(for: now, settings: settingsRepository)
            let existingEntry = try dayEntryRepository.fetch(date: activeDate, categoryId: nil)
            let freezeEntry = DayEntry(
                date: activeDate,
                categoryId: nil,
                status: .green,
                taskCount: existingEntry?.taskCount ?? 0,
                completedCount: existingEntry?.completedCount ?? 0
            )
            try dayEntryRepository.save(freezeEntry)
            if profile.streakFreezes > 0 {
                profile.streakFreezes -= 1
            }

        case .xpBoost, .doubleHabitDay:
            let duration: TimeInterval = 24 * 3600 // 24 hours
            let expiry = now.addingTimeInterval(duration)
            item.expiresAt = expiry
            profile.activeBoostExpiry = expiry

        case .xpMultiplierWeek:
            let duration: TimeInterval = 7 * 24 * 3600 // 7 days
            let expiry = now.addingTimeInterval(duration)
            item.expiresAt = expiry
            profile.activeBoostExpiry = expiry

        case .weekendShield, .restDayPass, .bingeNightPass:
            let activeDate = ActiveDayResolver.resolveActiveDate(for: now, settings: settingsRepository)
            let freezeEntry = DayEntry(
                date: activeDate,
                categoryId: nil,
                status: .green,
                taskCount: 0,
                completedCount: 0
            )
            try dayEntryRepository.save(freezeEntry)
            item.expiresAt = now.addingTimeInterval(24 * 3600)

        case .prestigeBadgeSlot, .legendaryStreakArmor:
            item.expiresAt = nil
        }

        profile.lastUpdated = now
        try playerProfileRepository.saveProfile(profile)
        try shopItemRepository.save(item)
    }
}
