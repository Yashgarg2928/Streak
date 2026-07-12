// Application/UseCases/Habits/CreateCategoryUseCase.swift

import Foundation

struct CreateCategoryUseCase {
    let repository: any CategoryRepository

    func execute(name: String, colorHex: String) throws -> Category {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw StreakError.emptyTitle }
        guard isValidHex(colorHex) else { throw StreakError.invalidColor }

        let order = (try? repository.maxSortOrder()) ?? -1
        let category = Category(name: trimmed, colorHex: colorHex, sortOrder: order + 1)
        try repository.save(category)
        return category
    }

    private func isValidHex(_ hex: String) -> Bool {
        let clean = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        return clean.count == 6 && clean.allSatisfy { $0.isHexDigit }
    }
}
