import SwiftData
import SwiftUI

/// 添加 / 编辑一件食材。
struct ItemFormView: View {
    enum Mode {
        case add(location: StorageLocation?)
        case edit(FoodItem)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var emoji: String
    @State private var category: FoodCategory
    @State private var location: StorageLocation
    @State private var quantity: Double
    @State private var unit: String
    @State private var expiryDate: Date
    @State private var notes: String
    /// 最近一次自动猜出来的 emoji。用户没改过它，就继续跟着名字猜。
    @State private var lastGuessedEmoji: String
    @State private var isDeleteConfirmed = false

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add(let location):
            _name = State(initialValue: "")
            _emoji = State(initialValue: "🥬")
            _category = State(initialValue: .vegetable)
            _location = State(initialValue: location ?? .middleShelf)
            _quantity = State(initialValue: 1)
            _unit = State(initialValue: "份")
            _expiryDate = State(initialValue: Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now)
            _notes = State(initialValue: "")
            _lastGuessedEmoji = State(initialValue: "🥬")
        case .edit(let item):
            _name = State(initialValue: item.name)
            _emoji = State(initialValue: item.emoji)
            _category = State(initialValue: item.category)
            _location = State(initialValue: item.location)
            _quantity = State(initialValue: item.quantity)
            _unit = State(initialValue: item.unit)
            _expiryDate = State(initialValue: item.expiryDate)
            _notes = State(initialValue: item.notes)
            _lastGuessedEmoji = State(initialValue: "")
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var suggestions: [CatalogEntry] {
        let hits = FoodCatalog.suggestions(for: name)
        if hits.count == 1, hits[0].name == name { return [] }
        return Array(hits.prefix(6))
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && quantity > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        TextField("图标", text: $emoji)
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .frame(width: 56)
                        TextField("名称", text: $name)
                            .font(.body.weight(.medium))
                            .onChange(of: name) { _, newName in
                                guard emoji == lastGuessedEmoji else { return }
                                let guess = FoodCatalog.guessEmoji(for: newName, category: category)
                                emoji = guess
                                lastGuessedEmoji = guess
                            }
                    }
                    if !suggestions.isEmpty {
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(suggestions) { entry in
                                    Button {
                                        apply(entry)
                                    } label: {
                                        Text("\(entry.emoji) \(entry.name)")
                                            .font(.subheadline)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(.fill.tertiary, in: .capsule)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                } footer: {
                    Text("输入名字会自动联想常见食材，选一个就把分类、位置和保质期都填好。")
                }

                Section("放在哪") {
                    Picker("分类", selection: $category) {
                        ForEach(FoodCategory.allCases) { category in
                            Text("\(category.emoji) \(category.rawValue)").tag(category)
                        }
                    }
                    Picker("位置", selection: $location) {
                        ForEach(StorageLocation.allCases) { location in
                            Label(location.rawValue, systemImage: location.symbol).tag(location)
                        }
                    }
                }

                Section("数量") {
                    HStack {
                        Stepper(value: $quantity, in: 0.5...99, step: quantity < 1 ? 0.5 : 1) {
                            Text(quantity.formatted(.number.precision(.fractionLength(0...1))))
                                .monospacedDigit()
                        }
                        TextField("单位", text: $unit)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("到期") {
                    DatePicker("到期日", selection: $expiryDate, displayedComponents: .date)
                    HStack(spacing: 8) {
                        ForEach([1, 3, 7, 30], id: \.self) { days in
                            Button("+\(days)天") {
                                expiryDate = Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            .font(.footnote)
                        }
                    }
                }

                Section("备注") {
                    TextField("比如：开封了、给孩子的", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }

                if case .edit(let item) = mode {
                    Section {
                        Button("删除这条记录", systemImage: "trash", role: .destructive) {
                            isDeleteConfirmed = true
                        }
                        .confirmationDialog("删除「\(item.name)」？", isPresented: $isDeleteConfirmed, titleVisibility: .visible) {
                            Button("删除", role: .destructive) {
                                NotificationService.cancel(for: item)
                                modelContext.delete(item)
                                dismiss()
                            }
                        } message: {
                            Text("删除不会计入吃掉或浪费的统计。")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑食材" : "添加食材")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", systemImage: "checkmark") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func apply(_ entry: CatalogEntry) {
        name = entry.name
        emoji = entry.emoji
        lastGuessedEmoji = ""
        category = entry.category
        location = entry.location
        unit = entry.unit
        expiryDate = entry.defaultExpiryDate
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespaces)
        let finalEmoji = trimmedEmoji.isEmpty ? category.emoji : String(trimmedEmoji.prefix(2))

        switch mode {
        case .add:
            let item = FoodItem(
                name: trimmedName,
                emoji: finalEmoji,
                category: category,
                location: location,
                quantity: quantity,
                unit: unit.isEmpty ? "份" : unit,
                expiryDate: expiryDate,
                notes: notes
            )
            modelContext.insert(item)
            NotificationService.schedule(for: item)
        case .edit(let item):
            item.name = trimmedName
            item.emoji = finalEmoji
            item.category = category
            item.location = location
            item.quantity = quantity
            item.unit = unit.isEmpty ? "份" : unit
            item.expiryDate = expiryDate
            item.notes = notes
            NotificationService.schedule(for: item)
        }
        dismiss()
    }
}
