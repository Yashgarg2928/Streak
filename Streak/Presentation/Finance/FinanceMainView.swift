// Presentation/Finance/FinanceMainView.swift

import SwiftUI

struct FinanceMainView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var vm: FinanceViewModel? = nil

    @State private var showAddTransactionSheet: Bool = false
    @State private var showShortcutsGuideSheet: Bool = false
    @State private var showSettledSplits: Bool = false

    private func getViewModel() -> FinanceViewModel {
        if let existing = vm {
            return existing
        }
        let newVM = FinanceViewModel(env: env)
        newVM.load()
        return newVM
    }

    var body: some View {
        let activeVM = getViewModel()

        NavigationStack {
            VStack(spacing: 0) {
                // Header Bar
                headerBar(vm: activeVM)
                    .padding(.horizontal, AppLayout.screenMargin)
                    .padding(.top, AppLayout.itemSpacing)

                // SubTab Picker
                subTabPicker(vm: activeVM)
                    .padding(.horizontal, AppLayout.screenMargin)
                    .padding(.top, AppLayout.itemSpacing)

                // Main Content
                ScrollView {
                    VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                        // Master Summary Card
                        summaryCard(vm: activeVM)

                        // SubTab Views
                        switch activeVM.selectedSubTab {
                        case .expenses:
                            expensesSection(vm: activeVM)
                        case .splits:
                            splitsSection(vm: activeVM)
                        case .analytics:
                            analyticsSection(vm: activeVM)
                        }
                    }
                    .padding(.horizontal, AppLayout.screenMargin)
                    .padding(.vertical, AppLayout.sectionSpacing)
                }
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddTransactionSheet) {
                AddTransactionSheet { amount, type, category, note, date, isSplit, numPeople, names, customShare in
                    activeVM.addTransaction(
                        amount: amount,
                        type: type,
                        category: category,
                        note: note,
                        date: date,
                        isSplit: isSplit,
                        numberOfPeople: numPeople,
                        friendNames: names,
                        customMyShare: customShare
                    )
                }
            }
            .sheet(isPresented: $showShortcutsGuideSheet) {
                ShortcutsSetupGuideSheet()
            }
            .onAppear {
                if vm == nil {
                    vm = FinanceViewModel(env: env)
                }
                vm?.load()
            }
        }
    }

    // MARK: - Header Bar

    private func headerBar(vm: FinanceViewModel) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("💰")
                        .font(.system(size: 22))
                    Text("FINANCE")
                        .font(.system(.title2, design: .monospaced).weight(.black))
                        .foregroundStyle(AppColor.textPrimary)
                }
                Text("Expenses, splits & debts")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    showShortcutsGuideSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11, weight: .black))
                        Text("SHORTCUTS")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#2980B9"))
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                            .stroke(AppColor.border, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showAddTransactionSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .black))
                        Text("LOG")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                    }
                    .foregroundStyle(AppColor.background)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(AppColor.border)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - SubTab Picker

    private func subTabPicker(vm: FinanceViewModel) -> some View {
        HStack(spacing: 6) {
            ForEach(FinanceSubTab.allCases) { tab in
                let isSelected = vm.selectedSubTab == tab
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        vm.selectedSubTab = tab
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(tab.emoji)
                            .font(.system(size: 13))
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? AppColor.border : AppColor.surface)
                    .foregroundStyle(isSelected ? AppColor.background : AppColor.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                            .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Master Summary Card

    private func summaryCard(vm: FinanceViewModel) -> some View {
        BrutalistCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("MONTHLY OVERVIEW")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(AppColor.textSecondary)

                    Spacer()

                    Text("CURRENCY: \(vm.currencySymbol)")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(AppColor.border, lineWidth: 1))
                }

                HStack(alignment: .top, spacing: 14) {
                    // Net Personal Spent
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MY EXPENSES")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColor.textSecondary)
                        Text(String(format: "\(vm.currencySymbol)%.2f", vm.summary.totalSpentThisMonth))
                            .font(.system(size: 22, weight: .black, design: .monospaced))
                            .foregroundStyle(AppColor.textPrimary)
                    }

                    Divider()
                        .frame(height: 38)

                    // To Collect from Friends (Splits)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("TO COLLECT")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(hex: "#8E44AD"))
                            if vm.summary.pendingSplitsCount > 0 {
                                Text("\(vm.summary.pendingSplitsCount)")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .padding(.horizontal, 4)
                                    .background(Color(hex: "#8E44AD"))
                                    .foregroundStyle(Color.white)
                                    .clipShape(Circle())
                            }
                        }
                        Text(String(format: "\(vm.currencySymbol)%.2f", vm.summary.totalPendingToCollect))
                            .font(.system(size: 22, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(hex: "#8E44AD"))
                    }
                }

                // Sub-metrics row
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text("TODAY:")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColor.textSecondary)
                        Text(String(format: "\(vm.currencySymbol)%.2f", vm.summary.totalSpentToday))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColor.textPrimary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("TOTAL OUTFLOW:")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColor.textSecondary)
                        Text(String(format: "\(vm.currencySymbol)%.2f", vm.summary.totalGrossOutflowThisMonth))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColor.textPrimary)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Expenses SubTab View

    private func expensesSection(vm: FinanceViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Search and Category Filters
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColor.textSecondary)
                    TextField("Search expenses, notes...", text: Bindable(vm).searchQuery)
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(8)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))

                if vm.selectedCategoryFilter != nil {
                    Button {
                        vm.selectedCategoryFilter = nil
                    } label: {
                        Text("RESET")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Category Chips Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(FinanceCategory.allCases) { cat in
                        let isSelected = vm.selectedCategoryFilter == cat
                        Button {
                            vm.selectedCategoryFilter = isSelected ? nil : cat
                        } label: {
                            HStack(spacing: 4) {
                                Text(cat.emoji)
                                    .font(.system(size: 11))
                                Text(cat.displayName)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(isSelected ? Color(hex: cat.colorHex) : AppColor.surface)
                            .foregroundStyle(isSelected ? Color.white : AppColor.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(AppColor.border, lineWidth: isSelected ? 2 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Transaction Cards List
            if vm.filteredTransactions.isEmpty {
                emptyExpensesView
            } else {
                VStack(spacing: 10) {
                    ForEach(vm.filteredTransactions) { tx in
                        transactionCard(tx: tx, vm: vm)
                    }
                }
            }
        }
    }

    private func transactionCard(tx: FinanceTransaction, vm: FinanceViewModel) -> some View {
        BrutalistCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 10) {
                    // Category Emoji
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: tx.category.colorHex).opacity(0.18))
                            .frame(width: 38, height: 38)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(hex: tx.category.colorHex), lineWidth: 1.5)
                            )

                        Text(tx.category.emoji)
                            .font(.system(size: 18))
                    }

                    // Title & Note
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tx.category.displayName)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColor.textPrimary)

                        if !tx.note.isEmpty {
                            Text(tx.note)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppColor.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Amount
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "\(tx.type == .income ? "+" : "-")\(vm.currencySymbol)%.2f", tx.amount))
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .foregroundStyle(tx.type == .income ? Color(hex: "#27AE60") : AppColor.textPrimary)

                        if tx.isSplit, let split = tx.splitDetails {
                            Text("My share: \(vm.currencySymbol)\(String(format: "%.2f", split.myShare))")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(hex: "#8E44AD"))
                        }
                    }
                }

                // Split Info Banner if applicable
                if tx.isSplit, let split = tx.splitDetails {
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("👥")
                                .font(.system(size: 10))
                            Text("Split with \(split.splits.count) friends")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(hex: "#8E44AD"))
                        }

                        Spacer()

                        let pending = tx.pendingCollectAmount
                        if pending > 0 {
                            Text("Pending: \(vm.currencySymbol)\(String(format: "%.2f", pending))")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#8E44AD").opacity(0.15))
                                .foregroundStyle(Color(hex: "#8E44AD"))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        } else {
                            Text("ALL SETTLED ✅")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#27AE60").opacity(0.15))
                                .foregroundStyle(Color(hex: "#27AE60"))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                // Date & Delete action
                HStack {
                    Text(tx.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppColor.textSecondary)

                    Spacer()

                    Button {
                        vm.deleteTransaction(id: tx.id)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#C0392B"))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyExpensesView: some View {
        BrutalistCard {
            VStack(spacing: 12) {
                Text("💸")
                    .font(.system(size: 40))
                Text("NO TRANSACTIONS LOGGED")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(AppColor.textPrimary)
                Text("Tap '+ LOG' or use the Shortcuts automation whenever you pay to track expenses automatically!")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    showAddTransactionSheet = true
                } label: {
                    Text("ADD FIRST EXPENSE")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppColor.border)
                        .foregroundStyle(AppColor.background)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Splits & Owed SubTab View

    private func splitsSection(vm: FinanceViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Info & Toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("WHO OWES YOU MONEY")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Track receivables from shared expenses & settle up")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColor.textSecondary)
                }

                Spacer()

                Button {
                    showSettledSplits.toggle()
                } label: {
                    Text(showSettledSplits ? "HIDE SETTLED" : "SHOW ALL")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.border, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }

            // Pending Splits List
            let allSplitItems = vm.transactions.flatMap { tx -> [(transaction: FinanceTransaction, share: SplitShare)] in
                guard tx.isSplit, let split = tx.splitDetails else { return [] }
                return split.splits.map { (transaction: tx, share: $0) }
            }

            let displayedSplits = allSplitItems.filter { item in
                showSettledSplits ? true : !item.share.isSettled
            }

            if displayedSplits.isEmpty {
                BrutalistCard {
                    VStack(spacing: 10) {
                        Text("🎉")
                            .font(.system(size: 36))
                        Text("ALL SETTLED UP!")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundStyle(AppColor.textPrimary)
                        Text("Nobody currently owes you money. Whenever you pay for friends, toggle 'Split' to track who owes you.")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(displayedSplits, id: \.share.id) { item in
                        splitShareCard(item: item, vm: vm)
                    }
                }
            }
        }
    }

    private func splitShareCard(
        item: (transaction: FinanceTransaction, share: SplitShare),
        vm: FinanceViewModel
    ) -> some View {
        BrutalistCard {
            HStack(alignment: .center, spacing: 12) {
                // Initial Avatar
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(item.share.isSettled ? Color(hex: "#27AE60") : Color(hex: "#8E44AD"))
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(AppColor.border, lineWidth: 2)
                        )

                    Text(item.share.personName.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.share.personName)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColor.textPrimary)

                        if item.share.isSettled {
                            Text("SETTLED ✅")
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#27AE60").opacity(0.18))
                                .foregroundStyle(Color(hex: "#27AE60"))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }

                    Text("For: \(item.transaction.category.displayName)\(item.transaction.note.isEmpty ? "" : " - " + item.transaction.note)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)

                    Text(item.transaction.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(AppColor.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(String(format: "\(vm.currencySymbol)%.2f", item.share.amountOwed))
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundStyle(item.share.isSettled ? Color(hex: "#27AE60") : Color(hex: "#8E44AD"))

                    Button {
                        vm.settleSplit(
                            transactionId: item.transaction.id,
                            shareId: item.share.id,
                            isSettled: !item.share.isSettled
                        )
                    } label: {
                        Text(item.share.isSettled ? "UNDO" : "SETTLE")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(item.share.isSettled ? AppColor.surface : Color(hex: "#8E44AD"))
                            .foregroundStyle(item.share.isSettled ? AppColor.textPrimary : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(AppColor.border, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Analytics SubTab View

    private func analyticsSection(vm: FinanceViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SPENDING BY CATEGORY (THIS MONTH)")
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundStyle(AppColor.textPrimary)

            let breakdown = vm.summary.categoryBreakdown.sorted { $0.value > $1.value }
            let maxAmount = breakdown.first?.value ?? 1.0

            if breakdown.isEmpty {
                BrutalistCard {
                    Text("No expense data recorded this month yet.")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColor.textSecondary)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(breakdown, id: \.key) { category, amount in
                        BrutalistCard {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    HStack(spacing: 6) {
                                        Text(category.emoji)
                                        Text(category.displayName)
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    }
                                    Spacer()
                                    Text(String(format: "\(vm.currencySymbol)%.2f", amount))
                                        .font(.system(size: 13, weight: .black, design: .monospaced))
                                }

                                // Progress bar
                                GeometryReader { geo in
                                    let fraction = max(0.04, min(1.0, amount / max(1.0, maxAmount)))
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(AppColor.surface)
                                            .frame(height: 8)

                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color(hex: category.colorHex))
                                            .frame(width: geo.size.width * fraction, height: 8)
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                    }
                }
            }
        }
    }
}
