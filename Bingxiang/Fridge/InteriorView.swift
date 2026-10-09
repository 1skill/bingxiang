import SwiftUI

/// 展开后看到的冰箱内部。折痕就是冰箱的合页：
/// 一边是门的内侧（门架），另一边是柜体（层架 + 底部冷冻区）。
/// 半折时门那一半离你远，会虚化一点，像相机的景深。
struct InteriorView: View {
    let theme: FridgeTheme
    let items: [FoodItem]
    let isLightOn: Bool
    /// 门那一半的虚化半径，由铰链角度决定。
    let doorBlur: CGFloat
    let onSelect: (StorageLocation) -> Void

    var body: some View {
        GeometryReader { proxy in
            // 👇 包含"不活跃"的分割区域：平放时折痕也在，只是不影响布局。我们就要它的位置。
            let fold = proxy.reservedRegions(kind: .division, options: [.includeInactive]).first?.frame
            let size = proxy.size

            Group {
                if let fold, fold.height >= fold.width {
                    // 书本：左边门，右边柜体。
                    HStack(spacing: 0) {
                        doorInside
                            .frame(width: max(fold.minX, 0))
                            .blur(radius: doorBlur)
                        FoldGap(isVertical: true)
                            .frame(width: fold.width)
                        cabinet
                            .frame(width: max(size.width - fold.maxX, 0))
                    }
                } else if let fold {
                    // 桌面：上面柜体，下面门。
                    VStack(spacing: 0) {
                        cabinet
                            .frame(height: max(fold.minY, 0))
                        FoldGap(isVertical: false)
                            .frame(height: fold.height)
                        doorInside
                            .frame(height: max(size.height - fold.maxY, 0))
                            .blur(radius: doorBlur)
                    }
                } else if size.width > size.height {
                    HStack(spacing: 0) {
                        doorInside
                            .frame(width: size.width * 0.44)
                        FoldGap(isVertical: true)
                            .frame(width: 10)
                        cabinet
                    }
                } else {
                    VStack(spacing: 0) {
                        cabinet
                            .frame(height: size.height * 0.60)
                        FoldGap(isVertical: false)
                            .frame(height: 10)
                        doorInside
                    }
                }
            }
            .animation(.smooth, value: fold)
        }
        .overlay {
            // 关灯：几乎全黑。
            Color.black
                .opacity(isLightOn ? 0 : 0.88)
                .animation(.easeOut(duration: 0.2), value: isLightOn)
                .allowsHitTesting(false)
        }
    }

    // MARK: 两半

    private var cabinet: some View {
        CompartmentColumn(
            theme: theme,
            fridgeShelves: [
                ShelfSpec(location: .upperShelf, items: items(at: .upperShelf)),
                ShelfSpec(location: .middleShelf, items: items(at: .middleShelf)),
                ShelfSpec(location: .lowerShelf, items: items(at: .lowerShelf)),
                ShelfSpec(location: .crisper, items: items(at: .crisper), isDrawer: true),
            ],
            freezerShelves: splitFreezer(keepEven: true),
            isDoor: false,
            onSelect: onSelect
        )
    }

    private var doorInside: some View {
        let doorItems = items(at: .door)
        return CompartmentColumn(
            theme: theme,
            fridgeShelves: [
                ShelfSpec(location: .door, items: doorItems.enumerated().filter { $0.offset % 3 == 0 }.map(\.element)),
                ShelfSpec(location: .door, items: doorItems.enumerated().filter { $0.offset % 3 == 1 }.map(\.element)),
                ShelfSpec(location: .door, items: doorItems.enumerated().filter { $0.offset % 3 == 2 }.map(\.element)),
            ],
            freezerShelves: splitFreezer(keepEven: false),
            isDoor: true,
            onSelect: onSelect
        )
    }

    private func items(at location: StorageLocation) -> [FoodItem] {
        items.filter { $0.location == location }
    }

    /// 冷冻食材一半放柜体、一半放冷冻门架，看起来满一点。
    private func splitFreezer(keepEven: Bool) -> [ShelfSpec] {
        let frozen = items(at: .freezer).enumerated()
            .filter { ($0.offset % 2 == 0) == keepEven }
            .map(\.element)
        let half = (frozen.count + 1) / 2
        return [
            ShelfSpec(location: .freezer, items: Array(frozen.prefix(half))),
            ShelfSpec(location: .freezer, items: Array(frozen.dropFirst(half))),
        ]
    }
}

struct ShelfSpec: Identifiable {
    let id = UUID()
    let location: StorageLocation
    let items: [FoodItem]
    var isDrawer = false
}

/// 一半冰箱：上面冷藏，下面冷冻，中间一道缝。
private struct CompartmentColumn: View {
    let theme: FridgeTheme
    let fridgeShelves: [ShelfSpec]
    let freezerShelves: [ShelfSpec]
    let isDoor: Bool
    let onSelect: (StorageLocation) -> Void

    var body: some View {
        GeometryReader { proxy in
            let fridgeHeight = proxy.size.height * FridgeMetrics.fridgeFraction
            VStack(spacing: 0) {
                zone(shelves: fridgeShelves, wall: theme.interior)
                    .frame(height: fridgeHeight - 4)
                Rectangle()
                    .fill(.black.opacity(0.55))
                    .frame(height: 8)
                zone(shelves: freezerShelves, wall: theme.freezerInterior)
            }
        }
        .padding(isDoor ? EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 4) : EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 8))
        .background(.black.opacity(0.7))
    }

    private func zone(shelves: [ShelfSpec], wall: Color) -> some View {
        VStack(spacing: 0) {
            ForEach(shelves) { spec in
                ShelfView(theme: theme, spec: spec, isRack: isDoor)
                    .onTapGesture { onSelect(spec.location) }
            }
        }
        .background {
            ZStack {
                wall
                // 四周暗一点，有进深。
                RadialGradient(
                    colors: [.clear, .black.opacity(0.22)],
                    center: .center,
                    startRadius: 40,
                    endRadius: 600
                )
            }
        }
        .clipShape(.rect(cornerRadius: 22))
    }
}

/// 一层架子：顶上有灯带，底下是层板，中间摆食材。门架的话前面多一道挡条。
private struct ShelfView: View {
    let theme: FridgeTheme
    let spec: ShelfSpec
    let isRack: Bool

    var body: some View {
        GeometryReader { proxy in
            let tile: CGFloat = min(max(proxy.size.height * (isRack ? 0.50 : 0.54), 28), 64)
            let capacity = max(Int((proxy.size.width - 20) / (tile + 6)), 1)
            let visible = Array(spec.items.prefix(capacity))
            let overflow = spec.items.count - visible.count

            ZStack(alignment: .bottom) {
                // 灯带：从上一层板底下打下来的光。
                LinearGradient(colors: [.white.opacity(0.75), .white.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 26)
                    .frame(maxHeight: .infinity, alignment: .top)

                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(visible) { item in
                        ItemBubble(item: item, size: tile)
                    }
                    if overflow > 0 {
                        Text("+\(overflow)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.35), in: .capsule)
                            .padding(.bottom, 8)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)

                // 层板
                VStack(spacing: 0) {
                    Rectangle().fill(theme.shelfEdge).frame(height: 2)
                    Rectangle().fill(theme.shelf).frame(height: spec.isDrawer ? 14 : 8)
                    Rectangle().fill(.black.opacity(0.18)).frame(height: 2)
                }

                if isRack {
                    // 门架前面的挡条，半透明。
                    Rectangle()
                        .fill(theme.shelfEdge.opacity(0.35))
                        .frame(height: 20)
                        .overlay(alignment: .top) {
                            Rectangle().fill(.white.opacity(0.6)).frame(height: 1)
                        }
                        .padding(.bottom, 10)
                        .allowsHitTesting(false)
                }

                if spec.isDrawer {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.white.opacity(0.55), lineWidth: 1.5)
                        .padding(.horizontal, 6)
                        .padding(.top, 10)
                        .padding(.bottom, 14)
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .topLeading) {
                Text(spec.location.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.35))
                    .padding(.leading, 8)
                    .padding(.top, 5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(spec.location.rawValue)，\(spec.items.count) 样食材")
        .accessibilityAddTraits(.isButton)
    }
}

/// 折痕处的一道暗缝。
private struct FoldGap: View {
    let isVertical: Bool

    var body: some View {
        LinearGradient(
            colors: [.black.opacity(0.15), .black.opacity(0.6), .black.opacity(0.15)],
            startPoint: isVertical ? .leading : .top,
            endPoint: isVertical ? .trailing : .bottom
        )
    }
}

/// 一颗食材 emoji，底下有影子，角上一个小点表示新鲜度。
struct ItemBubble: View {
    let item: FoodItem
    let size: CGFloat

    var body: some View {
        Text(item.emoji)
            .font(.system(size: size * 0.82))
            .shadow(color: .black.opacity(0.35), radius: 3, y: 3)
            .frame(width: size, height: size)
            .overlay(alignment: .topTrailing) {
                if item.freshness != .fresh {
                    Circle()
                        .fill(FridgeMetrics.freshnessColor(item.freshness))
                        .frame(width: size * 0.26, height: size * 0.26)
                        .overlay {
                            Circle().strokeBorder(.white, lineWidth: 1.5)
                        }
                }
            }
            .accessibilityLabel("\(item.name)，\(item.expiryDescription)")
    }
}
