import SwiftUI

/// 冰箱内部：上面是冷冻室，下面是三层层架、一个保鲜抽屉，右侧是门架。
/// 灯没亮的时候一片漆黑，只隐约看得见轮廓。
struct InteriorView: View {
    let items: [FoodItem]
    let isLightOn: Bool
    @Binding var selectedLocation: StorageLocation?

    var body: some View {
        GeometryReader { proxy in
            let freezerHeight = proxy.size.height * FridgeMetrics.freezerFraction
            VStack(spacing: 0) {
                compartment(.freezer, background: FridgeMetrics.freezerLit)
                    .frame(height: freezerHeight)

                Rectangle()
                    .fill(Color(white: 0.75))
                    .frame(height: 6)

                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        ForEach(StorageLocation.shelves) { shelf in
                            compartment(shelf, background: FridgeMetrics.interiorLit)
                            shelfGlass
                        }
                        compartment(.crisper, background: FridgeMetrics.interiorLit, isDrawer: true)
                    }
                    Rectangle()
                        .fill(Color(white: 0.82))
                        .frame(width: 3)
                    compartment(.door, background: FridgeMetrics.interiorLit, isRack: true)
                        .frame(width: proxy.size.width * FridgeMetrics.doorRackFraction)
                }
            }
            .overlay(alignment: .top) {
                lightBulb
                    .offset(y: freezerHeight + 10)
            }
            .overlay {
                // 关灯：几乎全黑，只留一点轮廓。
                Color.black
                    .opacity(isLightOn ? 0 : 0.84)
                    .animation(.easeOut(duration: 0.18), value: isLightOn)
            }
            .clipShape(.rect(cornerRadius: FridgeMetrics.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: FridgeMetrics.cornerRadius)
                    .strokeBorder(Color(white: 0.7), lineWidth: 6)
            }
        }
    }

    private var shelfGlass: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.9), Color(red: 0.75, green: 0.86, blue: 0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 5)
    }

    private var lightBulb: some View {
        Capsule()
            .fill(isLightOn ? Color(red: 1.0, green: 0.97, blue: 0.85) : Color(white: 0.5))
            .frame(width: 36, height: 8)
            .shadow(color: isLightOn ? .yellow.opacity(0.7) : .clear, radius: isLightOn ? 14 : 0)
            .animation(.easeOut(duration: 0.18), value: isLightOn)
    }

    private func compartment(
        _ location: StorageLocation,
        background: LinearGradient,
        isDrawer: Bool = false,
        isRack: Bool = false
    ) -> some View {
        let shelfItems = items.filter { $0.location == location }
        let isSelected = selectedLocation == location

        return ShelfContent(location: location, items: shelfItems, compact: isRack)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(background)
            .overlay {
                if isDrawer {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.7), lineWidth: 2)
                        .padding(6)
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.accentColor, lineWidth: 3)
                        .padding(3)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(.rect)
            .onTapGesture {
                withAnimation(.snappy) {
                    selectedLocation = isSelected ? nil : location
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(location.rawValue)，\(shelfItems.count) 样食材")
            .accessibilityAddTraits(.isButton)
    }
}

/// 一层架子上摆着的食材。放不下的折叠成 "+N"。
private struct ShelfContent: View {
    let location: StorageLocation
    let items: [FoodItem]
    let compact: Bool

    var body: some View {
        GeometryReader { proxy in
            let tile: CGFloat = compact ? 30 : 40
            let perRow = max(Int(proxy.size.width / (tile + 6)), 1)
            let rows = max(Int(proxy.size.height / (tile + 6)), 1)
            let capacity = max(perRow * rows - 1, 1)
            let visible = Array(items.prefix(capacity))
            let overflow = items.count - visible.count

            VStack(alignment: .leading, spacing: 2) {
                Text(location.rawValue)
                    .font(.system(size: compact ? 9 : 10, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.35))
                    .padding(.horizontal, 6)
                    .padding(.top, 3)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(tile), spacing: 6), count: perRow),
                    alignment: .leading,
                    spacing: 6
                ) {
                    ForEach(visible) { item in
                        ItemBubble(item: item, size: tile)
                    }
                    if overflow > 0 {
                        Text("+\(overflow)")
                            .font(.system(size: compact ? 10 : 12, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: tile, height: tile)
                            .background(.white.opacity(0.6), in: .circle)
                    }
                }
                .padding(.horizontal, 6)
                Spacer(minLength: 0)
            }
        }
    }
}

/// 一颗食材 emoji，角上一个小点表示新鲜度。
struct ItemBubble: View {
    let item: FoodItem
    let size: CGFloat

    var body: some View {
        Text(item.emoji)
            .font(.system(size: size * 0.72))
            .frame(width: size, height: size)
            .overlay(alignment: .topTrailing) {
                if item.freshness != .fresh {
                    Circle()
                        .fill(FridgeMetrics.freshnessColor(item.freshness))
                        .frame(width: size * 0.28, height: size * 0.28)
                        .overlay {
                            Circle().strokeBorder(.white, lineWidth: 1.5)
                        }
                }
            }
            .accessibilityLabel("\(item.name)，\(item.expiryDescription)")
    }
}
