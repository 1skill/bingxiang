import SwiftData
import SwiftUI

/// 点一下就把常见食材按默认保质期放进冰箱，适合刚买完菜回来一口气录入。
struct QuickAddView: View {
    let defaultLocation: StorageLocation?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var addedCount = 0
    @State private var lastAdded: String?

    private let columns = [GridItem(.adaptive(minimum: 84, maximum: 120), spacing: 10)]

    private var categories: [FoodCategory] {
        FoodCategory.allCases.filter { !entries(in: $0).isEmpty }
    }

    private func entries(in category: FoodCategory) -> [CatalogEntry] {
        let all = FoodCatalog.entries(in: category)
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(categories) { category in
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(category.emoji) \(category.rawValue)")
                                .font(.headline)
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(entries(in: category)) { entry in
                                    CatalogTile(entry: entry) {
                                        add(entry)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .searchable(text: $searchText, prompt: "找食材")
            .navigationTitle("快速添加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成", systemImage: "checkmark") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if addedCount > 0 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("已放入 \(addedCount) 样")
                        if let lastAdded {
                            Text("· 刚放了 \(lastAdded)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .glassEffect(in: .capsule)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sensoryFeedback(.success, trigger: addedCount)
        }
    }

    private func add(_ entry: CatalogEntry) {
        let item = FoodItem(
            name: entry.name,
            emoji: entry.emoji,
            category: entry.category,
            location: defaultLocation ?? entry.location,
            quantity: 1,
            unit: entry.unit,
            expiryDate: entry.defaultExpiryDate
        )
        modelContext.insert(item)
        NotificationService.schedule(for: item)
        withAnimation(.snappy) {
            addedCount += 1
            lastAdded = entry.name
        }
    }
}

private struct CatalogTile: View {
    let entry: CatalogEntry
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(entry.emoji)
                    .font(.system(size: 30))
                Text(entry.name)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                Text("\(entry.shelfLifeDays) 天")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(.fill.tertiary, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("添加 \(entry.name)，保质期 \(entry.shelfLifeDays) 天")
    }
}
