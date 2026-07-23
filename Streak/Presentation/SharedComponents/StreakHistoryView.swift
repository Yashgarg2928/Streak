// Presentation/SharedComponents/StreakHistoryView.swift
// Displays the full history of streak runs plus the all-time high.

import SwiftUI

struct StreakHistoryView: View {
    let runs: [StreakRun]
    let highStreak: Int
    let accentColor: Color

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {

            // ── High Score Banner ──────────────────────────────────────
            BrutalistCard {
                HStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColor.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("ALL-TIME BEST")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(AppColor.textSecondary)
                        Text("\(highStreak) DAYS")
                            .font(.system(.title2, design: .monospaced).weight(.black))
                            .foregroundStyle(AppColor.textPrimary)
                    }

                    Spacer()

                    // Mini bar showing proportion of high-streak vs total
                    if highStreak > 0 {
                        let totalGreen = runs.reduce(0) { $0 + $1.length }
                        let fraction = totalGreen > 0 ? min(Double(highStreak) / Double(totalGreen), 1.0) : 0.0
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("OF \(totalGreen) TOTAL")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(AppColor.textSecondary)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(AppColor.surface)
                                        .frame(height: 6)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(AppColor.green)
                                        .frame(width: geo.size.width * fraction, height: 6)
                                }
                            }
                            .frame(width: 70, height: 6)
                        }
                    }
                }
            }

            // ── Run Timeline ──────────────────────────────────────────
            if runs.isEmpty {
                BrutalistCard {
                    Text("No completed streaks yet.\nKeep going — your first green day starts a streak!")
                        .font(.system(.subheadline))
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            } else {
                let maxLen = runs.map(\.length).max() ?? 1
                ForEach(Array(runs.enumerated()), id: \.element.id) { index, run in
                    runRow(run: run, maxLen: maxLen, isLatest: index == 0)
                }
            }
        }
    }

    // MARK: - Single run row

    @ViewBuilder
    private func runRow(run: StreakRun, maxLen: Int, isLatest: Bool) -> some View {
        let fraction = maxLen > 0 ? Double(run.length) / Double(maxLen) : 0.0
        let isHigh   = run.length == highStreak && highStreak > 0

        BrutalistCard(borderColor: isHigh ? AppColor.green : AppColor.border) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    // Flame icon — larger for current/best
                    Image(systemName: isHigh ? "flame.fill" : "flame")
                        .font(.system(size: isHigh ? 16 : 13, weight: .bold))
                        .foregroundStyle(isHigh ? AppColor.green : AppColor.textSecondary)

                    // Day count
                    Text("\(run.length) DAY\(run.length == 1 ? "" : "S")")
                        .font(.system(.subheadline, design: .monospaced).weight(.black))
                        .foregroundStyle(AppColor.textPrimary)

                    // Best / Current badges
                    if isHigh {
                        Text("BEST")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(AppColor.background)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AppColor.green)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    if isLatest {
                        Text("LATEST")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(AppColor.background)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AppColor.border)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Spacer()

                    // Date range
                    Text("\(dateFormatter.string(from: run.startDate)) – \(dateFormatter.string(from: run.endDate))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppColor.textSecondary)
                }

                // Progress bar relative to all-time best
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppColor.surface)
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isHigh ? AppColor.green : AppColor.textSecondary.opacity(0.5))
                            .frame(width: geo.size.width * fraction, height: 5)
                    }
                }
                .frame(height: 5)
            }
        }
    }
}
