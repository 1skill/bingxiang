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

    static let colorNames = ["yellow", "pink", "mint", "sky", "lilac"]

    init(text: String, colorName: String? = nil, rotation: Double? = nil) {
        self.text = text
        self.colorName = colorName ?? Self.colorNames.randomElement() ?? "yellow"
        self.rotation = rotation ?? Double.random(in: -6...6)
        self.createdDate = .now
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
