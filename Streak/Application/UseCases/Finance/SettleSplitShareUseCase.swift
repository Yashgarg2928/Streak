// Application/UseCases/Finance/SettleSplitShareUseCase.swift

import Foundation

public final class SettleSplitShareUseCase {
    private let financeRepository: any FinanceRepository

    public init(financeRepository: any FinanceRepository) {
        self.financeRepository = financeRepository
    }

    public func execute(transactionId: UUID, shareId: UUID, isSettled: Bool = true) throws {
        try financeRepository.settleSplitShare(transactionId: transactionId, shareId: shareId, isSettled: isSettled)
    }
}
