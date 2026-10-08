import Foundation
import SwiftData

@Model
final class ShoppingItem {
    var name: String
    var emoji: String
    var quantity: Double
    var unit: String
    var isChecked: Bool
    var createdDate: Date
    /// 这条是手动加的，还是菜谱 / 补货建议自动加的。
    var sourceRaw: String

    enum Source: String {
        case manual
        case recipe
        case restock

        var title: String {
            switch self {
            case .manual: "手动添加"
            case .recipe: "来自菜谱"
            case .restock: "补货建议"
            }
        }
    }

    init(name: String, emoji: String, quantity: Double = 1, unit: String = "份", source: Source = .manual) {
        self.name = name
        self.emoji = emoji
        self.quantity = quantity
        self.unit = unit
        self.isChecked = false
        self.createdDate = .now
        self.sourceRaw = source.rawValue
    }

    var source: Source {
        get { Source(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    var quantityDescription: String {
        let number = quantity.formatted(.number.precision(.fractionLength(0...1)))
        return "\(number) \(unit)"
    }
}
