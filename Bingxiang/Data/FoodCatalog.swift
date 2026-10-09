import Foundation

/// 常见食材的默认信息：图标、分类、默认存放位置、默认保质期。
struct CatalogEntry: Identifiable, Hashable {
    let name: String
    let emoji: String
    let category: FoodCategory
    let location: StorageLocation
    let shelfLifeDays: Int
    let unit: String
    /// 资源目录里 `food-<art>` 这张图，没有就用 emoji。
    let art: String?
    /// 摆在架子上时占层高的比例：奶瓶接近 1，柠檬 0.3 左右。
    let size: Double

    var id: String { name }

    /// 从今天算起的默认到期日。
    var defaultExpiryDate: Date {
        Calendar.current.date(byAdding: .day, value: shelfLifeDays, to: .now) ?? .now
    }
}

enum FoodCatalog {
    static let entries: [CatalogEntry] = [
        // 蔬菜
        CatalogEntry(name: "番茄", emoji: "🍅", category: .vegetable, location: .crisper, shelfLifeDays: 7, unit: "个", art: "tomato", size: 0.4),
        CatalogEntry(name: "黄瓜", emoji: "🥒", category: .vegetable, location: .crisper, shelfLifeDays: 5, unit: "根", art: "cucumber", size: 0.5),
        CatalogEntry(name: "生菜", emoji: "🥬", category: .vegetable, location: .crisper, shelfLifeDays: 4, unit: "颗", art: "lettuce", size: 0.55),
        CatalogEntry(name: "西兰花", emoji: "🥦", category: .vegetable, location: .crisper, shelfLifeDays: 5, unit: "颗", art: "broccoli", size: 0.55),
        CatalogEntry(name: "土豆", emoji: "🥔", category: .vegetable, location: .lowerShelf, shelfLifeDays: 21, unit: "个", art: "potato", size: 0.36),
        CatalogEntry(name: "胡萝卜", emoji: "🥕", category: .vegetable, location: .crisper, shelfLifeDays: 14, unit: "根", art: "carrot", size: 0.6),
        CatalogEntry(name: "青椒", emoji: "🫑", category: .vegetable, location: .crisper, shelfLifeDays: 7, unit: "个", art: "green-pepper", size: 0.45),
        CatalogEntry(name: "洋葱", emoji: "🧅", category: .vegetable, location: .lowerShelf, shelfLifeDays: 30, unit: "个", art: "onion", size: 0.4),
        CatalogEntry(name: "大蒜", emoji: "🧄", category: .condiment, location: .door, shelfLifeDays: 60, unit: "头", art: "garlic", size: 0.32),
        CatalogEntry(name: "小葱", emoji: "🌿", category: .vegetable, location: .crisper, shelfLifeDays: 5, unit: "把", art: "scallion", size: 0.6),
        CatalogEntry(name: "芹菜", emoji: "🥬", category: .vegetable, location: .crisper, shelfLifeDays: 7, unit: "把", art: "celery", size: 0.65),
        CatalogEntry(name: "韭菜", emoji: "🌿", category: .vegetable, location: .crisper, shelfLifeDays: 3, unit: "把", art: "chives", size: 0.55),
        CatalogEntry(name: "香菇", emoji: "🍄", category: .vegetable, location: .crisper, shelfLifeDays: 5, unit: "盒", art: "mushroom", size: 0.45),
        CatalogEntry(name: "冬瓜", emoji: "🥒", category: .vegetable, location: .crisper, shelfLifeDays: 7, unit: "块", art: "winter-melon", size: 0.5),
        CatalogEntry(name: "豆腐", emoji: "🧈", category: .vegetable, location: .middleShelf, shelfLifeDays: 3, unit: "盒", art: "tofu", size: 0.4),
        CatalogEntry(name: "玉米", emoji: "🌽", category: .vegetable, location: .crisper, shelfLifeDays: 5, unit: "根", art: "corn", size: 0.55),
        CatalogEntry(name: "菠菜", emoji: "🥬", category: .vegetable, location: .crisper, shelfLifeDays: 3, unit: "把", art: "spinach", size: 0.5),
        // 水果
        CatalogEntry(name: "苹果", emoji: "🍎", category: .fruit, location: .crisper, shelfLifeDays: 21, unit: "个", art: "apple", size: 0.38),
        CatalogEntry(name: "香蕉", emoji: "🍌", category: .fruit, location: .upperShelf, shelfLifeDays: 5, unit: "根", art: "banana", size: 0.5),
        CatalogEntry(name: "橙子", emoji: "🍊", category: .fruit, location: .crisper, shelfLifeDays: 14, unit: "个", art: "orange", size: 0.36),
        CatalogEntry(name: "葡萄", emoji: "🍇", category: .fruit, location: .crisper, shelfLifeDays: 7, unit: "串", art: "grapes", size: 0.5),
        CatalogEntry(name: "草莓", emoji: "🍓", category: .fruit, location: .upperShelf, shelfLifeDays: 3, unit: "盒", art: "strawberry", size: 0.45),
        CatalogEntry(name: "西瓜", emoji: "🍉", category: .fruit, location: .lowerShelf, shelfLifeDays: 4, unit: "块", art: "watermelon", size: 0.5),
        CatalogEntry(name: "蓝莓", emoji: "🫐", category: .fruit, location: .upperShelf, shelfLifeDays: 7, unit: "盒", art: "blueberry", size: 0.4),
        CatalogEntry(name: "柠檬", emoji: "🍋", category: .fruit, location: .door, shelfLifeDays: 21, unit: "个", art: "lemon", size: 0.32),
        CatalogEntry(name: "猕猴桃", emoji: "🥝", category: .fruit, location: .crisper, shelfLifeDays: 10, unit: "个", art: "kiwi", size: 0.3),
        // 肉类
        CatalogEntry(name: "猪肉", emoji: "🥩", category: .meat, location: .lowerShelf, shelfLifeDays: 3, unit: "份", art: "pork", size: 0.45),
        CatalogEntry(name: "牛肉", emoji: "🥩", category: .meat, location: .lowerShelf, shelfLifeDays: 3, unit: "份", art: "beef", size: 0.45),
        CatalogEntry(name: "鸡胸肉", emoji: "🍗", category: .meat, location: .lowerShelf, shelfLifeDays: 2, unit: "份", art: "chicken-breast", size: 0.45),
        CatalogEntry(name: "鸡翅", emoji: "🍗", category: .meat, location: .lowerShelf, shelfLifeDays: 2, unit: "份", art: "chicken-wings", size: 0.45),
        CatalogEntry(name: "排骨", emoji: "🍖", category: .meat, location: .lowerShelf, shelfLifeDays: 3, unit: "份", art: "pork-ribs", size: 0.45),
        CatalogEntry(name: "培根", emoji: "🥓", category: .meat, location: .middleShelf, shelfLifeDays: 7, unit: "包", art: "bacon", size: 0.4),
        CatalogEntry(name: "火腿", emoji: "🍖", category: .meat, location: .middleShelf, shelfLifeDays: 10, unit: "包", art: "ham", size: 0.4),
        CatalogEntry(name: "香肠", emoji: "🌭", category: .meat, location: .middleShelf, shelfLifeDays: 14, unit: "包", art: "sausage", size: 0.4),
        // 海鲜
        CatalogEntry(name: "虾仁", emoji: "🦐", category: .seafood, location: .freezer, shelfLifeDays: 90, unit: "袋", art: "shrimp", size: 0.55),
        CatalogEntry(name: "鱼", emoji: "🐟", category: .seafood, location: .lowerShelf, shelfLifeDays: 2, unit: "条", art: "fish", size: 0.5),
        CatalogEntry(name: "三文鱼", emoji: "🍣", category: .seafood, location: .lowerShelf, shelfLifeDays: 2, unit: "份", art: "salmon", size: 0.4),
        // 蛋奶
        CatalogEntry(name: "鸡蛋", emoji: "🥚", category: .dairyEgg, location: .door, shelfLifeDays: 21, unit: "个", art: "egg", size: 0.45),
        CatalogEntry(name: "牛奶", emoji: "🥛", category: .dairyEgg, location: .door, shelfLifeDays: 7, unit: "盒", art: "milk", size: 0.9),
        CatalogEntry(name: "酸奶", emoji: "🥛", category: .dairyEgg, location: .upperShelf, shelfLifeDays: 14, unit: "杯", art: "yogurt", size: 0.5),
        CatalogEntry(name: "黄油", emoji: "🧈", category: .dairyEgg, location: .door, shelfLifeDays: 60, unit: "块", art: "butter", size: 0.35),
        CatalogEntry(name: "奶酪", emoji: "🧀", category: .dairyEgg, location: .middleShelf, shelfLifeDays: 21, unit: "块", art: "cheese", size: 0.45),
        // 饮品
        CatalogEntry(name: "可乐", emoji: "🥤", category: .drink, location: .door, shelfLifeDays: 180, unit: "瓶", art: "cola", size: 0.95),
        CatalogEntry(name: "橙汁", emoji: "🧃", category: .drink, location: .door, shelfLifeDays: 7, unit: "瓶", art: "orange-juice", size: 0.9),
        CatalogEntry(name: "啤酒", emoji: "🍺", category: .drink, location: .door, shelfLifeDays: 180, unit: "罐", art: "beer", size: 0.7),
        CatalogEntry(name: "豆浆", emoji: "🥛", category: .drink, location: .door, shelfLifeDays: 3, unit: "瓶", art: "soy-milk", size: 0.85),
        // 调料
        CatalogEntry(name: "番茄酱", emoji: "🥫", category: .condiment, location: .door, shelfLifeDays: 90, unit: "瓶", art: "ketchup", size: 0.8),
        CatalogEntry(name: "蚝油", emoji: "🧂", category: .condiment, location: .door, shelfLifeDays: 180, unit: "瓶", art: "oyster-sauce", size: 0.85),
        CatalogEntry(name: "沙拉酱", emoji: "🥫", category: .condiment, location: .door, shelfLifeDays: 60, unit: "瓶", art: "salad-dressing", size: 0.8),
        CatalogEntry(name: "果酱", emoji: "🍯", category: .condiment, location: .door, shelfLifeDays: 90, unit: "瓶", art: "jam", size: 0.55),
        CatalogEntry(name: "豆瓣酱", emoji: "🥫", category: .condiment, location: .door, shelfLifeDays: 180, unit: "瓶", art: "bean-paste", size: 0.6),
        // 剩菜熟食
        CatalogEntry(name: "剩饭", emoji: "🍚", category: .leftover, location: .middleShelf, shelfLifeDays: 2, unit: "盒", art: "leftover-rice", size: 0.45),
        CatalogEntry(name: "剩菜", emoji: "🍱", category: .leftover, location: .middleShelf, shelfLifeDays: 2, unit: "盒", art: "leftovers", size: 0.45),
        CatalogEntry(name: "外卖", emoji: "🥡", category: .leftover, location: .middleShelf, shelfLifeDays: 1, unit: "盒", art: "takeout", size: 0.55),
        CatalogEntry(name: "蛋糕", emoji: "🍰", category: .leftover, location: .upperShelf, shelfLifeDays: 2, unit: "块", art: "cake", size: 0.45),
        // 主食
        CatalogEntry(name: "面包", emoji: "🍞", category: .staple, location: .upperShelf, shelfLifeDays: 4, unit: "袋", art: "bread", size: 0.55),
        CatalogEntry(name: "面条", emoji: "🍜", category: .staple, location: .middleShelf, shelfLifeDays: 3, unit: "袋", art: "noodles", size: 0.55),
        CatalogEntry(name: "燕麦", emoji: "🥣", category: .staple, location: .upperShelf, shelfLifeDays: 180, unit: "袋", art: "oats", size: 0.7),
        CatalogEntry(name: "紫菜", emoji: "🍙", category: .staple, location: .upperShelf, shelfLifeDays: 180, unit: "包", art: "seaweed", size: 0.5),
        // 冷冻
        CatalogEntry(name: "速冻水饺", emoji: "🥟", category: .frozen, location: .freezer, shelfLifeDays: 180, unit: "袋", art: "dumplings", size: 0.6),
        CatalogEntry(name: "冰淇淋", emoji: "🍨", category: .frozen, location: .freezer, shelfLifeDays: 90, unit: "盒", art: "ice-cream", size: 0.55),
        CatalogEntry(name: "冷冻蔬菜", emoji: "🧊", category: .frozen, location: .freezer, shelfLifeDays: 180, unit: "袋", art: "frozen-vegetables", size: 0.6),
        CatalogEntry(name: "冻肉", emoji: "🥩", category: .frozen, location: .freezer, shelfLifeDays: 120, unit: "份", art: "frozen-meat", size: 0.5),
        CatalogEntry(name: "汤圆", emoji: "🍡", category: .frozen, location: .freezer, shelfLifeDays: 180, unit: "袋", art: "tangyuan", size: 0.6),
    ]

    static func entry(named name: String) -> CatalogEntry? {
        entries.first { $0.name == name }
    }

    /// 按名字模糊匹配，给输入框做联想。
    static func suggestions(for query: String) -> [CatalogEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        return entries.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    static func entries(in category: FoodCategory) -> [CatalogEntry] {
        entries.filter { $0.category == category }
    }

    /// 这件食材对应的素材图名，按名字精确匹配，再试包含关系（"土鸡蛋" → 鸡蛋）。
    static func artName(for name: String) -> String? {
        if let exact = entries.first(where: { $0.name == name }), let art = exact.art {
            return "food-\(art)"
        }
        if let hit = entries.first(where: { $0.art != nil && (name.contains($0.name) || $0.name.contains(name)) }), let art = hit.art {
            return "food-\(art)"
        }
        return nil
    }

    /// 这件食材摆在架子上的相对大小，按名字匹配；没有数据的按 0.5。
    static func relativeSize(for name: String) -> Double {
        if let exact = entries.first(where: { $0.name == name }) { return exact.size }
        if let hit = entries.first(where: { name.contains($0.name) || $0.name.contains(name) }) { return hit.size }
        return 0.5
    }

    /// 根据名字猜一个 emoji，猜不到就按分类给。
    static func guessEmoji(for name: String, category: FoodCategory) -> String {
        if let hit = entries.first(where: { name.contains($0.name) || $0.name.contains(name) }) {
            return hit.emoji
        }
        return category.emoji
    }
}
