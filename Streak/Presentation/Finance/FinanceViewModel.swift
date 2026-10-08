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
    /// Set when a user action fails; FinanceMainView shows it in an alert.
    var errorMessage: String? = nil
    private let env: AppEnvironment

    var transactions: [FinanceTransaction] = []
    var summary: FinanceSummary = FinanceSummary()
    var pendingSplits: [(transaction: FinanceTransaction, share: SplitShare)] = []
    var friends: [Friend] = []

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
            self.friends = try env.financeRepository.fetchFriends()
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
        customMyShare: Double? = nil,
        customFriendShares: [SplitShare]? = nil
    ) throws {
        let useCase = LogTransactionUseCase(financeRepository: env.financeRepository)
        _ = try useCase.execute(
            amount: amount,
            type: type,
            category: category,
            note: note,
            date: date,
            isSplit: isSplit,
            numberOfPeople: numberOfPeople,
            friendNames: friendNames,
            customMyShare: customMyShare,
            customFriendShares: customFriendShares
        )
        load()
        env.syncWidgets()
    }

    public func updateTransaction(
        id: UUID,
        amount: Double,
        type: TransactionType = .expense,
        category: FinanceCategory = .food,
        note: String = "",
        date: Date = Date(),
        isSplit: Bool = false,
        numberOfPeople: Int = 1,
        friendNames: [String] = [],
        customMyShare: Double? = nil,
        customFriendShares: [SplitShare]? = nil
    ) throws {
        let useCase = UpdateTransactionUseCase(financeRepository: env.financeRepository)
        _ = try useCase.execute(
            id: id,
            amount: amount,
            type: type,
            category: category,
            note: note,
            date: date,
            isSplit: isSplit,
            numberOfPeople: numberOfPeople,
            friendNames: friendNames,
            customMyShare: customMyShare,
            customFriendShares: customFriendShares
        )
        load()
        env.syncWidgets()
    }

    public func deleteTransaction(id: UUID) throws {
        let useCase = DeleteTransactionUseCase(financeRepository: env.financeRepository)
        try useCase.execute(id: id)
        load()
        env.syncWidgets()
    }

    public func settleSplit(transactionId: UUID, shareId: UUID, isSettled: Bool = true) {
        let useCase = SettleSplitShareUseCase(financeRepository: env.financeRepository)
        do {
            try useCase.execute(transactionId: transactionId, shareId: shareId, isSettled: isSettled)
            load()
            env.syncWidgets()
        } catch {
            errorMessage = "Couldn't settle split: \(error.localizedDescription)"
        }
    }

    // MARK: - Friend Directory & Direct Collection

    public func addFriend(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let friend = Friend(name: trimmed)
        do {
            try env.financeRepository.saveFriend(friend)
            self.friends = try env.financeRepository.fetchFriends()
        } catch {
            errorMessage = "Couldn't save friend: \(error.localizedDescription)"
        }
    }

    public func deleteFriend(id: UUID) {
        do {
            try env.financeRepository.deleteFriend(id: id)
            self.friends = try env.financeRepository.fetchFriends()
        } catch {
            errorMessage = "Couldn't delete friend: \(error.localizedDescription)"
        }
    }

    public func settleAllForFriend(name: String) {
        do {
            try env.financeRepository.settleAllSplitsForFriend(name: name)
            load()
            env.syncWidgets()
        } catch {
            errorMessage = "Couldn't settle all for friend: \(error.localizedDescription)"
        }
    }

    public func addDirectCollect(
        friendName: String,
        amount: Double,
        note: String = "",
        category: FinanceCategory = .personal,
        date: Date = Date()
    ) {
        let trimmedFriend = friendName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFriend.isEmpty, amount > 0 else { return }

        // Automatically save to fixed friends
        addFriend(name: trimmedFriend)

        let share = SplitShare(
            personName: trimmedFriend,
            amountOwed: amount,
            isSettled: false
        )
        let split = SplitDetails(
            totalAmount: amount,
            numberOfPeople: 2,
            myShare: 0.0,
            splits: [share]
        )
        let transaction = FinanceTransaction(
            amount: amount,
            type: .expense,
            category: category,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Direct to collect from \(trimmedFriend)" : note,
            date: date,
            isSplit: true,
            splitDetails: split
        )
        do {
            try env.financeRepository.saveTransaction(transaction)
            load()
            env.syncWidgets()
        } catch {
            errorMessage = "Couldn't add direct collect: \(error.localizedDescription)"
        }
    }

    // MARK: - Friend Tabs & Aggregated Balances

    public var friendTabSummaries: [FriendTabSummary] {
        var map: [String: (name: String, items: [(transaction: FinanceTransaction, share: SplitShare)])] = [:]

        // Seed with all saved fixed friends
        for f in friends {
            let key = f.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !key.isEmpty {
                map[key] = (name: f.name, items: [])
            }
        }

        // Aggregate every split share across all transactions
        for tx in transactions {
            if tx.isSplit, let split = tx.splitDetails {
                for share in split.splits {
                    let trimmed = share.personName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { continue }
                    let key = trimmed.lowercased()
                    if map[key] == nil {
                        map[key] = (name: trimmed, items: [])
                    }
                    map[key]?.items.append((transaction: tx, share: share))
                }
            }
        }

        var list: [FriendTabSummary] = []
        for (_, value) in map {
            let totalOwed = value.items.filter { !$0.share.isSettled }.reduce(0.0) { $0 + $1.share.amountOwed }
            let totalSettled = value.items.filter { $0.share.isSettled }.reduce(0.0) { $0 + $1.share.amountOwed }
            let pendingCount = value.items.filter { !$0.share.isSettled }.count
            let sortedItems = value.items.sorted { $0.transaction.date > $1.transaction.date }
            list.append(FriendTabSummary(
                name: value.name,
                totalOwed: totalOwed,
                totalSettled: totalSettled,
                pendingCount: pendingCount,
                items: sortedItems
            ))
        }

        // Sort: Friends with outstanding receivables first (descending), then alphabetically
        return list.sorted {
            if $0.totalOwed != $1.totalOwed {
                return $0.totalOwed > $1.totalOwed
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}

// MARK: - Friend Tab Summary Model

public struct FriendTabSummary: Identifiable, Equatable {
    public var id: String { name.lowercased() }
    public let name: String
    public var totalOwed: Double
    public var totalSettled: Double
    public var totalHistory: Double { totalOwed + totalSettled }
    public var pendingCount: Int
    public var items: [(transaction: FinanceTransaction, share: SplitShare)]

    public static func == (lhs: FriendTabSummary, rhs: FriendTabSummary) -> Bool {
        lhs.name.lowercased() == rhs.name.lowercased() &&
        abs(lhs.totalOwed - rhs.totalOwed) < 0.001 &&
        abs(lhs.totalSettled - rhs.totalSettled) < 0.001 &&
        lhs.pendingCount == rhs.pendingCount &&
        lhs.items.count == rhs.items.count
    }
}

