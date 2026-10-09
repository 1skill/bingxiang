import SwiftUI

/// 冰箱的配色：外壳、内壁、层架。参考原作的 Cherry Blossom / Night Sky / Star White / Burgundy / Glacier。
struct FridgeTheme: Identifiable, Hashable {
    let id: String
    let name: String
    /// 门板主色。
    let exterior: Color
    /// 门板上方的高光色。
    let exteriorHighlight: Color
    /// 冷藏区内壁。
    let interior: Color
    /// 冷冻区内壁，比冷藏区更白一点。
    let freezerInterior: Color
    /// 层板。
    let shelf: Color
    /// 层板前沿的亮边。
    let shelfEdge: Color
    /// "…" 按钮的底色。
    let menuTint: Color
    /// 门板是深色的话，字和图标用浅色。
    let isDark: Bool
    /// 内部渲染图是樱花红的，其他颜色靠调色相 / 饱和度 / 亮度派生。
    var renderHue: Angle = .zero
    var renderSaturation: Double = 1
    var renderBrightness: Double = 0

    var doorText: Color { isDark ? .white.opacity(0.85) : .black.opacity(0.7) }

    static let cherryBlossom = FridgeTheme(
        id: "cherryBlossom", name: "樱花红",
        exterior: Color(red: 0.88, green: 0.07, blue: 0.11),
        exteriorHighlight: Color(red: 1.0, green: 0.32, blue: 0.32),
        interior: Color(red: 0.96, green: 0.72, blue: 0.75),
        freezerInterior: Color(red: 0.95, green: 0.87, blue: 0.93),
        shelf: Color(red: 0.92, green: 0.52, blue: 0.58),
        shelfEdge: Color(red: 1.0, green: 0.82, blue: 0.85),
        menuTint: Color(red: 1.0, green: 0.56, blue: 0.64),
        isDark: true
    )

    static let nightSky = FridgeTheme(
        id: "nightSky", name: "夜空",
        exterior: Color(red: 0.16, green: 0.20, blue: 0.26),
        exteriorHighlight: Color(red: 0.34, green: 0.40, blue: 0.48),
        interior: Color(red: 0.40, green: 0.47, blue: 0.58),
        freezerInterior: Color(red: 0.55, green: 0.61, blue: 0.72),
        shelf: Color(red: 0.26, green: 0.32, blue: 0.42),
        shelfEdge: Color(red: 0.62, green: 0.68, blue: 0.80),
        menuTint: Color(red: 0.45, green: 0.52, blue: 0.66),
        isDark: true,
        renderHue: .degrees(-150),
        renderSaturation: 0.45,
        renderBrightness: -0.22
    )

    static let starWhite = FridgeTheme(
        id: "starWhite", name: "星白",
        exterior: Color(red: 0.94, green: 0.94, blue: 0.95),
        exteriorHighlight: .white,
        interior: Color(red: 0.90, green: 0.91, blue: 0.93),
        freezerInterior: Color(red: 0.94, green: 0.96, blue: 0.99),
        shelf: Color(red: 0.78, green: 0.80, blue: 0.84),
        shelfEdge: .white,
        menuTint: Color(red: 0.72, green: 0.75, blue: 0.80),
        isDark: false,
        renderSaturation: 0.08,
        renderBrightness: 0.05
    )

    static let burgundy = FridgeTheme(
        id: "burgundy", name: "酒红",
        exterior: Color(red: 0.35, green: 0.07, blue: 0.12),
        exteriorHighlight: Color(red: 0.56, green: 0.18, blue: 0.24),
        interior: Color(red: 0.56, green: 0.15, blue: 0.21),
        freezerInterior: Color(red: 0.64, green: 0.24, blue: 0.30),
        shelf: Color(red: 0.40, green: 0.09, blue: 0.14),
        shelfEdge: Color(red: 0.78, green: 0.38, blue: 0.44),
        menuTint: Color(red: 0.72, green: 0.32, blue: 0.38),
        isDark: true,
        renderHue: .degrees(-8),
        renderSaturation: 1.35,
        renderBrightness: -0.28
    )

    static let glacier = FridgeTheme(
        id: "glacier", name: "冰川",
        exterior: Color(red: 0.74, green: 0.86, blue: 0.94),
        exteriorHighlight: Color(red: 0.92, green: 0.97, blue: 1.0),
        interior: Color(red: 0.85, green: 0.93, blue: 0.98),
        freezerInterior: Color(red: 0.93, green: 0.97, blue: 1.0),
        shelf: Color(red: 0.60, green: 0.75, blue: 0.88),
        shelfEdge: .white,
        menuTint: Color(red: 0.52, green: 0.70, blue: 0.86),
        isDark: false,
        renderHue: .degrees(190),
        renderSaturation: 0.55,
        renderBrightness: 0.06
    )

    static let all: [FridgeTheme] = [.cherryBlossom, .nightSky, .starWhite, .burgundy, .glacier]

    static func named(_ id: String) -> FridgeTheme {
        all.first { $0.id == id } ?? .cherryBlossom
    }
}
