// Application/UseCases/Finance/UpdateTransactionUseCase.swift

import Foundation

public final class UpdateTransactionUseCase {
    private let financeRepository: any FinanceRepository

    public init(financeRepository: any FinanceRepository) {
        self.financeRepository = financeRepository
    }

    @discardableResult
    public func execute(
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
    ) throws -> FinanceTransaction {
        let cleanAmount = max(0, amount)
        let existing = try financeRepository.fetchTransaction(id: id)

        var splitDetails: SplitDetails? = nil
        if isSplit {
            if let customFriendShares, !customFriendShares.isEmpty {
                // Custom split mode
                let totalFriendsOwed = customFriendShares.reduce(0.0) { $0 + $1.amountOwed }
                let myShare = customMyShare ?? max(0, cleanAmount - totalFriendsOwed)
                let totalCount = customFriendShares.count + 1

                splitDetails = SplitDetails(
                    totalAmount: cleanAmount,
                    numberOfPeople: totalCount,
                    myShare: myShare,
                    splits: customFriendShares
                )
            } else {
                // Equal split mode
                let totalCount = max(1, numberOfPeople)
                if totalCount > 1 {
                    let myShare = customMyShare ?? (cleanAmount / Double(totalCount))
                    let toCollectTotal = max(0, cleanAmount - myShare)

                    let friendCount = totalCount - 1
                    let perFriendShare = friendCount > 0 ? (toCollectTotal / Double(friendCount)) : 0

                    var shares: [SplitShare] = []
                    for i in 0..<friendCount {
                        let name: String
                        if i < friendNames.count && !friendNames[i].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            name = friendNames[i].trimmingCharacters(in: .whitespacesAndNewlines)
                        } else {
                            name = "Friend \(i + 1)"
                        }

                        // Preserve existing settlement status if matching by index/name
                        let existingShare = existing?.splitDetails?.splits.first(where: { $0.personName.lowercased() == name.lowercased() })
                        shares.append(SplitShare(
                            id: existingShare?.id ?? UUID(),
                            personName: name,
                            amountOwed: perFriendShare,
                            isSettled: existingShare?.isSettled ?? false,
                            settledAt: existingShare?.settledAt
                        ))
                    }

                    splitDetails = SplitDetails(
                        totalAmount: cleanAmount,
                        numberOfPeople: totalCount,
                        myShare: myShare,
                        splits: shares
                    )
                }
            }
        }

        let transaction = FinanceTransaction(
            id: id,
            amount: cleanAmount,
            type: type,
            category: category,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            isSplit: isSplit && (splitDetails != nil),
            splitDetails: splitDetails,
            createdAt: existing?.createdAt ?? Date(),
            updatedAt: Date()
        )

        try financeRepository.saveTransaction(transaction)
        return transaction
    }
}
