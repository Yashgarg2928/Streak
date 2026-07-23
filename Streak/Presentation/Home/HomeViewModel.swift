// Presentation/Home/HomeViewModel.swift

import Foundation

@Observable
final class HomeViewModel {
    private(set) var categories: [Category] = []
    private(set) var masterStreak: Int = 0
    private(set) var masterHighStreak: Int = 0
    private(set) var masterStreakHistory: [StreakRun] = []
    private(set) var masterEntries: [Date: DayStatus] = [:]
    private(set) var categoryStreaks: [UUID: Int] = [:]
    private(set) var categoryHighStreaks: [UUID: Int] = [:]
    private(set) var categoryStreakHistories: [UUID: [StreakRun]] = [:]
    private(set) var categoryEntries: [UUID: [Date: DayStatus]] = [:]
    private(set) var errorMessage: String? = nil

    private let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    func load() {
        do {
            categories = try env.categoryRepository.fetchActive()

            // Master entries + streak + history
            let masterDayEntries = try env.dayEntryRepository.fetchAll(categoryId: nil)
            masterEntries = Dictionary(uniqueKeysWithValues: masterDayEntries.map { ($0.date, $0.status) })
            masterStreak = try CalculateStreakUseCase(dayEntryRepository: env.dayEntryRepository)
                .execute(categoryId: nil)
            let masterHistory = try CalculateStreakHistoryUseCase(dayEntryRepository: env.dayEntryRepository)
                .execute(categoryId: nil)
            masterHighStreak    = masterHistory.highStreak
            masterStreakHistory = masterHistory.runs

            // Per-category entries + streaks + histories
            for cat in categories {
                let entries = try env.dayEntryRepository.fetchAll(categoryId: cat.id)
                categoryEntries[cat.id] = Dictionary(uniqueKeysWithValues: entries.map { ($0.date, $0.status) })
                categoryStreaks[cat.id] = try CalculateStreakUseCase(dayEntryRepository: env.dayEntryRepository)
                    .execute(categoryId: cat.id)
                let catHistory = try CalculateStreakHistoryUseCase(dayEntryRepository: env.dayEntryRepository)
                    .execute(categoryId: cat.id)
                categoryHighStreaks[cat.id]      = catHistory.highStreak
                categoryStreakHistories[cat.id]  = catHistory.runs
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
