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

    var id: String { name }

    /// 从今天算起的默认到期日。
    var defaultExpiryDate: Date {
        Calendar.current.date(byAdding: .day, value: shelfLifeDays, to: .now) ?? .now
    }
}

enum FoodCatalog {
    static let entries: [CatalogEntry] = [
        // 蔬菜
        CatalogEntry(name: "番茄", emoji: "🍅", category: .vegetable, location: .crisper, shelfLifeDays: 7, unit: "个", art: "tomato"),
        CatalogEntry(name: "黄瓜", emoji: "🥒", category: .vegetable, location: .crisper, shelfLifeDays: 5, unit: "根", art: "cucumber"),
        CatalogEntry(name: "生菜", emoji: "🥬", category: .vegetable, location: .crisper, shelfLifeDays: 4, unit: "颗", art: "lettuce"),
        CatalogEntry(name: "西兰花", emoji: "🥦", category: .vegetable, location: .crisper, shelfLifeDays: 5, unit: "颗", art: "broccoli"),
        CatalogEntry(name: "土豆", emoji: "🥔", category: .vegetable, location: .lowerShelf, shelfLifeDays: 21, unit: "个", art: "potato"),
        CatalogEntry(name: "胡萝卜", emoji: "🥕", category: .vegetable, location: .crisper, shelfLifeDays: 14, unit: "根", art: "carrot"),
        CatalogEntry(name: "青椒", emoji: "🫑", category: .vegetable, location: .crisper, shelfLifeDays: 7, unit: "个", art: "green-pepper"),
        CatalogEntry(name: "洋葱", emoji: "🧅", category: .vegetable, location: .lowerShelf, shelfLifeDays: 30, unit: "个", art: "onion"),
        CatalogEntry(name: "大蒜", emoji: "🧄", category: .condiment, location: .door, shelfLifeDays: 60, unit: "头", art: "garlic"),
        CatalogEntry(name: "小葱", emoji: "🌿", category: .vegetable, location: .crisper, shelfLifeDays: 5, unit: "把", art: "scallion"),
        CatalogEntry(name: "芹菜", emoji: "🥬", category: .vegetable, location: .crisper, shelfLifeDays: 7, unit: "把", art: "celery"),
        CatalogEntry(name: "韭菜", emoji: "🌿", category: .vegetable, location: .crisper, shelfLifeDays: 3, unit: "把", art: "chives"),
        CatalogEntry(name: "香菇", emoji: "🍄", category: .vegetable, location: .crisper, shelfLifeDays: 5, unit: "盒", art: "mushroom"),
        CatalogEntry(name: "冬瓜", emoji: "🥒", category: .vegetable, location: .crisper, shelfLifeDays: 7, unit: "块", art: "winter-melon"),
        CatalogEntry(name: "豆腐", emoji: "🧈", category: .vegetable, location: .middleShelf, shelfLifeDays: 3, unit: "盒", art: "tofu"),
        CatalogEntry(name: "玉米", emoji: "🌽", category: .vegetable, location: .crisper, shelfLifeDays: 5, unit: "根", art: "corn"),
        CatalogEntry(name: "菠菜", emoji: "🥬", category: .vegetable, location: .crisper, shelfLifeDays: 3, unit: "把", art: "spinach"),
        // 水果
        CatalogEntry(name: "苹果", emoji: "🍎", category: .fruit, location: .crisper, shelfLifeDays: 21, unit: "个", art: "apple"),
        CatalogEntry(name: "香蕉", emoji: "🍌", category: .fruit, location: .upperShelf, shelfLifeDays: 5, unit: "根", art: "banana"),
        CatalogEntry(name: "橙子", emoji: "🍊", category: .fruit, location: .crisper, shelfLifeDays: 14, unit: "个", art: "orange"),
        CatalogEntry(name: "葡萄", emoji: "🍇", category: .fruit, location: .crisper, shelfLifeDays: 7, unit: "串", art: "grapes"),
        CatalogEntry(name: "草莓", emoji: "🍓", category: .fruit, location: .upperShelf, shelfLifeDays: 3, unit: "盒", art: "strawberry"),
        CatalogEntry(name: "西瓜", emoji: "🍉", category: .fruit, location: .lowerShelf, shelfLifeDays: 4, unit: "块", art: "watermelon"),
        CatalogEntry(name: "蓝莓", emoji: "🫐", category: .fruit, location: .upperShelf, shelfLifeDays: 7, unit: "盒", art: "blueberry"),
        CatalogEntry(name: "柠檬", emoji: "🍋", category: .fruit, location: .door, shelfLifeDays: 21, unit: "个", art: "lemon"),
        CatalogEntry(name: "猕猴桃", emoji: "🥝", category: .fruit, location: .crisper, shelfLifeDays: 10, unit: "个", art: "kiwi"),
        // 肉类
        CatalogEntry(name: "猪肉", emoji: "🥩", category: .meat, location: .lowerShelf, shelfLifeDays: 3, unit: "份", art: "pork"),
        CatalogEntry(name: "牛肉", emoji: "🥩", category: .meat, location: .lowerShelf, shelfLifeDays: 3, unit: "份", art: "beef"),
        CatalogEntry(name: "鸡胸肉", emoji: "🍗", category: .meat, location: .lowerShelf, shelfLifeDays: 2, unit: "份", art: "chicken-breast"),
        CatalogEntry(name: "鸡翅", emoji: "🍗", category: .meat, location: .lowerShelf, shelfLifeDays: 2, unit: "份", art: "chicken-wings"),
        CatalogEntry(name: "排骨", emoji: "🍖", category: .meat, location: .lowerShelf, shelfLifeDays: 3, unit: "份", art: "pork-ribs"),
        CatalogEntry(name: "培根", emoji: "🥓", category: .meat, location: .middleShelf, shelfLifeDays: 7, unit: "包", art: "bacon"),
        CatalogEntry(name: "火腿", emoji: "🍖", category: .meat, location: .middleShelf, shelfLifeDays: 10, unit: "包", art: "ham"),
        CatalogEntry(name: "香肠", emoji: "🌭", category: .meat, location: .middleShelf, shelfLifeDays: 14, unit: "包", art: "sausage"),
        // 海鲜
        CatalogEntry(name: "虾仁", emoji: "🦐", category: .seafood, location: .freezer, shelfLifeDays: 90, unit: "袋", art: "shrimp"),
        CatalogEntry(name: "鱼", emoji: "🐟", category: .seafood, location: .lowerShelf, shelfLifeDays: 2, unit: "条", art: "fish"),
        CatalogEntry(name: "三文鱼", emoji: "🍣", category: .seafood, location: .lowerShelf, shelfLifeDays: 2, unit: "份", art: "salmon"),
        // 蛋奶
        CatalogEntry(name: "鸡蛋", emoji: "🥚", category: .dairyEgg, location: .door, shelfLifeDays: 21, unit: "个", art: "egg"),
        CatalogEntry(name: "牛奶", emoji: "🥛", category: .dairyEgg, location: .door, shelfLifeDays: 7, unit: "盒", art: "milk"),
        CatalogEntry(name: "酸奶", emoji: "🥛", category: .dairyEgg, location: .upperShelf, shelfLifeDays: 14, unit: "杯", art: "yogurt"),
        CatalogEntry(name: "黄油", emoji: "🧈", category: .dairyEgg, location: .door, shelfLifeDays: 60, unit: "块", art: "butter"),
        CatalogEntry(name: "奶酪", emoji: "🧀", category: .dairyEgg, location: .middleShelf, shelfLifeDays: 21, unit: "块", art: "cheese"),
        // 饮品
        CatalogEntry(name: "可乐", emoji: "🥤", category: .drink, location: .door, shelfLifeDays: 180, unit: "瓶", art: "cola"),
        CatalogEntry(name: "橙汁", emoji: "🧃", category: .drink, location: .door, shelfLifeDays: 7, unit: "瓶", art: "orange-juice"),
        CatalogEntry(name: "啤酒", emoji: "🍺", category: .drink, location: .door, shelfLifeDays: 180, unit: "罐", art: "beer"),
        CatalogEntry(name: "豆浆", emoji: "🥛", category: .drink, location: .door, shelfLifeDays: 3, unit: "瓶", art: "soy-milk"),
        // 调料
        CatalogEntry(name: "番茄酱", emoji: "🥫", category: .condiment, location: .door, shelfLifeDays: 90, unit: "瓶", art: "ketchup"),
        CatalogEntry(name: "蚝油", emoji: "🧂", category: .condiment, location: .door, shelfLifeDays: 180, unit: "瓶", art: "oyster-sauce"),
        CatalogEntry(name: "沙拉酱", emoji: "🥫", category: .condiment, location: .door, shelfLifeDays: 60, unit: "瓶", art: "salad-dressing"),
        CatalogEntry(name: "果酱", emoji: "🍯", category: .condiment, location: .door, shelfLifeDays: 90, unit: "瓶", art: "jam"),
        CatalogEntry(name: "豆瓣酱", emoji: "🥫", category: .condiment, location: .door, shelfLifeDays: 180, unit: "瓶", art: "bean-paste"),
        // 剩菜熟食
        CatalogEntry(name: "剩饭", emoji: "🍚", category: .leftover, location: .middleShelf, shelfLifeDays: 2, unit: "盒", art: "leftover-rice"),
        CatalogEntry(name: "剩菜", emoji: "🍱", category: .leftover, location: .middleShelf, shelfLifeDays: 2, unit: "盒", art: "leftovers"),
        CatalogEntry(name: "外卖", emoji: "🥡", category: .leftover, location: .middleShelf, shelfLifeDays: 1, unit: "盒", art: "takeout"),
        CatalogEntry(name: "蛋糕", emoji: "🍰", category: .leftover, location: .upperShelf, shelfLifeDays: 2, unit: "块", art: "cake"),
        // 主食
        CatalogEntry(name: "面包", emoji: "🍞", category: .staple, location: .upperShelf, shelfLifeDays: 4, unit: "袋", art: "bread"),
        CatalogEntry(name: "面条", emoji: "🍜", category: .staple, location: .middleShelf, shelfLifeDays: 3, unit: "袋", art: "noodles"),
        CatalogEntry(name: "燕麦", emoji: "🥣", category: .staple, location: .upperShelf, shelfLifeDays: 180, unit: "袋", art: "oats"),
        CatalogEntry(name: "紫菜", emoji: "🍙", category: .staple, location: .upperShelf, shelfLifeDays: 180, unit: "包", art: "seaweed"),
        // 冷冻
        CatalogEntry(name: "速冻水饺", emoji: "🥟", category: .frozen, location: .freezer, shelfLifeDays: 180, unit: "袋", art: "dumplings"),
        CatalogEntry(name: "冰淇淋", emoji: "🍨", category: .frozen, location: .freezer, shelfLifeDays: 90, unit: "盒", art: "ice-cream"),
        CatalogEntry(name: "冷冻蔬菜", emoji: "🧊", category: .frozen, location: .freezer, shelfLifeDays: 180, unit: "袋", art: "frozen-vegetables"),
        CatalogEntry(name: "冻肉", emoji: "🥩", category: .frozen, location: .freezer, shelfLifeDays: 120, unit: "份", art: "frozen-meat"),
        CatalogEntry(name: "汤圆", emoji: "🍡", category: .frozen, location: .freezer, shelfLifeDays: 180, unit: "袋", art: "tangyuan"),
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

    /// 根据名字猜一个 emoji，猜不到就按分类给。
    static func guessEmoji(for name: String, category: FoodCategory) -> String {
        if let hit = entries.first(where: { name.contains($0.name) || $0.name.contains(name) }) {
            return hit.emoji
        }
        return category.emoji
    }
}
