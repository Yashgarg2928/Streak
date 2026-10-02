// App/FinanceAppIntents.swift
// Siri & Shortcuts integration for instant expense tracking and automated payment alerts.

import Foundation
import AppIntents
import SwiftUI
import SwiftData

// MARK: - Finance Category App Enum for Siri & Shortcuts

public enum FinanceCategoryAppEnum: String, AppEnum {
    case food          = "Food & Dining"
    case groceries     = "Groceries"
    case shopping      = "Shopping"
    case transport     = "Transport & Fuel"
    case bills         = "Bills & Utilities"
    case entertainment = "Entertainment"
    case health        = "Health & Fitness"
    case personal      = "Personal Care"
    case investment    = "Investment & Savings"
    case other         = "Other Expense"

    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Expense Category"
    public static var caseDisplayRepresentations: [FinanceCategoryAppEnum: DisplayRepresentation] = [
        .food: DisplayRepresentation(
            title: "Food & Dining",
            subtitle: "Restaurants, cafes, takeout, snacks",
            synonyms: ["food", "dining", "dinner", "lunch", "breakfast", "restaurant", "cafe", "coffee", "swiggy", "zomato", "eat"]
        ),
        .groceries: DisplayRepresentation(
            title: "Groceries",
            subtitle: "Supermarket, vegetables, daily essentials",
            synonyms: ["groceries", "grocery", "blinkit", "zepto", "instamart", "supermarket", "veggies", "milk"]
        ),
        .shopping: DisplayRepresentation(
            title: "Shopping",
            subtitle: "Clothes, electronics, Amazon, gifts",
            synonyms: ["shopping", "amazon", "flipkart", "myntra", "clothes", "gadgets", "shoes"]
        ),
        .transport: DisplayRepresentation(
            title: "Transport & Travel",
            subtitle: "Uber, Ola, metro, flights, fuel",
            synonyms: ["transport", "travel", "uber", "ola", "auto", "metro", "cab", "petrol", "fuel", "flight", "train"]
        ),
        .bills: DisplayRepresentation(
            title: "Bills & Utilities",
            subtitle: "Electricity, wifi, rent, subscriptions",
            synonyms: ["bills", "bill", "utilities", "electricity", "rent", "wifi", "broadband", "mobile recharge", "subscription"]
        ),
        .entertainment: DisplayRepresentation(
            title: "Entertainment",
            subtitle: "Movies, concerts, Netflix, outings",
            synonyms: ["entertainment", "movie", "cinema", "netflix", "party", "games", "outing", "club"]
        ),
        .health: DisplayRepresentation(
            title: "Health & Fitness",
            subtitle: "Medicine, doctor, gym, supplements",
            synonyms: ["health", "fitness", "gym", "medicine", "doctor", "pharmacy", "supplements", "hospital"]
        ),
        .personal: DisplayRepresentation(
            title: "Personal Care",
            subtitle: "Salon, grooming, skincare",
            synonyms: ["personal", "grooming", "salon", "barber", "haircut", "skincare", "spa"]
        ),
        .investment: DisplayRepresentation(
            title: "Investment & Savings",
            subtitle: "Stocks, mutual funds, crypto, savings",
            synonyms: ["investment", "savings", "stocks", "mutual funds", "crypto", "gold", "sip"]
        ),
        .other: DisplayRepresentation(
            title: "Other Expense",
            subtitle: "Miscellaneous spending",
            synonyms: ["other", "misc", "miscellaneous", "general"]
        )
    ]

    public var domainCategory: FinanceCategory {
        switch self {
        case .food:          return .food
        case .groceries:     return .groceries
        case .shopping:      return .shopping
        case .transport:     return .transport
        case .bills:         return .bills
        case .entertainment: return .entertainment
        case .health:        return .health
        case .personal:      return .personal
        case .investment:    return .investment
        case .other:         return .other
        }
    }
}

// MARK: - Shared Finance Intent Service

enum StreakFinanceIntentService {
    @MainActor
    static func recordExpense(
        amount: Double,
        category: FinanceCategoryAppEnum,
        note: String,
        isSplit: Bool,
        numberOfPeople: Int,
        friendNames: String?
    ) throws -> (transaction: FinanceTransaction, snippet: ExpenseAddedSiriSnippetView, dialog: String) {
        let container = try ModelContainerFactory.makeContainer()
        let ctx = container.mainContext
        let repo = SwiftDataFinanceRepository(context: ctx)
        let settings = UserDefaultsSettingsRepository()
        let currency = settings.currencySymbol

        let parsedNames: [String]
        if let friendNames, !friendNames.isEmpty {
            parsedNames = friendNames.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        } else {
            parsedNames = []
        }

        let useCase = LogTransactionUseCase(financeRepository: repo)
        let transaction = try useCase.execute(
            amount: amount,
            type: .expense,
            category: category.domainCategory,
            note: note,
            date: Date(),
            isSplit: isSplit,
            numberOfPeople: numberOfPeople,
            friendNames: parsedNames
        )

        let formattedAmount = String(format: "\(currency)%.2f", amount)
        let dialogText: String
        if transaction.isSplit, let split = transaction.splitDetails {
            let myShareFormatted = String(format: "\(currency)%.2f", split.myShare)
            let toCollectFormatted = String(format: "\(currency)%.2f", split.totalToCollect)
            dialogText = "Logged \(formattedAmount) in \(category.rawValue). Your share is \(myShareFormatted), and you need to collect \(toCollectFormatted) from \(split.splits.count) friends."
        } else {
            dialogText = "Logged \(formattedAmount) for \(category.rawValue) in Streak!"
        }

        let snippet = ExpenseAddedSiriSnippetView(
            transaction: transaction,
            currencySymbol: currency
        )

        return (transaction, snippet, dialogText)
    }
}

// MARK: - Full Log Expense Intent (Siri / Action Button / Back Tap)

public struct LogExpenseIntent: AppIntent {
    public static var title: LocalizedStringResource = "Log Expense in Streak"
    public static var description = IntentDescription("Log an expense, calculate splits, and track money owed without opening the app.")

    // Runs in the background window at the top of the iPhone
    public static var openAppWhenRun: Bool = false

    @Parameter(title: "Amount", requestValueDialog: "How much did you spend?")
    public var amount: Double

    @Parameter(title: "Category", default: .food, requestValueDialog: "Which category?")
    public var category: FinanceCategoryAppEnum

    @Parameter(title: "Note / Description", default: "")
    public var note: String

    @Parameter(title: "Split with anyone?", default: false)
    public var isSplit: Bool

    @Parameter(title: "Total People (Including You)", default: 1)
    public var splitCount: Int

    @Parameter(title: "Friend Names (Optional, Comma Separated)", default: "")
    public var splitNames: String

    public static var parameterSummary: some ParameterSummary {
        Summary("Log expense of \(\.$amount) in \(\.$category)") {
            \.$note
            \.$isSplit
            \.$splitCount
            \.$splitNames
        }
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some ProvidesDialog & ShowsSnippetView {
        let result = try StreakFinanceIntentService.recordExpense(
            amount: amount,
            category: category,
            note: note,
            isSplit: isSplit,
            numberOfPeople: splitCount,
            friendNames: splitNames.isEmpty ? nil : splitNames
        )

        return .result(
            dialog: IntentDialog(stringLiteral: result.dialog),
            view: result.snippet
        )
    }
}

// MARK: - Quick 1-Tap Log Expense Intent (For Automation on Payment App Closed)

public struct QuickLogExpenseIntent: AppIntent {
    public static var title: LocalizedStringResource = "Quick Log Expense"
    public static var description = IntentDescription("Instantly prompts for amount and category to log an expense when closing payment apps.")

    // Runs directly in the top modal banner
    public static var openAppWhenRun: Bool = false

    @Parameter(title: "Amount", requestValueDialog: "How much was the payment?")
    public var amount: Double

    @Parameter(title: "Category", default: .food, requestValueDialog: "Category?")
    public var category: FinanceCategoryAppEnum

    @Parameter(title: "Note (Optional)", default: "")
    public var note: String

    public static var parameterSummary: some ParameterSummary {
        Summary("Quick log \(\.$amount) in \(\.$category)") {
            \.$note
        }
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some ProvidesDialog & ShowsSnippetView {
        let result = try StreakFinanceIntentService.recordExpense(
            amount: amount,
            category: category,
            note: note,
            isSplit: false,
            numberOfPeople: 1,
            friendNames: nil
        )

        return .result(
            dialog: IntentDialog(stringLiteral: result.dialog),
            view: result.snippet
        )
    }
}

// MARK: - Visual Snippet View shown in Top Window Banner

public struct ExpenseAddedSiriSnippetView: View {
    public let transaction: FinanceTransaction
    public let currencySymbol: String

    private var categoryColor: Color {
        Color(hex: transaction.category.colorHex)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                // Category Icon Badge
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(categoryColor)
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "#1A1A1A"), lineWidth: 2)
                        )

                    Text(transaction.category.emoji)
                        .font(.system(size: 22))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(String(format: "\(currencySymbol)%.2f", transaction.amount))
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(hex: "#1A1A1A"))

                        Text(transaction.category.displayName.uppercased())
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#1A1A1A"))
                            .foregroundStyle(Color(hex: "#F5F0E8"))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    if !transaction.note.isEmpty {
                        Text(transaction.note)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "#4A4A4A"))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: "#2D7A2D"))
            }

            // Split breakdown details if split
            if transaction.isSplit, let split = transaction.splitDetails {
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("MY SHARE:")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "#4A4A4A"))
                        Text(String(format: "\(currencySymbol)%.2f", split.myShare))
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(hex: "#1A1A1A"))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#EFEFDF"))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                    HStack(spacing: 4) {
                        Text("TO COLLECT:")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "#8E44AD"))
                        Text(String(format: "\(currencySymbol)%.2f", split.totalToCollect))
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(hex: "#8E44AD"))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#8E44AD").opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                    Spacer()

                    Text("\(split.splits.count) friends")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#4A4A4A"))
                }
            }
        }
        .padding(14)
        .background(Color(hex: "#F5F0E8"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#1A1A1A"), lineWidth: 2)
        )
        .padding(6)
    }
}
