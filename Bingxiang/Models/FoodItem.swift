import Foundation
import SwiftData

/// 食材在冰箱里的存放位置。
enum StorageLocation: String, CaseIterable, Identifiable {
    case freezer = "冷冻室"
    case upperShelf = "上层"
    case middleShelf = "中层"
    case lowerShelf = "下层"
    case crisper = "保鲜抽屉"
    case door = "门架"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .freezer: "snowflake"
        case .upperShelf: "square.split.1x2"
        case .middleShelf: "square.split.1x2"
        case .lowerShelf: "square.split.1x2"
        case .crisper: "tray"
        case .door: "door.left.hand.open"
        }
    }

    var isFreezer: Bool { self == .freezer }

    /// 冰箱内部从上到下的顺序。
    static let shelves: [StorageLocation] = [.upperShelf, .middleShelf, .lowerShelf]
}

/// 食材的大类，用于筛选与统计。
enum FoodCategory: String, CaseIterable, Identifiable {
    case vegetable = "蔬菜"
    case fruit = "水果"
    case meat = "肉类"
    case seafood = "海鲜"
    case dairyEgg = "蛋奶"
    case drink = "饮品"
    case condiment = "调料"
    case leftover = "剩菜熟食"
    case staple = "主食"
    case frozen = "冷冻食品"
    case other = "其他"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .vegetable: "🥬"
        case .fruit: "🍎"
        case .meat: "🥩"
        case .seafood: "🦐"
        case .dairyEgg: "🥚"
        case .drink: "🥤"
        case .condiment: "🧂"
        case .leftover: "🍱"
        case .staple: "🍞"
        case .frozen: "🧊"
        case .other: "📦"
        }
    }
}

/// 一件食材的生命周期状态。原始值是英文标识符，方便写进 `#Predicate`。
enum ItemStatus: String {
    case inStock
    case eaten
    case wasted

    var title: String {
        switch self {
        case .inStock: "在库"
        case .eaten: "吃掉了"
        case .wasted: "扔掉了"
        }
    }
}

/// 新鲜程度，由到期日推算。
enum Freshness: Int, Comparable {
    case expired
    case soon
    case fresh

    static func < (lhs: Freshness, rhs: Freshness) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .expired: "已过期"
        case .soon: "快过期"
        case .fresh: "新鲜"
        }
    }
}

@Model
final class FoodItem {
    var name: String
    var emoji: String
    var categoryRaw: String
    var locationRaw: String
    var quantity: Double
    var unit: String
    var addedDate: Date
    var expiryDate: Date
    var notes: String
    var statusRaw: String
    var resolvedDate: Date?
    var notificationID: String?

    init(
        name: String,
        emoji: String,
        category: FoodCategory,
        location: StorageLocation,
        quantity: Double = 1,
        unit: String = "份",
        addedDate: Date = .now,
        expiryDate: Date,
        notes: String = ""
    ) {
        self.name = name
        self.emoji = emoji
        self.categoryRaw = category.rawValue
        self.locationRaw = location.rawValue
        self.quantity = quantity
        self.unit = unit
        self.addedDate = addedDate
        self.expiryDate = expiryDate
        self.notes = notes
        self.statusRaw = ItemStatus.inStock.rawValue
        self.resolvedDate = nil
        self.notificationID = UUID().uuidString
    }

    var category: FoodCategory {
        get { FoodCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var location: StorageLocation {
        get { StorageLocation(rawValue: locationRaw) ?? .middleShelf }
        set { locationRaw = newValue.rawValue }
    }

    var status: ItemStatus {
        get { ItemStatus(rawValue: statusRaw) ?? .inStock }
        set { statusRaw = newValue.rawValue }
    }

    var isInStock: Bool { status == .inStock }

    /// 距离到期还有几天。负数表示已经过期。
    var daysUntilExpiry: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.startOfDay(for: expiryDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    var freshness: Freshness {
        let days = daysUntilExpiry
        if days < 0 { return .expired }
        if days <= 3 { return .soon }
        return .fresh
    }

    /// 给列表用的到期描述。
    var expiryDescription: String {
        let days = daysUntilExpiry
        switch days {
        case ..<(-1): "过期 \(-days) 天"
        case -1: "昨天过期"
        case 0: "今天到期"
        case 1: "明天到期"
        default: "还有 \(days) 天"
        }
    }

    var quantityDescription: String {
        let number = quantity.formatted(.number.precision(.fractionLength(0...1)))
        return "\(number) \(unit)"
    }

    func markResolved(_ status: ItemStatus) {
        self.status = status
        self.resolvedDate = .now
    }
}
