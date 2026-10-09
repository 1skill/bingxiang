import SwiftUI

/// 换一台颜色的冰箱。
struct ColourPickerView: View {
    @AppStorage(SettingsKeys.fridgeTheme) private var themeID = FridgeTheme.cherryBlossom.id
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(FridgeTheme.all) { theme in
                Button {
                    themeID = theme.id
                } label: {
                    HStack(spacing: 14) {
                        HStack(spacing: 3) {
                            swatch(theme.exterior)
                            swatch(theme.interior)
                        }
                        Text(theme.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if theme.id == themeID {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .navigationTitle("颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成", systemImage: "checkmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func swatch(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(color.gradient)
            .frame(width: 26, height: 34)
            .overlay {
                RoundedRectangle(cornerRadius: 6).strokeBorder(.black.opacity(0.1))
            }
    }
}
