// Domain/Repositories/FinanceRepository.swift
// Pure Swift protocol for Finance persistence operations.

import Foundation

public protocol FinanceRepository {
    func fetchAllTransactions() throws -> [FinanceTransaction]
    func fetchTransactions(from startDate: Date, to endDate: Date) throws -> [FinanceTransaction]
    func fetchTransaction(id: UUID) throws -> FinanceTransaction?
    func saveTransaction(_ transaction: FinanceTransaction) throws
    func deleteTransaction(id: UUID) throws
    func settleSplitShare(transactionId: UUID, shareId: UUID, isSettled: Bool) throws
    func fetchPendingSplits() throws -> [(transaction: FinanceTransaction, share: SplitShare)]
    func fetchSummary(for date: Date) throws -> FinanceSummary

    // Friend Directory & Tabs
    func fetchFriends() throws -> [Friend]
    func saveFriend(_ friend: Friend) throws
    func deleteFriend(id: UUID) throws
    func settleAllSplitsForFriend(name: String) throws
}
