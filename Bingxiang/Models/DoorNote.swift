import Foundation
import SwiftData
import SwiftUI

/// 贴在冰箱门上的便签磁贴。
@Model
final class DoorNote {
    var text: String
    var colorName: String
    var rotation: Double
    var createdDate: Date
    /// 在冷藏门上的位置，0...1 的比例，可以拖着挪。
    var posX: Double = 0.4
    var posY: Double = 0.55

    static let colorNames = ["yellow", "pink", "mint", "sky", "lilac"]

    init(text: String, colorName: String? = nil, rotation: Double? = nil) {
        self.text = text
        self.colorName = colorName ?? Self.colorNames.randomElement() ?? "yellow"
        self.rotation = rotation ?? Double.random(in: -6...6)
        self.createdDate = .now
        self.posX = Double.random(in: 0.25...0.65)
        self.posY = Double.random(in: 0.66...0.84)
    }

    var color: Color {
        Self.color(named: colorName)
    }

    static func color(named colorName: String) -> Color {
        switch colorName {
        case "pink": Color(red: 1.0, green: 0.80, blue: 0.86)
        case "mint": Color(red: 0.78, green: 0.95, blue: 0.86)
        case "sky": Color(red: 0.78, green: 0.90, blue: 1.0)
        case "lilac": Color(red: 0.88, green: 0.82, blue: 1.0)
        default: Color(red: 1.0, green: 0.95, blue: 0.62)
        }
    }
}
