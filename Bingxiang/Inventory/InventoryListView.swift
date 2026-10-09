import SwiftData
import SwiftUI

/// 全部在库食材，按新鲜度分组，可搜索、可按位置和分类筛选。
struct InventoryListView: View {
    @Query(filter: #Predicate<FoodItem> { $0.statusRaw == "inStock" }, sort: \FoodItem.expiryDate)
    private var items: [FoodItem]

    @State private var searchText = ""
    @State private var locationFilter: StorageLocation?
    @State private var categoryFilter: FoodCategory?
    @State private var editingItem: FoodItem?
    @State private var isAddPresented = false
    @State private var isQuickAddPresented = false

    private var filtered: [FoodItem] {
        items.filter { item in
            if let locationFilter, item.location != locationFilter { return false }
            if let categoryFilter, item.category != categoryFilter { return false }
            if !searchText.isEmpty, !item.name.localizedCaseInsensitiveContains(searchText) { return false }
            return true
        }
    }

    private var groups: [(Freshness, [FoodItem])] {
        [Freshness.expired, .soon, .fresh].compactMap { freshness in
            let group = filtered.filter { $0.freshness == freshness }
            return group.isEmpty ? nil : (freshness, group)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView {
                        Label("冰箱是空的", systemImage: "refrigerator")
                    } description: {
                        Text("先放点东西进去。")
                    } actions: {
                        Button("快速添加", systemImage: "square.grid.2x2") { isQuickAddPresented = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(groups, id: \.0) { freshness, group in
                            Section {
                                ForEach(group) { item in
                                    ItemRow(item: item)
                                        .contentShape(.rect)
                                        .onTapGesture { editingItem = item }
                                        .itemSwipeActions(item)
                                }
                            } header: {
                                HStack {
                                    Circle()
                                        .fill(FridgeMetrics.freshnessColor(freshness))
                                        .frame(width: 8, height: 8)
                                    Text("\(freshness.title) · \(group.count)")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("清单")
            .searchable(text: $searchText, prompt: "搜食材")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    filterMenu
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu("添加", systemImage: "plus") {
                        Button("快速添加常见食材", systemImage: "square.grid.2x2") { isQuickAddPresented = true }
                        Button("手动添加", systemImage: "square.and.pencil") { isAddPresented = true }
                    }
                }
            }
            .sheet(item: $editingItem) { item in
                ItemFormView(mode: .edit(item))
            }
            .sheet(isPresented: $isAddPresented) {
                ItemFormView(mode: .add(location: locationFilter))
            }
            .sheet(isPresented: $isQuickAddPresented) {
                QuickAddView(defaultLocation: locationFilter)
            }
        }
    }

    private var filterMenu: some View {
        Menu("筛选", systemImage: hasFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle") {
            Picker("位置", selection: $locationFilter) {
                Text("所有位置").tag(StorageLocation?.none)
                ForEach(StorageLocation.allCases) { location in
                    Text(location.rawValue).tag(StorageLocation?.some(location))
                }
            }
            Picker("分类", selection: $categoryFilter) {
                Text("所有分类").tag(FoodCategory?.none)
                ForEach(FoodCategory.allCases) { category in
                    Text("\(category.emoji) \(category.rawValue)").tag(FoodCategory?.some(category))
                }
            }
            if hasFilter {
                Button("清除筛选", systemImage: "xmark.circle") {
                    locationFilter = nil
                    categoryFilter = nil
                }
            }
        }
    }

    private var hasFilter: Bool {
        locationFilter != nil || categoryFilter != nil
    }
}

#Preview {
    InventoryListView()
        .modelContainer(for: [FoodItem.self, ShoppingItem.self, DoorNote.self, DoorPhoto.self], inMemory: true)
}
