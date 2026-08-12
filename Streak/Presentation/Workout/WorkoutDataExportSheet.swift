// Presentation/Workout/WorkoutDataExportSheet.swift

import SwiftUI

struct WorkoutDataExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let env: AppEnvironment

    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var exportedJSON: String = ""
    @State private var copied: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppLayout.itemSpacing) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("EXPORT DATE RANGE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppColor.textSecondary)

                    HStack {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                        Text("to")
                            .font(.system(.caption, weight: .bold))
                            .foregroundStyle(AppColor.textSecondary)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                            .labelsHidden()
                        Spacer()
                        Button("GENERATE") {
                            generateExport()
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppColor.background)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColor.green)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }

                if !exportedJSON.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("EXPORTED AI JSON")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppColor.textSecondary)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = exportedJSON
                                copied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copied = false
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    Text(copied ? "COPIED!" : "COPY TO CLIPBOARD")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(copied ? AppColor.green : AppColor.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
                            }
                        }

                        ScrollView {
                            Text(exportedJSON)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(AppColor.textPrimary)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(AppColor.blank)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1))
                    }
                } else {
                    Spacer()
                    Text("Select a date range and tap GENERATE to export workout & nutrition history for AI review.")
                        .font(.system(.subheadline))
                        .foregroundStyle(AppColor.textDisabled)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    Spacer()
                }

                if let errorMessage {
                    Text("⚠️ \(errorMessage)")
                        .font(.system(.caption, weight: .bold))
                        .foregroundStyle(AppColor.red)
                }
            }
            .padding(AppLayout.screenMargin)
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Export Fitness History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .onAppear {
                generateExport()
            }
        }
    }

    private func generateExport() {
        do {
            let useCase = ExportWorkoutDataUseCase(workoutRepository: env.workoutRepository, nutritionRepository: env.nutritionRepository)
            exportedJSON = try useCase.execute(startDate: startDate, endDate: endDate)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
