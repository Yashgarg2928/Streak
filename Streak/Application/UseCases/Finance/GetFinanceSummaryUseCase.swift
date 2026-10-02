// Application/UseCases/Finance/GetFinanceSummaryUseCase.swift

import Foundation

public final class GetFinanceSummaryUseCase {
    private let financeRepository: any FinanceRepository

    public init(financeRepository: any FinanceRepository) {
        self.financeRepository = financeRepository
    }

    public func execute(for date: Date = Date()) throws -> FinanceSummary {
        try financeRepository.fetchSummary(for: date)
    }
}
