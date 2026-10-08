import Foundation
import SwiftData

/// 第一次打开时塞一些示例数据，让冰箱不至于空空如也。
enum SampleData {
    static func seedIfNeeded(in context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: SettingsKeys.hasSeededSampleData) else { return }

        let descriptor = FetchDescriptor<FoodItem>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else {
            defaults.set(true, forKey: SettingsKeys.hasSeededSampleData)
            return
        }

        insertSamples(in: context)
        defaults.set(true, forKey: SettingsKeys.hasSeededSampleData)
    }

    static func insertSamples(in context: ModelContext) {
        let calendar = Calendar.current
        func days(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: offset, to: .now) ?? .now
        }

        let samples: [(String, Int, Double)] = [
            ("牛奶", 2, 1), ("鸡蛋", 12, 8), ("番茄", 3, 4), ("黄瓜", -1, 2),
            ("生菜", 1, 1), ("土豆", 15, 5), ("猪肉", 1, 1), ("鸡翅", 2, 1),
            ("可乐", 90, 3), ("酸奶", 6, 4), ("草莓", 0, 1), ("剩菜", 1, 1),
            ("速冻水饺", 120, 1), ("冰淇淋", 60, 1), ("虾仁", 80, 1), ("大蒜", 40, 2),
            ("蚝油", 150, 1), ("面包", 2, 1), ("豆腐", 2, 1), ("小葱", 3, 1),
        ]

        for (name, expiryOffset, quantity) in samples {
            guard let entry = FoodCatalog.entry(named: name) else { continue }
            let item = FoodItem(
                name: entry.name,
                emoji: entry.emoji,
                category: entry.category,
                location: entry.location,
                quantity: quantity,
                unit: entry.unit,
                addedDate: days(expiryOffset - entry.shelfLifeDays),
                expiryDate: days(expiryOffset)
            )
            context.insert(item)
        }

        // 一些历史记录，让统计页有东西看。
        let history: [(String, ItemStatus, Int)] = [
            ("菠菜", .wasted, -3), ("香蕉", .eaten, -2), ("牛奶", .eaten, -5), ("剩饭", .wasted, -6),
            ("苹果", .eaten, -8), ("豆浆", .wasted, -10), ("鸡胸肉", .eaten, -12), ("橙汁", .eaten, -15),
            ("生菜", .wasted, -17), ("葡萄", .eaten, -20), ("外卖", .wasted, -24), ("鸡蛋", .eaten, -28),
        ]
        for (name, status, offset) in history {
            guard let entry = FoodCatalog.entry(named: name) else { continue }
            let item = FoodItem(
                name: entry.name,
                emoji: entry.emoji,
                category: entry.category,
                location: entry.location,
                quantity: 1,
                unit: entry.unit,
                addedDate: days(offset - 5),
                expiryDate: days(offset + (status == .wasted ? -1 : 3))
            )
            item.status = status
            item.resolvedDate = days(offset)
            context.insert(item)
        }

        context.insert(ShoppingItem(name: "鸡蛋", emoji: "🥚", quantity: 10, unit: "个"))
        context.insert(ShoppingItem(name: "西兰花", emoji: "🥦", quantity: 1, unit: "颗"))
        context.insert(DoorNote(text: "周末火锅 🍲", colorName: "yellow", rotation: -4))
        context.insert(DoorNote(text: "记得买酱油", colorName: "pink", rotation: 3))

        try? context.save()
    }
}
