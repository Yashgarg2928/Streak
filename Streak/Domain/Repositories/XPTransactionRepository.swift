// Domain/Repositories/XPTransactionRepository.swift

import Foundation

public protocol XPTransactionRepository {
    func fetchAll() throws -> [XPTransaction]
    func fetchRecent(limit: Int) throws -> [XPTransaction]
    func save(_ transaction: XPTransaction) throws
}
