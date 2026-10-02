// Presentation/Finance/AddTransactionSheet.swift

import SwiftUI

struct AddTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env

    var onSave: ((Double, TransactionType, FinanceCategory, String, Date, Bool, Int, [String], Double?) -> Void)?

    @State private var amountString: String = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategory: FinanceCategory = .food
    @State private var note: String = ""
    @State private var date: Date = Date()

    // Split state
    @State private var isSplit: Bool = false
    @State private var numberOfPeople: Int = 3
    @State private var friendNamesText: String = ""
    @State private var isCustomMyShare: Bool = false
    @State private var customMyShareString: String = ""

    init(
        onSave: ((Double, TransactionType, FinanceCategory, String, Date, Bool, Int, [String], Double?) -> Void)? = nil
    ) {
        self.onSave = onSave
    }

    private var currency: String {
        env.settingsRepository.currencySymbol
    }

    private var parsedAmount: Double {
        Double(amountString.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var myShareCalculated: Double {
        if isCustomMyShare, let custom = Double(customMyShareString.replacingOccurrences(of: ",", with: ".")) {
            return custom
        }
        let count = max(1, numberOfPeople)
        return parsedAmount / Double(count)
    }

    private var toCollectCalculated: Double {
        max(0, parsedAmount - myShareCalculated)
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

                    // Save Button
                    saveButton
                        .padding(.top, 10)
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.vertical, AppLayout.sectionSpacing)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("LOG TRANSACTION")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .foregroundStyle(AppColor.textSecondary)
                }
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
                            Text("Auto-calculate shares & record who owes you")
                                .font(.system(size: 11))
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                }
                .tint(Color(hex: "#8E44AD"))
            }

            // Split Configuration Box (shown when isSplit == true)
            if isSplit {
                VStack(alignment: .leading, spacing: 12) {
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

                    // Live Split Calculation Box
                    if parsedAmount > 0 {
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

                            Text("(\(currency)\(String(format: "%.2f", perFriendShareCalculated)) from each of the \(max(1, numberOfPeople - 1)) friends)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AppColor.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(12)
                        .background(Color(hex: "#8E44AD").opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "#8E44AD"), lineWidth: 1.5)
                        )
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            guard parsedAmount > 0 else { return }

            let friendNames = friendNamesText
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            let customShare: Double? = isCustomMyShare ? Double(customMyShareString) : nil

            onSave?(
                parsedAmount,
                selectedType,
                selectedCategory,
                note,
                date,
                isSplit,
                numberOfPeople,
                friendNames,
                customShare
            )
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("SAVE TRANSACTION")
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
}
