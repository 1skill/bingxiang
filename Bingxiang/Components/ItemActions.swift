import SwiftData
import SwiftUI

/// 对一件食材能做的事：吃掉、扔掉、加进购物清单。清单页和冰箱面板共用。
enum ItemActions {
    static func markEaten(_ item: FoodItem, in context: ModelContext) {
        item.markResolved(.eaten)
        NotificationService.cancel(for: item)
    }

    static func markWasted(_ item: FoodItem, in context: ModelContext) {
        item.markResolved(.wasted)
        NotificationService.cancel(for: item)
    }

    /// 把它加进购物清单。已经在清单里就不重复加。
    static func addToShoppingList(_ item: FoodItem, in context: ModelContext, source: ShoppingItem.Source = .manual) {
        addToShoppingList(name: item.name, emoji: item.emoji, unit: item.unit, in: context, source: source)
    }

    static func addToShoppingList(
        name: String,
        emoji: String,
        unit: String,
        in context: ModelContext,
        source: ShoppingItem.Source = .manual
    ) {
        let descriptor = FetchDescriptor<ShoppingItem>(
            predicate: #Predicate { $0.name == name && $0.isChecked == false }
        )
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }
        context.insert(ShoppingItem(name: name, emoji: emoji, quantity: 1, unit: unit, source: source))
    }

    /// 买回来了：按常见食材的默认信息放进冰箱。
    static func restock(_ shoppingItem: ShoppingItem, in context: ModelContext) {
        let entry = FoodCatalog.entry(named: shoppingItem.name)
        let category = entry?.category ?? .other
        let item = FoodItem(
            name: shoppingItem.name,
            emoji: shoppingItem.emoji,
            category: category,
            location: entry?.location ?? .middleShelf,
            quantity: shoppingItem.quantity,
            unit: shoppingItem.unit,
            expiryDate: entry?.defaultExpiryDate
                ?? Calendar.current.date(byAdding: .day, value: 7, to: .now)
                ?? .now
        )
        context.insert(item)
        NotificationService.schedule(for: item)
        context.delete(shoppingItem)
    }
}

extension View {
    /// 左滑扔掉 / 加购，右滑吃掉。
    func itemSwipeActions(_ item: FoodItem) -> some View {
        modifier(ItemSwipeActions(item: item))
    }
}

private struct ItemSwipeActions: ViewModifier {
    let item: FoodItem
    @Environment(\.modelContext) private var modelContext

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button("吃掉了", systemImage: "fork.knife") {
                    withAnimation { ItemActions.markEaten(item, in: modelContext) }
                }
                .tint(.green)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button("扔掉了", systemImage: "trash") {
                    withAnimation { ItemActions.markWasted(item, in: modelContext) }
                }
                .tint(.red)
                Button("加购", systemImage: "cart.badge.plus") {
                    ItemActions.addToShoppingList(item, in: modelContext)
                }
                .tint(.orange)
            }
    }
}
