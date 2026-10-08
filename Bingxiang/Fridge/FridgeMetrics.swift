import SwiftUI

/// 冰箱外观的公共尺寸和颜色，门和内部要对得上。
enum FridgeMetrics {
    /// 冷冻室占整台冰箱的高度比例。
    static let freezerFraction: CGFloat = 0.24
    /// 门架占主冷藏室的宽度比例。
    static let doorRackFraction: CGFloat = 0.22
    static let cornerRadius: CGFloat = 28

    static func doorSteel(_ scheme: ColorScheme) -> LinearGradient {
        let colors: [Color] = scheme == .dark
            ? [Color(white: 0.36), Color(white: 0.26), Color(white: 0.31)]
            : [Color(white: 0.95), Color(white: 0.84), Color(white: 0.90)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let interiorLit = LinearGradient(
        colors: [Color(red: 0.97, green: 0.99, blue: 1.0), Color(red: 0.86, green: 0.93, blue: 0.98)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let freezerLit = LinearGradient(
        colors: [Color(red: 0.86, green: 0.94, blue: 1.0), Color(red: 0.74, green: 0.87, blue: 0.98)],
        startPoint: .top,
        endPoint: .bottom
    )

    static func freshnessColor(_ freshness: Freshness) -> Color {
        switch freshness {
        case .expired: .red
        case .soon: .orange
        case .fresh: .green
        }
    }
}
