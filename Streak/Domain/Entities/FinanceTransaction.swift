// Domain/Entities/FinanceTransaction.swift
// Pure Swift — no UIKit, SwiftUI, or SwiftData imports

import Foundation

public enum TransactionType: String, Codable, CaseIterable {
    case expense = "EXPENSE"
    case income  = "INCOME"
}

public enum FinanceCategory: String, Codable, CaseIterable, Identifiable {
    case food          = "FOOD"
    case groceries     = "GROCERIES"
    case shopping      = "SHOPPING"
    case transport     = "TRANSPORT"
    case bills         = "BILLS"
    case entertainment = "ENTERTAINMENT"
    case health        = "HEALTH"
    case personal      = "PERSONAL"
    case investment    = "INVESTMENT"
    case other         = "OTHER"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .food:          return "Food & Dining"
        case .groceries:     return "Groceries"
        case .shopping:      return "Shopping"
        case .transport:     return "Transport & Travel"
        case .bills:         return "Bills & Utilities"
        case .entertainment: return "Entertainment"
        case .health:        return "Health & Fitness"
        case .personal:      return "Personal Care"
        case .investment:    return "Investment & Savings"
        case .other:         return "Other Expense"
        }
    }

    public var emoji: String {
        switch self {
        case .food:          return "🍔"
        case .groceries:     return "🛒"
        case .shopping:      return "🛍️"
        case .transport:     return "🚕"
        case .bills:         return "⚡"
        case .entertainment: return "🍿"
        case .health:        return "💊"
        case .personal:      return "💈"
        case .investment:    return "📈"
        case .other:         return "💸"
        }
    }

    public var colorHex: String {
        switch self {
        case .food:          return "#E67E22"
        case .groceries:     return "#27AE60"
        case .shopping:      return "#9B59B6"
        case .transport:     return "#2980B9"
        case .bills:         return "#E74C3C"
        case .entertainment: return "#F39C12"
        case .health:        return "#1ABC9C"
        case .personal:      return "#D35400"
        case .investment:    return "#2ECC71"
        case .other:         return "#7F8C8D"
        }
    }

    public var sfSymbol: String {
        switch self {
        case .food:          return "fork.knife"
        case .groceries:     return "cart.fill"
        case .shopping:      return "bag.fill"
        case .transport:     return "car.fill"
        case .bills:         return "bolt.fill"
        case .entertainment: return "film.fill"
        case .health:        return "cross.case.fill"
        case .personal:      return "person.fill"
        case .investment:    return "chart.line.uptrend.xyaxis"
        case .other:         return "creditcard.fill"
        }
    }
}

public struct SplitShare: Identifiable, Codable, Equatable {
    public let id: UUID
    public var personName: String
    public var amountOwed: Double
    public var isSettled: Bool
    public var settledAt: Date?

    public init(
        id: UUID = UUID(),
        personName: String,
        amountOwed: Double,
        isSettled: Bool = false,
        settledAt: Date? = nil
    ) {
        self.id = id
        self.personName = personName
        self.amountOwed = amountOwed
        self.isSettled = isSettled
        self.settledAt = settledAt
    }
}

public struct SplitDetails: Codable, Equatable {
    public var totalAmount: Double
    public var numberOfPeople: Int
    public var myShare: Double
    public var totalToCollect: Double
    public var splits: [SplitShare]

    public init(
        totalAmount: Double,
        numberOfPeople: Int? = nil,
        myShare: Double? = nil,
        splits: [SplitShare] = []
    ) {
        self.totalAmount = totalAmount
        let effectivePeopleCount = numberOfPeople ?? (splits.count + 1)
        self.numberOfPeople = max(1, effectivePeopleCount)
        
        let totalOwedByFriends = splits.reduce(0.0) { $0 + $1.amountOwed }
        
        if let explicitMyShare = myShare {
            self.myShare = explicitMyShare
        } else if !splits.isEmpty {
            self.myShare = max(0, totalAmount - totalOwedByFriends)
        } else {
            self.myShare = totalAmount / Double(max(1, effectivePeopleCount))
        }
        
        self.totalToCollect = !splits.isEmpty ? totalOwedByFriends : max(0, totalAmount - self.myShare)
        self.splits = splits
    }
}

public struct FinanceTransaction: Identifiable, Equatable {
    public let id: UUID
    public var amount: Double
    public var type: TransactionType
    public var category: FinanceCategory
    public var note: String
    public var date: Date
    public var isSplit: Bool
    public var splitDetails: SplitDetails?
    public let createdAt: Date
    public var updatedAt: Date

    /// The net personal expense of the user. If split, it is `myShare`. Otherwise, full `amount`.
    public var personalAmount: Double {
        if isSplit, let split = splitDetails {
            return split.myShare
        }
        return amount
    }

    /// Total amount currently pending collection from friends for this transaction.
    public var pendingCollectAmount: Double {
        guard isSplit, let split = splitDetails else { return 0 }
        return split.splits.filter { !$0.isSettled }.reduce(0) { $0 + $1.amountOwed }
    }

    public init(
        id: UUID = UUID(),
        amount: Double,
        type: TransactionType = .expense,
        category: FinanceCategory = .food,
        note: String = "",
        date: Date = Date(),
        isSplit: Bool = false,
        splitDetails: SplitDetails? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.category = category
        self.note = note
        self.date = date
        self.isSplit = isSplit
        self.splitDetails = splitDetails
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct FinanceSummary: Equatable {
    public var totalSpentThisMonth: Double
    public var totalSpentToday: Double
    public var totalGrossOutflowThisMonth: Double
    public var totalPendingToCollect: Double
    public var pendingSplitsCount: Int
    public var categoryBreakdown: [FinanceCategory: Double]

    public init(
        totalSpentThisMonth: Double = 0,
        totalSpentToday: Double = 0,
        totalGrossOutflowThisMonth: Double = 0,
        totalPendingToCollect: Double = 0,
        pendingSplitsCount: Int = 0,
        categoryBreakdown: [FinanceCategory: Double] = [:]
    ) {
        self.totalSpentThisMonth = totalSpentThisMonth
        self.totalSpentToday = totalSpentToday
        self.totalGrossOutflowThisMonth = totalGrossOutflowThisMonth
        self.totalPendingToCollect = totalPendingToCollect
        self.pendingSplitsCount = pendingSplitsCount
        self.categoryBreakdown = categoryBreakdown
    }
}
