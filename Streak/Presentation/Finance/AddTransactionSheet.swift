// Presentation/Finance/AddTransactionSheet.swift

import SwiftUI

enum SplitMode: String, CaseIterable, Identifiable {
    case equal = "EQUAL"
    case custom = "CUSTOM"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .equal:  return "DIVIDE EQUALLY"
        case .custom: return "CUSTOM AMOUNTS"
        }
    }
}

struct CustomFriendItem: Identifiable, Equatable {
    let id: UUID
    var name: String
    var amountString: String
    var isSettled: Bool
    var settledAt: Date?

    var amount: Double {
        Double(amountString.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        amountString: String = "",
        isSettled: Bool = false,
        settledAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.amountString = amountString
        self.isSettled = isSettled
        self.settledAt = settledAt
    }
}

struct AddTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env

    var transactionToEdit: FinanceTransaction?
    var onSave: ((
        _ id: UUID?,
        _ amount: Double,
        _ type: TransactionType,
        _ category: FinanceCategory,
        _ note: String,
        _ date: Date,
        _ isSplit: Bool,
        _ numberOfPeople: Int,
        _ friendNames: [String],
        _ customMyShare: Double?,
        _ customFriendShares: [SplitShare]?
    ) -> Void)?
    var onDelete: ((_ id: UUID) -> Void)?

    @State private var amountString: String
    @State private var selectedType: TransactionType
    @State private var selectedCategory: FinanceCategory
    @State private var note: String
    @State private var date: Date

    // Split state
    @State private var isSplit: Bool
    @State private var splitMode: SplitMode
    @State private var numberOfPeople: Int
    @State private var friendNamesText: String
    @State private var isCustomMyShare: Bool
    @State private var customMyShareString: String

    // Custom friends list for Custom Split Mode
    @State private var customFriends: [CustomFriendItem]

    @State private var showDeleteConfirmation: Bool = false

    init(
        transactionToEdit: FinanceTransaction? = nil,
        onSave: ((
            _ id: UUID?,
            _ amount: Double,
            _ type: TransactionType,
            _ category: FinanceCategory,
            _ note: String,
            _ date: Date,
            _ isSplit: Bool,
            _ numberOfPeople: Int,
            _ friendNames: [String],
            _ customMyShare: Double?,
            _ customFriendShares: [SplitShare]?
        ) -> Void)? = nil,
        onDelete: ((_ id: UUID) -> Void)? = nil
    ) {
        self.transactionToEdit = transactionToEdit
        self.onSave = onSave
        self.onDelete = onDelete

        if let tx = transactionToEdit {
            let amountVal = tx.amount
            if amountVal.truncatingRemainder(dividingBy: 1) == 0 {
                _amountString = State(initialValue: String(format: "%.0f", amountVal))
            } else {
                _amountString = State(initialValue: String(format: "%.2f", amountVal))
            }

            _selectedType = State(initialValue: tx.type)
            _selectedCategory = State(initialValue: tx.category)
            _note = State(initialValue: tx.note)
            _date = State(initialValue: tx.date)
            _isSplit = State(initialValue: tx.isSplit)

            if let split = tx.splitDetails, !split.splits.isEmpty {
                let shares = split.splits
                let isAllEqual = shares.allSatisfy { abs($0.amountOwed - (shares.first?.amountOwed ?? 0)) < 0.01 }
                if isAllEqual && abs((shares.first?.amountOwed ?? 0) - split.myShare) < 0.01 {
                    _splitMode = State(initialValue: .equal)
                    _numberOfPeople = State(initialValue: split.numberOfPeople)
                    _friendNamesText = State(initialValue: shares.map { $0.personName }.joined(separator: ", "))
                    _isCustomMyShare = State(initialValue: false)
                    _customMyShareString = State(initialValue: "")
                    _customFriends = State(initialValue: shares.map {
                        CustomFriendItem(
                            id: $0.id,
                            name: $0.personName,
                            amountString: String(format: "%.2f", $0.amountOwed),
                            isSettled: $0.isSettled,
                            settledAt: $0.settledAt
                        )
                    })
                } else {
                    _splitMode = State(initialValue: .custom)
                    _numberOfPeople = State(initialValue: split.numberOfPeople)
                    _friendNamesText = State(initialValue: shares.map { $0.personName }.joined(separator: ", "))
                    _isCustomMyShare = State(initialValue: true)
                    _customMyShareString = State(initialValue: String(format: "%.2f", split.myShare))
                    _customFriends = State(initialValue: shares.map {
                        CustomFriendItem(
                            id: $0.id,
                            name: $0.personName,
                            amountString: String(format: "%.2f", $0.amountOwed),
                            isSettled: $0.isSettled,
                            settledAt: $0.settledAt
                        )
                    })
                }
            } else {
                _splitMode = State(initialValue: .equal)
                _numberOfPeople = State(initialValue: 3)
                _friendNamesText = State(initialValue: "")
                _isCustomMyShare = State(initialValue: false)
                _customMyShareString = State(initialValue: "")
                _customFriends = State(initialValue: [
                    CustomFriendItem(name: "Friend 1", amountString: ""),
                    CustomFriendItem(name: "Friend 2", amountString: "")
                ])
            }
        } else {
            _amountString = State(initialValue: "")
            _selectedType = State(initialValue: .expense)
            _selectedCategory = State(initialValue: .food)
            _note = State(initialValue: "")
            _date = State(initialValue: Date())
            _isSplit = State(initialValue: false)
            _splitMode = State(initialValue: .equal)
            _numberOfPeople = State(initialValue: 3)
            _friendNamesText = State(initialValue: "")
            _isCustomMyShare = State(initialValue: false)
            _customMyShareString = State(initialValue: "")
            _customFriends = State(initialValue: [
                CustomFriendItem(name: "Friend 1", amountString: ""),
                CustomFriendItem(name: "Friend 2", amountString: "")
            ])
        }
    }

    private var isEditing: Bool {
        transactionToEdit != nil
    }

    private var currency: String {
        env.settingsRepository.currencySymbol
    }

    private var parsedAmount: Double {
        Double(amountString.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var customFriendsTotal: Double {
        customFriends.reduce(0.0) { $0 + $1.amount }
    }

    private var myShareCalculated: Double {
        if isCustomMyShare, let custom = Double(customMyShareString.replacingOccurrences(of: ",", with: ".")) {
            return custom
        }
        if splitMode == .custom {
            return max(0, parsedAmount - customFriendsTotal)
        } else {
            let count = max(1, numberOfPeople)
            return parsedAmount / Double(count)
        }
    }

    private var toCollectCalculated: Double {
        if splitMode == .custom {
            return customFriendsTotal
        } else {
            return max(0, parsedAmount - myShareCalculated)
        }
    }

    private var perFriendShareCalculated: Double {
        let friendsCount = max(1, numberOfPeople - 1)
        return toCollectCalculated / Double(friendsCount)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Type Switcher (EXPENSE vs INCOME)
                    typePicker

                    // Big Amount Input
                    amountSection

                    // Category Selector
                    categorySection

                    // Note Input
                    noteSection

                    // Date Picker
                    dateSection

                    // Split Section
                    if selectedType == .expense {
                        splitSection
                    }

                    // Save / Update Button
                    saveButton
                        .padding(.top, 10)

                    // Delete Button (if editing)
                    if isEditing {
                        deleteSection
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.vertical, AppLayout.sectionSpacing)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle(isEditing ? "EDIT TRANSACTION" : "LOG TRANSACTION")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .foregroundStyle(AppColor.textSecondary)
                }

                if isEditing {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color(hex: "#C0392B"))
                        }
                    }
                }
            }
            .confirmationDialog(
                "Delete this transaction?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Expense", role: .destructive) {
                    if let tx = transactionToEdit {
                        onDelete?(tx.id)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this expense? Any friend receivables from this split will also be removed.")
            }
        }
    }

    // MARK: - Type Picker

    private var typePicker: some View {
        HStack(spacing: 8) {
            Button {
                selectedType = .expense
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.right.circle.fill")
                    Text("EXPENSE")
                }
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selectedType == .expense ? Color(hex: "#C0392B") : AppColor.surface)
                .foregroundStyle(selectedType == .expense ? Color.white : AppColor.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
                )
            }
            .buttonStyle(.plain)

            Button {
                selectedType = .income
                isSplit = false
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.left.circle.fill")
                    Text("INCOME")
                }
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selectedType == .income ? Color(hex: "#27AE60") : AppColor.surface)
                .foregroundStyle(selectedType == .income ? Color.white : AppColor.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        BrutalistCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("AMOUNT")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(AppColor.textSecondary)

                HStack(spacing: 8) {
                    Text(currency)
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundStyle(AppColor.textPrimary)

                    TextField("0.00", text: $amountString)
                        .font(.system(size: 36, weight: .black, design: .monospaced))
                        .foregroundStyle(AppColor.textPrimary)
                        .keyboardType(.decimalPad)
                }
            }
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CATEGORY")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(AppColor.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FinanceCategory.allCases) { cat in
                        let isSelected = selectedCategory == cat
                        Button {
                            selectedCategory = cat
                        } label: {
                            HStack(spacing: 6) {
                                Text(cat.emoji)
                                    .font(.system(size: 15))
                                Text(cat.displayName)
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color(hex: cat.colorHex) : AppColor.surface)
                            .foregroundStyle(isSelected ? Color.white : AppColor.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(AppColor.border, lineWidth: isSelected ? 2.5 : 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Note Section

    private var noteSection: some View {
        BrutalistCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("NOTE / DESCRIPTION")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(AppColor.textSecondary)

                TextField("e.g. Dinner with team, Blinkit groceries...", text: $note)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
            }
        }
    }

    // MARK: - Date Section

    private var dateSection: some View {
        BrutalistCard {
            HStack {
                Text("TRANSACTION DATE")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                DatePicker("", selection: $date, displayedComponents: [.date])
                    .labelsHidden()
            }
        }
    }

    // MARK: - Split Section

    private var splitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Split Toggle Card
            BrutalistCard {
                Toggle(isOn: $isSplit) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: "#8E44AD"))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(AppColor.border, lineWidth: 2)
                                )
                            Text("👥")
                                .font(.system(size: 16))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("SPLIT WITH FRIENDS")
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                                .foregroundStyle(AppColor.textPrimary)
                            Text("Divide equally or set custom amounts per friend")
                                .font(.system(size: 11))
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                }
                .tint(Color(hex: "#8E44AD"))
            }

            // Split Configuration (shown when isSplit == true)
            if isSplit {
                VStack(alignment: .leading, spacing: 12) {
                    // Split Mode Switcher (EQUAL vs CUSTOM AMOUNTS)
                    splitModePicker

                    if splitMode == .equal {
                        equalSplitControls
                    } else {
                        customSplitControls
                    }

                    // Live Split Calculation Box
                    if parsedAmount > 0 {
                        liveSplitBreakdown
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Split Mode Picker

    private var splitModePicker: some View {
        HStack(spacing: 8) {
            Button {
                switchToEqualMode()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "equal")
                    Text("DIVIDE EQUALLY")
                }
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(splitMode == .equal ? Color(hex: "#8E44AD") : AppColor.surface)
                .foregroundStyle(splitMode == .equal ? Color.white : AppColor.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
            }
            .buttonStyle(.plain)

            Button {
                switchToCustomMode()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                    Text("CUSTOM AMOUNTS")
                }
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(splitMode == .custom ? Color(hex: "#8E44AD") : AppColor.surface)
                .foregroundStyle(splitMode == .custom ? Color.white : AppColor.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
    }

    private func switchToEqualMode() {
        splitMode = .equal
        let names = customFriends.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if !names.isEmpty {
            friendNamesText = names.joined(separator: ", ")
            numberOfPeople = names.count + 1
        }
    }

    private func switchToCustomMode() {
        splitMode = .custom
        let names = friendNamesText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !names.isEmpty {
            customFriends = names.map { CustomFriendItem(name: $0, amountString: "") }
        } else if customFriends.isEmpty {
            customFriends = [
                CustomFriendItem(name: "Friend 1", amountString: ""),
                CustomFriendItem(name: "Friend 2", amountString: "")
            ]
        }
    }

    // MARK: - Equal Split Controls

    private var equalSplitControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Number of people Stepper
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TOTAL PEOPLE")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(AppColor.textSecondary)
                    Text("You + \(max(1, numberOfPeople - 1)) friends")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        if numberOfPeople > 2 { numberOfPeople -= 1 }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .black))
                            .frame(width: 34, height: 34)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 2))
                    }
                    .buttonStyle(.plain)

                    Text("\(numberOfPeople)")
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .frame(minWidth: 24)

                    Button {
                        if numberOfPeople < 20 { numberOfPeople += 1 }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .black))
                            .frame(width: 34, height: 34)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: AppLayout.cornerRadius).stroke(AppColor.border, lineWidth: AppLayout.borderWidth))

            // Friend Names text field
            VStack(alignment: .leading, spacing: 4) {
                Text("FRIEND NAMES (OPTIONAL, COMMA-SEPARATED)")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(AppColor.textSecondary)

                TextField("e.g. Rohan, Aman, Priya", text: $friendNamesText)
                    .font(.system(size: 13, weight: .semibold))
                    .padding(10)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
            }
        }
    }

    // MARK: - Custom Split Controls & Tools

    private var customSplitControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Split Tools Toolbar
            splitToolsToolbar

            // Friends list with individual amount inputs
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("FRIENDS & CUSTOM AMOUNTS")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer()
                    Text("\(customFriends.count) friends")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppColor.textSecondary)
                }

                ForEach($customFriends) { $friend in
                    friendCustomRow(friend: $friend)
                }

                // Add Friend Button
                Button {
                    customFriends.append(CustomFriendItem(name: "Friend \(customFriends.count + 1)", amountString: ""))
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 13))
                        Text("ADD ANOTHER FRIEND")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#8E44AD").opacity(0.08))
                    .foregroundStyle(Color(hex: "#8E44AD"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: "#8E44AD"), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Split Tools Toolbar

    private var splitToolsToolbar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🛠️ CUSTOM SPLIT TOOLS")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: "#8E44AD"))
                Spacer()
                Text("Quick helpers")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppColor.textSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Tool 1: Split Remainder
                    Button {
                        splitRemainder()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 11))
                            Text("Split Remainder")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color(hex: "#8E44AD").opacity(0.12))
                        .foregroundStyle(Color(hex: "#8E44AD"))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#8E44AD"), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)

                    // Tool 2: Split Evenly
                    Button {
                        splitEvenly()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "equal.circle")
                                .font(.system(size: 11))
                            Text("Split Evenly")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(AppColor.surface)
                        .foregroundStyle(AppColor.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)

                    // Tool 3: Clear Amounts
                    Button {
                        clearAmounts()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11))
                            Text("Clear Amounts")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(AppColor.surface)
                        .foregroundStyle(Color(hex: "#C0392B"))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: AppLayout.cornerRadius).stroke(AppColor.border, lineWidth: AppLayout.borderWidth))
    }

    private func splitRemainder() {
        let currentFriendsTotal = customFriends.reduce(0.0) { $0 + $1.amount }
        let currentMyShare = isCustomMyShare ? (Double(customMyShareString) ?? 0) : 0
        let unallocated = max(0, parsedAmount - (currentFriendsTotal + currentMyShare))
        guard unallocated > 0, !customFriends.isEmpty else { return }

        // Find friends with zero amount, or apply across all friends if none are zero
        let zeroIndices = customFriends.indices.filter { customFriends[$0].amount <= 0 }
        let targetIndices = zeroIndices.isEmpty ? Array(customFriends.indices) : zeroIndices
        let perFriend = unallocated / Double(targetIndices.count)

        for idx in targetIndices {
            let newAmount = zeroIndices.isEmpty ? (customFriends[idx].amount + perFriend) : perFriend
            customFriends[idx].amountString = String(format: "%.2f", newAmount)
        }
    }

    private func splitEvenly() {
        guard parsedAmount > 0, !customFriends.isEmpty else { return }
        let totalPeople = customFriends.count + 1
        let evenShare = parsedAmount / Double(totalPeople)
        for idx in customFriends.indices {
            customFriends[idx].amountString = String(format: "%.2f", evenShare)
        }
        isCustomMyShare = false
        customMyShareString = ""
    }

    private func clearAmounts() {
        for idx in customFriends.indices {
            customFriends[idx].amountString = ""
        }
        isCustomMyShare = false
        customMyShareString = ""
    }

    // MARK: - Friend Custom Row

    private func friendCustomRow(friend: Binding<CustomFriendItem>) -> some View {
        HStack(spacing: 8) {
            // Initial avatar
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: "#8E44AD").opacity(0.18))
                    .frame(width: 32, height: 32)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#8E44AD"), lineWidth: 1.5))
                Text(friend.wrappedValue.name.isEmpty ? "👤" : String(friend.wrappedValue.name.prefix(1)).uppercased())
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: "#8E44AD"))
            }

            // Name field
            TextField("Friend name", text: friend.name)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .padding(8)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
                .frame(maxWidth: .infinity)

            // Amount field with currency symbol
            HStack(spacing: 4) {
                Text(currency)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: "#8E44AD"))
                TextField("0.00", text: friend.amountString)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .keyboardType(.decimalPad)
                    .frame(width: 72)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(Color(hex: "#8E44AD").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#8E44AD"), lineWidth: 1.5))

            // Settled Status badge if friend already settled
            if friend.wrappedValue.isSettled {
                Text("PAID")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#27AE60").opacity(0.15))
                    .foregroundStyle(Color(hex: "#27AE60"))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }

            // Delete Friend Button
            if customFriends.count > 1 {
                Button {
                    if let index = customFriends.firstIndex(where: { $0.id == friend.wrappedValue.id }) {
                        customFriends.remove(at: index)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#C0392B"))
                        .frame(width: 30, height: 30)
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Live Split Breakdown

    private var liveSplitBreakdown: some View {
        VStack(spacing: 8) {
            HStack {
                Text("SPLIT BREAKDOWN")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: "#8E44AD"))
                Spacer()
                Text("Total: \(currency)\(String(format: "%.2f", parsedAmount))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
            }

            Divider()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("YOUR SHARE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppColor.textSecondary)
                    Text("\(currency)\(String(format: "%.2f", myShareCalculated))")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundStyle(AppColor.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("TO COLLECT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#8E44AD"))
                    Text("\(currency)\(String(format: "%.2f", toCollectCalculated))")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(hex: "#8E44AD"))
                }
            }

            if splitMode == .custom {
                let diff = parsedAmount - (myShareCalculated + customFriendsTotal)
                if abs(diff) < 0.01 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("100% accounted for (Balanced)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(Color(hex: "#27AE60"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if diff > 0.01 {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 10))
                        Text("\(currency)\(String(format: "%.2f", diff)) remainder (Added to your share)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(Color(hex: "#2980B9"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                        Text("Custom amounts recorded (Collection: \(currency)\(String(format: "%.2f", customFriendsTotal)))")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(Color(hex: "#8E44AD"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text("(\(currency)\(String(format: "%.2f", perFriendShareCalculated)) from each of the \(max(1, numberOfPeople - 1)) friends)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(Color(hex: "#8E44AD").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "#8E44AD"), lineWidth: 1.5)
        )
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            guard parsedAmount > 0 else { return }

            let targetId = transactionToEdit?.id

            if isSplit {
                if splitMode == .custom {
                    let validFriends = customFriends
                        .filter { $0.amount > 0 || !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                        .enumerated()
                        .map { (index, item) in
                            let cleanName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
                            let finalName = cleanName.isEmpty ? "Friend \(index + 1)" : cleanName
                            return SplitShare(
                                id: item.id,
                                personName: finalName,
                                amountOwed: item.amount,
                                isSettled: item.isSettled,
                                settledAt: item.settledAt
                            )
                        }

                    let effectiveShares = validFriends.isEmpty ? [SplitShare(personName: "Friend 1", amountOwed: 0)] : validFriends
                    let customShare = isCustomMyShare ? Double(customMyShareString) : myShareCalculated

                    onSave?(
                        targetId,
                        parsedAmount,
                        selectedType,
                        selectedCategory,
                        note,
                        date,
                        true,
                        effectiveShares.count + 1,
                        [],
                        customShare,
                        effectiveShares
                    )
                } else {
                    let friendNames = friendNamesText
                        .components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }

                    let customShare: Double? = isCustomMyShare ? Double(customMyShareString) : nil

                    onSave?(
                        targetId,
                        parsedAmount,
                        selectedType,
                        selectedCategory,
                        note,
                        date,
                        true,
                        numberOfPeople,
                        friendNames,
                        customShare,
                        nil
                    )
                }
            } else {
                onSave?(
                    targetId,
                    parsedAmount,
                    selectedType,
                    selectedCategory,
                    note,
                    date,
                    false,
                    1,
                    [],
                    nil,
                    nil
                )
            }
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isEditing ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                Text(isEditing ? "UPDATE TRANSACTION" : "SAVE TRANSACTION")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(parsedAmount > 0 ? AppColor.border : AppColor.border.opacity(0.4))
            .foregroundStyle(AppColor.background)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
        }
        .disabled(parsedAmount <= 0)
    }

    // MARK: - Delete Section (Edit Mode Only)

    private var deleteSection: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("DELETE TRANSACTION")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(hex: "#C0392B").opacity(0.1))
            .foregroundStyle(Color(hex: "#C0392B"))
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(Color(hex: "#C0392B"), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
