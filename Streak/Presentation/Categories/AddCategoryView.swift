// Presentation/Categories/AddCategoryView.swift

import SwiftUI

struct AddCategoryView: View {
    var editingId: UUID? = nil
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    @State private var name: String = ""
    @State private var selectedColor: Color = .blue
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                // Name field
                VStack(alignment: .leading, spacing: 6) {
                    Text("NAME")
                        .font(.system(.caption).weight(.semibold))
                        .foregroundStyle(AppColor.textSecondary)
                    TextField("e.g. Gym, Reading…", text: $name)
                        .font(.system(.body))
                        .foregroundStyle(AppColor.textPrimary)
                        .frame(minHeight: AppLayout.minTapTarget)
                        .padding(.horizontal, 10)
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                                .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
                        )
                }

                // Color picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("COLOR")
                        .font(.system(.caption).weight(.semibold))
                        .foregroundStyle(AppColor.textSecondary)
                    ColorPicker("Choose a color", selection: $selectedColor, supportsOpacity: false)
                        .frame(minHeight: AppLayout.minTapTarget)
                        .padding(.horizontal, 10)
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                                .stroke(AppColor.border, lineWidth: AppLayout.borderWidth)
                        )
                }

                // Preview card
                BrutalistCard(borderColor: selectedColor) {
                    HStack {
                        CategoryDot(color: selectedColor)
                        Text(name.isEmpty ? "Preview" : name)
                            .font(.system(.body).weight(.medium))
                            .foregroundStyle(AppColor.textPrimary)
                    }
                }

                if let err = errorMessage {
                    Text(err)
                        .font(.system(.caption))
                        .foregroundStyle(AppColor.red)
                }

                Spacer()

                BrutalistButton(title: editingId == nil ? "CREATE CATEGORY" : "SAVE CHANGES") {
                    save()
                }
            }
            .padding(AppLayout.screenMargin)
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle(editingId == nil ? "NEW CATEGORY" : "EDIT CATEGORY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { router.dismiss() }
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
        }
        .onAppear { loadExisting() }
    }

    private func save() {
        let hex = selectedColor.toHex() ?? "#000000"
        do {
            if let id = editingId {
                guard var cat = try env.categoryRepository.fetch(id: id) else { return }
                cat.name = name.trimmingCharacters(in: .whitespaces)
                cat.colorHex = hex
                try env.categoryRepository.save(cat)
            } else {
                let useCase = CreateCategoryUseCase(repository: env.categoryRepository)
                _ = try useCase.execute(name: name, colorHex: hex)
            }
            router.dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadExisting() {
        guard let id = editingId,
              let cat = try? env.categoryRepository.fetch(id: id) else { return }
        name = cat.name
        selectedColor = cat.color
    }
}

// MARK: - Color → Hex string
extension Color {
    func toHex() -> String? {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "#%02X%02X%02X",
                      Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
