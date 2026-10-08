import SwiftData
import SwiftUI

/// 购物清单。买到的勾掉，一键"放进冰箱"；还会根据最近吃完的东西给补货建议。
struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ShoppingItem.createdDate)
    private var shoppingItems: [ShoppingItem]
    @Query(filter: #Predicate<FoodItem> { $0.statusRaw == "inStock" })
    private var stockItems: [FoodItem]
    @Query(filter: #Predicate<FoodItem> { $0.statusRaw == "eaten" })
    private var eatenItems: [FoodItem]

    @State private var newItemName = ""
    @FocusState private var isInputFocused: Bool

    private var pending: [ShoppingItem] { shoppingItems.filter { !$0.isChecked } }
    private var checked: [ShoppingItem] { shoppingItems.filter(\.isChecked) }

    /// 最近 30 天吃完、现在没货、也不在清单里的东西。
    private var restockSuggestions: [FoodItem] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        let stockNames = Set(stockItems.map(\.name))
        let listNames = Set(shoppingItems.map(\.name))
        var seen = Set<String>()
        return eatenItems
            .sorted { ($0.resolvedDate ?? .distantPast) > ($1.resolvedDate ?? .distantPast) }
            .filter { item in
                guard let resolved = item.resolvedDate, resolved >= cutoff else { return false }
                guard !stockNames.contains(item.name), !listNames.contains(item.name) else { return false }
                return seen.insert(item.name).inserted
            }
            .prefix(6)
            .map { $0 }
    }

    private var inputSuggestions: [CatalogEntry] {
        Array(FoodCatalog.suggestions(for: newItemName).prefix(5))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("想买点什么", text: $newItemName)
                            .focused($isInputFocused)
                            .onSubmit(addTyped)
                        Button("添加", systemImage: "plus.circle.fill", action: addTyped)
                            .labelStyle(.iconOnly)
                            .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    if !inputSuggestions.isEmpty {
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(inputSuggestions) { entry in
                                    Button("\(entry.emoji) \(entry.name)") {
                                        add(name: entry.name, emoji: entry.emoji, unit: entry.unit)
                                    }
                                    .buttonStyle(.bordered)
                                    .buttonBorderShape(.capsule)
                                    .font(.subheadline)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                }

                if pending.isEmpty && checked.isEmpty {
                    ContentUnavailableView("清单是空的", systemImage: "cart", description: Text("在上面输入，或者从冰箱里左滑食材加购。"))
                        .listRowBackground(Color.clear)
                }

                if !pending.isEmpty {
                    Section("待购买 · \(pending.count)") {
                        ForEach(pending) { item in
                            ShoppingRow(item: item)
                        }
                        .onDelete { offsets in delete(offsets, from: pending) }
                    }
                }

                if !checked.isEmpty {
                    Section {
                        ForEach(checked) { item in
                            ShoppingRow(item: item)
                        }
                        .onDelete { offsets in delete(offsets, from: checked) }
                    } header: {
                        Text("已买到 · \(checked.count)")
                    } footer: {
                        Text("点右上角「放进冰箱」，会按常见食材的默认保质期入库。")
                    }
                }

                if !restockSuggestions.isEmpty {
                    Section {
                        ForEach(restockSuggestions) { item in
                            HStack {
                                Text(item.emoji)
                                Text(item.name)
                                Spacer()
                                Button("加入", systemImage: "plus") {
                                    add(name: item.name, emoji: item.emoji, unit: item.unit, source: .restock)
                                }
                                .labelStyle(.iconOnly)
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.circle)
                            }
                        }
                    } header: {
                        Text("补货建议")
                    } footer: {
                        Text("最近一个月吃完、现在冰箱里没有的东西。")
                    }
                }
            }
            .navigationTitle("购物")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("放进冰箱", systemImage: "refrigerator") {
                        restockChecked()
                    }
                    .disabled(checked.isEmpty)
                }
            }
            .sensoryFeedback(.success, trigger: checked.count) { old, new in new < old }
        }
    }

    private func addTyped() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let entry = FoodCatalog.entry(named: trimmed) {
            add(name: entry.name, emoji: entry.emoji, unit: entry.unit)
        } else {
            add(name: trimmed, emoji: FoodCatalog.guessEmoji(for: trimmed, category: .other), unit: "份")
        }
    }

    private func add(name: String, emoji: String, unit: String, source: ShoppingItem.Source = .manual) {
        withAnimation {
            ItemActions.addToShoppingList(name: name, emoji: emoji, unit: unit, in: modelContext, source: source)
        }
        newItemName = ""
    }

    private func delete(_ offsets: IndexSet, from list: [ShoppingItem]) {
        for index in offsets {
            modelContext.delete(list[index])
        }
    }

    private func restockChecked() {
        withAnimation {
            for item in checked {
                ItemActions.restock(item, in: modelContext)
            }
        }
    }
}

private struct ShoppingRow: View {
    @Bindable var item: ShoppingItem

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.snappy) { item.isChecked.toggle() }
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isChecked ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isChecked ? "取消勾选" : "勾选")

            Text(item.emoji)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .strikethrough(item.isChecked)
                    .foregroundStyle(item.isChecked ? .secondary : .primary)
                if item.source != .manual {
                    Text(item.source.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(item.quantityDescription)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Stepper("数量", value: $item.quantity, in: 1...99, step: 1)
                .labelsHidden()
                .fixedSize()
        }
    }
}

#Preview {
    ShoppingListView()
        .modelContainer(for: [FoodItem.self, ShoppingItem.self, DoorNote.self], inMemory: true)
}
