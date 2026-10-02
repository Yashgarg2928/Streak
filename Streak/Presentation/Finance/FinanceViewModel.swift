// Presentation/Finance/FinanceViewModel.swift

import Foundation
import SwiftUI

enum FinanceSubTab: String, CaseIterable, Identifiable {
    case expenses = "EXPENSES"
    case splits   = "SPLITS & OWED"
    case analytics = "ANALYTICS"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .expenses:  return "🧾"
        case .splits:    return "👥"
        case .analytics: return "📊"
        }
    }
}

@Observable
final class FinanceViewModel {
    private let env: AppEnvironment

    var transactions: [FinanceTransaction] = []
    var summary: FinanceSummary = FinanceSummary()
    var pendingSplits: [(transaction: FinanceTransaction, share: SplitShare)] = []

    var selectedSubTab: FinanceSubTab = .expenses
    var selectedCategoryFilter: FinanceCategory? = nil
    var searchQuery: String = ""

    var currencySymbol: String {
        env.settingsRepository.currencySymbol
    }

    init(env: AppEnvironment) {
        self.env = env
    }

    public func load() {
        do {
            self.transactions = try env.financeRepository.fetchAllTransactions()
            self.summary = try env.financeRepository.fetchSummary(for: Date())
            self.pendingSplits = try env.financeRepository.fetchPendingSplits()
        } catch {
            print("Failed to load finance data: \(error)")
        }
    }

    public var filteredTransactions: [FinanceTransaction] {
        transactions.filter { tx in
            let matchesCategory = selectedCategoryFilter == nil || tx.category == selectedCategoryFilter
            let matchesQuery = searchQuery.isEmpty ||
                tx.note.localizedCaseInsensitiveContains(searchQuery) ||
                tx.category.displayName.localizedCaseInsensitiveContains(searchQuery) ||
                (tx.splitDetails?.splits.contains(where: { $0.personName.localizedCaseInsensitiveContains(searchQuery) }) ?? false)
            return matchesCategory && matchesQuery
        }
    }

    public func addTransaction(
        amount: Double,
        type: TransactionType = .expense,
        category: FinanceCategory = .food,
        note: String = "",
        date: Date = Date(),
        isSplit: Bool = false,
        numberOfPeople: Int = 1,
        friendNames: [String] = [],
        customMyShare: Double? = nil
    ) {
        let useCase = LogTransactionUseCase(financeRepository: env.financeRepository)
        do {
            _ = try useCase.execute(
                amount: amount,
                type: type,
                category: category,
                note: note,
                date: date,
                isSplit: isSplit,
                numberOfPeople: numberOfPeople,
                friendNames: friendNames,
                customMyShare: customMyShare
            )
            load()
        } catch {
            print("Failed to add transaction: \(error)")
        }
    }

    public func deleteTransaction(id: UUID) {
        do {
            try env.financeRepository.deleteTransaction(id: id)
            load()
        } catch {
            print("Failed to delete transaction: \(error)")
        }
    }

    public func settleSplit(transactionId: UUID, shareId: UUID, isSettled: Bool = true) {
        let useCase = SettleSplitShareUseCase(financeRepository: env.financeRepository)
        do {
            try useCase.execute(transactionId: transactionId, shareId: shareId, isSettled: isSettled)
            load()
        } catch {
            print("Failed to settle split: \(error)")
        }
    }
}
