// Presentation/Finance/FriendTabDetailSheet.swift

import SwiftUI

struct FriendTabDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let friendSummary: FriendTabSummary
    let vm: FinanceViewModel
    var onAddDirectCollect: ((String) -> Void)?
    var onEditTransaction: ((FinanceTransaction) -> Void)?

    @State private var showSettleAllAlert: Bool = false
    @State private var showDeleteFriendAlert: Bool = false

    // Look up live summary to reflect immediate updates on settle/unsettle
    private var liveSummary: FriendTabSummary {
        vm.friendTabSummaries.first(where: { $0.id == friendSummary.id }) ?? friendSummary
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Friend Hero Profile Card
                    profileCard

                    // Quick Action Buttons
                    actionButtons

                    // Activity Ledger
                    activityLedgerSection
                }
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.vertical, AppLayout.sectionSpacing)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("\(liveSummary.name.uppercased())'S TAB")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .foregroundStyle(AppColor.textSecondary)
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteFriendAlert = true
                        } label: {
                            Label("Remove from Fixed Friends", systemImage: "person.crop.circle.badge.minus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.app(size: 16, weight: .bold))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
            .alert("SETTLE ALL DEBTS?", isPresented: $showSettleAllAlert) {
                Button("Settle All (\(vm.currencySymbol)\(String(format: "%.2f", liveSummary.totalOwed)))") {
                    vm.settleAllForFriend(name: liveSummary.name)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Mark all \(liveSummary.pendingCount) pending split shares from \(liveSummary.name) as fully paid back?")
            }
            .alert("REMOVE FRIEND?", isPresented: $showDeleteFriendAlert) {
                Button("Remove", role: .destructive) {
                    if let f = vm.friends.first(where: { $0.name.lowercased() == liveSummary.name.lowercased() }) {
                        vm.deleteFriend(id: f.id)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Remove \(liveSummary.name) from your fixed friends directory? Past transactions will remain recorded.")
            }
        }
    }

    // MARK: - Hero Profile Card

    private var profileCard: some View {
        BrutalistCard {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    // Initial Avatar
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(liveSummary.totalOwed > 0 ? Color(hex: "#8E44AD") : Color(hex: "#27AE60"))
                            .frame(width: 52, height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppColor.border, lineWidth: 2)
                            )

                        Text(liveSummary.name.prefix(1).uppercased())
                            .font(.app(size: 24, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(liveSummary.name)
                            .font(.app(size: 18, weight: .black, design: .monospaced))
                            .foregroundStyle(AppColor.textPrimary)

                        if liveSummary.totalOwed > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.app(size: 10))
                                Text("\(liveSummary.pendingCount) PENDING COLLECTION")
                                    .font(.app(size: 9, weight: .black, design: .monospaced))
                            }
                            .foregroundStyle(Color(hex: "#8E44AD"))
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.app(size: 10))
                                Text("ALL SETTLED UP")
                                    .font(.app(size: 9, weight: .black, design: .monospaced))
                            }
                            .foregroundStyle(Color(hex: "#27AE60"))
                        }
                    }

                    Spacer()
                }

                Divider()

                // Balance Metrics Grid
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CURRENTLY OWED")
                            .font(.app(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(AppColor.textSecondary)
                        Text(String(format: "\(vm.currencySymbol)%.2f", liveSummary.totalOwed))
                            .font(.app(size: 20, weight: .black, design: .monospaced))
                            .foregroundStyle(liveSummary.totalOwed > 0 ? Color(hex: "#8E44AD") : AppColor.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("TOTAL SETTLED")
                            .font(.app(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(AppColor.textSecondary)
                        Text(String(format: "\(vm.currencySymbol)%.2f", liveSummary.totalSettled))
                            .font(.app(size: 20, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(hex: "#27AE60"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
                onAddDirectCollect?(liveSummary.name)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.app(size: 14))
                    Text("ADD TO TAB")
                        .font(.app(size: 12, weight: .black, design: .monospaced))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(hex: "#8E44AD"))
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
                )
            }
            .buttonStyle(.plain)

            if liveSummary.totalOwed > 0 {
                Button {
                    showSettleAllAlert = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.app(size: 14))
                        Text("SETTLE ALL")
                            .font(.app(size: 12, weight: .black, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#27AE60"))
                    .foregroundStyle(Color.white)
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

    // MARK: - Activity Ledger Section

    private var activityLedgerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TAB ACTIVITY & HISTORY")
                    .font(.app(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(AppColor.textPrimary)

                Spacer()

                Text("\(liveSummary.items.count) entries")
                    .font(.app(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppColor.textSecondary)
            }

            if liveSummary.items.isEmpty {
                BrutalistCard {
                    VStack(spacing: 8) {
                        Text("📝")
                            .font(.app(size: 28))
                        Text("NO SPLITS OR DEBTS RECORDED")
                            .font(.app(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(AppColor.textPrimary)
                        Text("Tap 'ADD TO TAB' to lend money or toggle 'Split' on any expense.")
                            .font(.app(size: 11))
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(liveSummary.items, id: \.share.id) { item in
                        tabItemCard(item: item)
                    }
                }
            }
        }
    }

    private func tabItemCard(item: (transaction: FinanceTransaction, share: SplitShare)) -> some View {
        BrutalistCard {
            HStack(alignment: .center, spacing: 12) {
                // Category Emoji
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: item.transaction.category.colorHex))
                        .frame(width: 38, height: 38)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(AppColor.border, lineWidth: 1.5)
                        )

                    Text(item.transaction.category.emoji)
                        .font(.app(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.transaction.category.displayName)
                            .font(.app(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColor.textPrimary)

                        if item.share.isSettled {
                            Text("SETTLED ✅")
                                .font(.app(size: 8, weight: .black, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#27AE60").opacity(0.18))
                                .foregroundStyle(Color(hex: "#27AE60"))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }

                    if !item.transaction.note.isEmpty {
                        Text(item.transaction.note)
                            .font(.app(size: 11, weight: .medium))
                            .foregroundStyle(AppColor.textSecondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        Text(item.transaction.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.app(size: 10, design: .monospaced))
                            .foregroundStyle(AppColor.textSecondary)

                        Button {
                            dismiss()
                            onEditTransaction?(item.transaction)
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "pencil")
                                    .font(.app(size: 8, weight: .bold))
                                Text("EDIT")
                                    .font(.app(size: 9, weight: .black, design: .monospaced))
                            }
                            .foregroundStyle(Color(hex: "#8E44AD"))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(String(format: "\(vm.currencySymbol)%.2f", item.share.amountOwed))
                        .font(.app(size: 15, weight: .black, design: .monospaced))
                        .foregroundStyle(item.share.isSettled ? Color(hex: "#27AE60") : Color(hex: "#8E44AD"))

                    Button {
                        vm.settleSplit(
                            transactionId: item.transaction.id,
                            shareId: item.share.id,
                            isSettled: !item.share.isSettled
                        )
                    } label: {
                        Text(item.share.isSettled ? "UNDO" : "SETTLE")
                            .font(.app(size: 10, weight: .black, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
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
}
