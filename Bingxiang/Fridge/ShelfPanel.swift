import SwiftData
import SwiftUI

/// 冰箱旁边 / 下面的清单面板：按层架筛选，左滑右滑处理食材。
struct ShelfPanel: View {
    let items: [FoodItem]
    @Binding var selectedLocation: StorageLocation?
    let onAdd: () -> Void

    @State private var editingItem: FoodItem?

    private var filtered: [FoodItem] {
        guard let selectedLocation else { return items }
        return items.filter { $0.location == selectedLocation }
    }

    var body: some View {
        VStack(spacing: 0) {
            chips
            if filtered.isEmpty {
                ContentUnavailableView {
                    Label(selectedLocation == nil ? "冰箱是空的" : "\(selectedLocation?.rawValue ?? "") 空空的", systemImage: "refrigerator")
                } description: {
                    Text("买点东西回来放进去吧。")
                } actions: {
                    Button("添加食材", systemImage: "plus", action: onAdd)
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(filtered) { item in
                        ItemRow(item: item)
                            .contentShape(.rect)
                            .onTapGesture { editingItem = item }
                            .itemSwipeActions(item)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(item: $editingItem) { item in
            ItemFormView(mode: .edit(item))
        }
    }

    private var chips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                LocationChip(title: "全部", count: items.count, isSelected: selectedLocation == nil) {
                    withAnimation(.snappy) { selectedLocation = nil }
                }
                ForEach(StorageLocation.allCases) { location in
                    let count = items.filter { $0.location == location }.count
                    LocationChip(title: location.rawValue, count: count, isSelected: selectedLocation == location) {
                        withAnimation(.snappy) { selectedLocation = location }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .scrollIndicators(.hidden)
    }
}

private struct LocationChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                Text(count, format: .number)
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.fill.tertiary), in: .capsule)
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}
