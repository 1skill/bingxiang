import SwiftUI

/// 清单里的一行食材。
struct ItemRow: View {
    let item: FoodItem

    var body: some View {
        HStack(spacing: 12) {
            Text(item.emoji)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(.fill.tertiary, in: .rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.body.weight(.medium))
                HStack(spacing: 6) {
                    Text(item.quantityDescription)
                    Text("·")
                    Text(item.location.rawValue)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            FreshnessBadge(item: item)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

/// "还有 3 天" / "今天到期" / "过期 2 天" 的小胶囊。
struct FreshnessBadge: View {
    let item: FoodItem

    var body: some View {
        Text(item.expiryDescription)
            .font(.caption.weight(.semibold))
            .foregroundStyle(FridgeMetrics.freshnessColor(item.freshness))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(FridgeMetrics.freshnessColor(item.freshness).opacity(0.14), in: .capsule)
    }
}
