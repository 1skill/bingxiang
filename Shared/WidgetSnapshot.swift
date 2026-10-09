import Foundation

/// App 写、小组件读的一份快照，放在 App Group 的共享容器里。
/// 小组件不碰 SwiftData，只读这份 JSON。
nonisolated struct WidgetSnapshot: Codable, Equatable {
    struct Item: Codable, Equatable {
        let name: String
        let emoji: String
        /// 负数表示已经过期。
        let daysLeft: Int
    }

    var themeID: String
    var inStockCount: Int
    /// 快过期和已过期的，按到期日排好，最多 6 样。
    var expiring: [Item]
    var shoppingNames: [String]
    var shoppingCount: Int
    var noteTexts: [String]
    var openCount: Int
    var updatedAt: Date

    static let appGroupID = "group.dev.bingxiang.app"

    static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("widget-snapshot.json")
    }

    static func load() -> WidgetSnapshot? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }

    func save() throws {
        guard let url = Self.fileURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(self).write(to: url, options: .atomic)
    }

    /// 没有数据时（第一次加小组件、还没打开过 app）用的占位内容。
    static let placeholder = WidgetSnapshot(
        themeID: "cherryBlossom",
        inStockCount: 12,
        expiring: [
            Item(name: "牛奶", emoji: "🥛", daysLeft: 1),
            Item(name: "草莓", emoji: "🍓", daysLeft: 0),
            Item(name: "黄瓜", emoji: "🥒", daysLeft: -1),
        ],
        shoppingNames: ["鸡蛋", "西兰花"],
        shoppingCount: 2,
        noteTexts: ["周末火锅 🍲"],
        openCount: 3,
        updatedAt: .now
    )
}
