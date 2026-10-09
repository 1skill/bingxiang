import Foundation
import SwiftData

/// 贴在冰箱门上的拍立得照片。
@Model
final class DoorPhoto {
    @Attribute(.externalStorage) var imageData: Data
    var posX: Double
    var posY: Double
    var rotation: Double
    var createdDate: Date

    init(imageData: Data) {
        self.imageData = imageData
        self.posX = Double.random(in: 0.30...0.70)
        self.posY = Double.random(in: 0.60...0.80)
        self.rotation = Double.random(in: -8...8)
        self.createdDate = .now
    }
}
