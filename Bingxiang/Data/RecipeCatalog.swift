import Foundation

/// 一道家常菜。`ingredients` 用的名字和 `FoodCatalog` 对齐，方便匹配冰箱库存。
struct Recipe: Identifiable, Hashable {
    let name: String
    let emoji: String
    let minutes: Int
    let ingredients: [String]
    let steps: [String]

    var id: String { name }
}

/// 菜谱与库存的匹配结果。
struct RecipeMatch: Identifiable {
    let recipe: Recipe
    let have: [String]
    let missing: [String]
    /// 用到了多少快过期的食材，越多越应该先做。
    let usesExpiringCount: Int

    var id: String { recipe.id }

    var completeness: Double {
        guard !recipe.ingredients.isEmpty else { return 0 }
        return Double(have.count) / Double(recipe.ingredients.count)
    }

    var isReady: Bool { missing.isEmpty }
}

enum RecipeCatalog {
    static let recipes: [Recipe] = [
        Recipe(name: "番茄炒蛋", emoji: "🍅", minutes: 10, ingredients: ["番茄", "鸡蛋", "小葱"],
               steps: ["鸡蛋打散加少许盐。", "番茄切块。", "热油炒蛋至凝固盛出。", "下番茄炒出汁，倒回鸡蛋，加糖盐翻匀，撒葱花。"]),
        Recipe(name: "青椒肉丝", emoji: "🫑", minutes: 15, ingredients: ["青椒", "猪肉", "大蒜"],
               steps: ["猪肉切丝，用生抽淀粉腌十分钟。", "青椒切丝，蒜切片。", "热油滑炒肉丝变色盛出。", "下蒜片青椒炒软，倒回肉丝调味出锅。"]),
        Recipe(name: "蒜蓉西兰花", emoji: "🥦", minutes: 10, ingredients: ["西兰花", "大蒜"],
               steps: ["西兰花掰小朵焯水一分钟。", "蒜切末。", "热油爆香蒜末，下西兰花快炒，加盐出锅。"]),
        Recipe(name: "可乐鸡翅", emoji: "🍗", minutes: 30, ingredients: ["鸡翅", "可乐", "小葱"],
               steps: ["鸡翅划两刀，煎至两面金黄。", "倒入可乐没过鸡翅，加生抽。", "中火收汁至浓稠，撒葱花。"]),
        Recipe(name: "土豆炖牛肉", emoji: "🥘", minutes: 60, ingredients: ["土豆", "牛肉", "洋葱", "胡萝卜"],
               steps: ["牛肉切块焯水。", "洋葱胡萝卜土豆切块。", "炒香洋葱，下牛肉加水炖四十分钟。", "下土豆胡萝卜再炖二十分钟，调味。"]),
        Recipe(name: "紫菜蛋花汤", emoji: "🍲", minutes: 8, ingredients: ["紫菜", "鸡蛋", "小葱"],
               steps: ["水烧开，下紫菜。", "鸡蛋打散淋入成蛋花。", "加盐、香油、葱花。"]),
        Recipe(name: "凉拌黄瓜", emoji: "🥒", minutes: 5, ingredients: ["黄瓜", "大蒜"],
               steps: ["黄瓜拍碎切段。", "蒜末、醋、生抽、糖、香油拌匀。", "冷藏十分钟更好吃。"]),
        Recipe(name: "蚝油生菜", emoji: "🥬", minutes: 6, ingredients: ["生菜", "蚝油", "大蒜"],
               steps: ["生菜焯水十秒捞出。", "蒜末爆香，加蚝油、少许水和糖烧开。", "淋在生菜上。"]),
        Recipe(name: "香菇滑鸡", emoji: "🍄", minutes: 25, ingredients: ["香菇", "鸡胸肉", "小葱"],
               steps: ["鸡肉切块用生抽淀粉腌十分钟。", "香菇切片。", "炒香鸡肉，下香菇加少许水焖八分钟，收汁撒葱。"]),
        Recipe(name: "酸辣土豆丝", emoji: "🥔", minutes: 12, ingredients: ["土豆", "青椒", "大蒜"],
               steps: ["土豆切丝泡水。", "蒜末、干辣椒爆香。", "下土豆丝大火快炒，加醋、盐，出锅前下青椒丝。"]),
        Recipe(name: "麻婆豆腐", emoji: "🌶️", minutes: 15, ingredients: ["豆腐", "猪肉", "豆瓣酱", "小葱"],
               steps: ["豆腐切块焯水。", "炒香肉末，下豆瓣酱炒出红油。", "加水下豆腐烧五分钟，勾薄芡撒葱花花椒粉。"]),
        Recipe(name: "红烧排骨", emoji: "🍖", minutes: 50, ingredients: ["排骨", "大蒜", "小葱"],
               steps: ["排骨焯水。", "炒糖色，下排骨上色。", "加生抽、老抽、蒜、葱和热水炖四十分钟，收汁。"]),
        Recipe(name: "冬瓜排骨汤", emoji: "🍲", minutes: 60, ingredients: ["冬瓜", "排骨", "小葱"],
               steps: ["排骨焯水后加水炖四十分钟。", "冬瓜切块下锅再煮十五分钟。", "加盐撒葱花。"]),
        Recipe(name: "牛奶燕麦粥", emoji: "🥣", minutes: 5, ingredients: ["牛奶", "燕麦", "香蕉"],
               steps: ["燕麦加牛奶小火煮三分钟。", "切香蕉片铺上，可加蓝莓。"]),
        Recipe(name: "水果酸奶杯", emoji: "🍓", minutes: 3, ingredients: ["酸奶", "草莓", "蓝莓"],
               steps: ["水果洗净切块。", "和酸奶分层装杯，可撒燕麦。"]),
        Recipe(name: "虾仁炒蛋", emoji: "🦐", minutes: 10, ingredients: ["虾仁", "鸡蛋", "小葱"],
               steps: ["虾仁解冻擦干，加少许盐胡椒。", "鸡蛋打散加葱花。", "炒虾仁变色，倒入蛋液滑炒至凝固。"]),
        Recipe(name: "韭菜炒蛋", emoji: "🌿", minutes: 8, ingredients: ["韭菜", "鸡蛋"],
               steps: ["韭菜切段。", "鸡蛋炒散盛出。", "下韭菜炒软，倒回鸡蛋加盐翻匀。"]),
        Recipe(name: "芹菜炒肉", emoji: "🥬", minutes: 12, ingredients: ["芹菜", "猪肉", "大蒜"],
               steps: ["芹菜斜切段，肉切片腌制。", "滑炒肉片盛出。", "蒜片爆香下芹菜，倒回肉片调味。"]),
        Recipe(name: "培根炒蛋", emoji: "🥓", minutes: 8, ingredients: ["培根", "鸡蛋", "面包"],
               steps: ["培根煎脆。", "鸡蛋炒嫩。", "配烤面包。"]),
        Recipe(name: "胡萝卜玉米排骨汤", emoji: "🌽", minutes: 70, ingredients: ["胡萝卜", "玉米", "排骨"],
               steps: ["排骨焯水。", "加水、玉米段、胡萝卜块炖一小时。", "加盐即可。"]),
        Recipe(name: "蒜蓉菠菜", emoji: "🥬", minutes: 6, ingredients: ["菠菜", "大蒜"],
               steps: ["菠菜焯水去草酸。", "蒜末爆香，下菠菜快炒加盐。"]),
        Recipe(name: "香蕉牛奶", emoji: "🍌", minutes: 3, ingredients: ["香蕉", "牛奶"],
               steps: ["香蕉切段和牛奶一起打成奶昔。"]),
    ]

    /// 用在库食材给每道菜打分：先看能不能直接做，再看用掉多少快过期的，最后看完成度。
    static func matches(for items: [FoodItem]) -> [RecipeMatch] {
        let stock = items.filter(\.isInStock)
        let names = stock.map(\.name)
        let expiringNames = stock.filter { $0.freshness != .fresh }.map(\.name)

        return recipes.map { recipe in
            var have: [String] = []
            var missing: [String] = []
            var expiring = 0
            for ingredient in recipe.ingredients {
                if names.contains(where: { matches(ingredient: ingredient, itemName: $0) }) {
                    have.append(ingredient)
                    if expiringNames.contains(where: { matches(ingredient: ingredient, itemName: $0) }) {
                        expiring += 1
                    }
                } else {
                    missing.append(ingredient)
                }
            }
            return RecipeMatch(recipe: recipe, have: have, missing: missing, usesExpiringCount: expiring)
        }
        .sorted { lhs, rhs in
            if lhs.isReady != rhs.isReady { return lhs.isReady }
            if lhs.usesExpiringCount != rhs.usesExpiringCount { return lhs.usesExpiringCount > rhs.usesExpiringCount }
            if lhs.completeness != rhs.completeness { return lhs.completeness > rhs.completeness }
            return lhs.recipe.minutes < rhs.recipe.minutes
        }
    }

    /// "鸡蛋" 能匹配 "土鸡蛋"，"猪肉" 能匹配 "猪肉末"。
    static func matches(ingredient: String, itemName: String) -> Bool {
        itemName.contains(ingredient) || ingredient.contains(itemName)
    }
}
