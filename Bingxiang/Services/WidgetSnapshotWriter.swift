import Foundation
import WidgetKit

/// 数据一变就把快照写给小组件，并让它刷新。
enum WidgetSnapshotWriter {
    static func write(items: [FoodItem], shoppingItems: [ShoppingItem], notes: [DoorNote], themeID: String, openCount: Int) {
        let stock = items.filter(\.isInStock)
        let expiring = stock
            .filter { $0.freshness != .fresh }
            .sorted { $0.expiryDate < $1.expiryDate }
            .prefix(6)
            .map { WidgetSnapshot.Item(name: $0.name, emoji: $0.emoji, daysLeft: $0.daysUntilExpiry) }
        let pending = shoppingItems.filter { !$0.isChecked }
        let snapshot = WidgetSnapshot(
            themeID: themeID,
            inStockCount: stock.count,
            expiring: Array(expiring),
            shoppingNames: pending.prefix(4).map(\.name),
            shoppingCount: pending.count,
            noteTexts: notes.suffix(2).map(\.text),
            openCount: openCount,
            updatedAt: .now
        )
        guard snapshot != WidgetSnapshot.load() else { return }
        do {
            try snapshot.save()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            // 写不进共享容器就算了，小组件用上一次的。
        }
    }
}
