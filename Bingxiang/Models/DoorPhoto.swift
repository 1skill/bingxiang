import Foundation
import SwiftData

/// 贴在冰箱门上的拍立得照片，或者手写的涂鸦便签。
@Model
final class DoorPhoto {
    @Attribute(.externalStorage) var imageData: Data
    var posX: Double
    var posY: Double
    var rotation: Double
    var createdDate: Date
    /// 手写涂鸦的话，没有拍立得白边，画在便签纸上。
    var isDrawing: Bool = false
    /// 涂鸦用的便签纸颜色，见 `DoorNote.colorNames`。
    var paperColor: String = "yellow"

    init(imageData: Data, isDrawing: Bool = false, paperColor: String = "yellow") {
        self.imageData = imageData
        self.isDrawing = isDrawing
        self.paperColor = paperColor
        self.posX = Double.random(in: 0.30...0.70)
        self.posY = Double.random(in: 0.60...0.80)
        self.rotation = Double.random(in: -8...8)
        self.createdDate = .now
    }
}
