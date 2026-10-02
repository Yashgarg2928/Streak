// Application/UseCases/Finance/DeleteTransactionUseCase.swift

import Foundation

public final class DeleteTransactionUseCase {
    private let financeRepository: any FinanceRepository

    public init(financeRepository: any FinanceRepository) {
        self.financeRepository = financeRepository
    }

    public func execute(id: UUID) throws {
        try financeRepository.deleteTransaction(id: id)
    }
}
