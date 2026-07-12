// Presentation/Home/HomeViewModel.swift

import Foundation

@Observable
final class HomeViewModel {
    private(set) var categories: [Category] = []
    private(set) var masterStreak: Int = 0
    private(set) var masterEntries: [Date: DayStatus] = [:]
    private(set) var categoryStreaks: [UUID: Int] = [:]
    private(set) var categoryEntries: [UUID: [Date: DayStatus]] = [:]
    private(set) var errorMessage: String? = nil

    private let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    func load() {
        do {
            categories = try env.categoryRepository.fetchActive()

            // Master entries + streak
            let masterDayEntries = try env.dayEntryRepository.fetchAll(categoryId: nil)
            masterEntries = Dictionary(uniqueKeysWithValues: masterDayEntries.map { ($0.date, $0.status) })
            masterStreak = try CalculateStreakUseCase(dayEntryRepository: env.dayEntryRepository)
                .execute(categoryId: nil)

            // Per-category entries + streaks
            for cat in categories {
                let entries = try env.dayEntryRepository.fetchAll(categoryId: cat.id)
                categoryEntries[cat.id] = Dictionary(uniqueKeysWithValues: entries.map { ($0.date, $0.status) })
                categoryStreaks[cat.id] = try CalculateStreakUseCase(dayEntryRepository: env.dayEntryRepository)
                    .execute(categoryId: cat.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
