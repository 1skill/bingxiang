import SwiftUI

enum FridgeMetrics {
    /// 冷藏门（和冷藏区）占整台冰箱的高度比例，剩下的是冷冻。
    static let fridgeFraction: CGFloat = 0.62

    static func freshnessColor(_ freshness: Freshness) -> Color {
        switch freshness {
        case .expired: .red
        case .soon: .orange
        case .fresh: .green
        }
    }

    /// 把手、字母用的铬色。
    static let chrome = LinearGradient(
        colors: [Color(white: 0.58), Color(white: 0.96), Color(white: 0.80), Color(white: 0.55)],
        startPoint: .leading,
        endPoint: .trailing
    )
}
