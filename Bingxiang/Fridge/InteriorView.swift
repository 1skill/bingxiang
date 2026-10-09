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

/// 一半冰箱：上面冷藏，下面冷冻，外面一圈红色箱体。
private struct CompartmentColumn: View {
    let theme: FridgeTheme
    let fridgeShelves: [ShelfSpec]
    let freezerShelves: [ShelfSpec]
    let isDoor: Bool
    let onSelect: (StorageLocation) -> Void

    var body: some View {
        GeometryReader { proxy in
            let fridgeHeight = proxy.size.height * FridgeMetrics.fridgeFraction
            VStack(spacing: 6) {
                CompartmentBox(theme: theme, shelves: fridgeShelves, wall: theme.interior, isDoor: isDoor, isFreezer: false, onSelect: onSelect)
                    .frame(height: fridgeHeight - 6)
                CompartmentBox(theme: theme, shelves: freezerShelves, wall: theme.freezerInterior, isDoor: isDoor, isFreezer: true, onSelect: onSelect)
            }
        }
        .padding(EdgeInsets(top: 10, leading: isDoor ? 10 : 6, bottom: 10, trailing: isDoor ? 6 : 10))
        .background(liner)
    }

    /// 箱体：比门板深一点的红。
    private var liner: some View {
        LinearGradient(
            colors: [theme.exterior.opacity(0.95), theme.exterior.opacity(0.75)],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(.black.opacity(0.35))
    }
}

/// 一个有深度的格子：开口有一圈内框，看得见侧壁和地板，玻璃层板带透视，每层顶上有灯打下来。
private struct CompartmentBox: View {
    let theme: FridgeTheme
    let shelves: [ShelfSpec]
    let wall: Color
    let isDoor: Bool
    let isFreezer: Bool
    let onSelect: (StorageLocation) -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            // 透视：侧壁往里收这么多，像从正前方略高一点往里看。
            let inset = min(size.width * 0.09, 44)
            let topInset = min(size.height * 0.05, 22)
            ZStack {
                // 后壁：上亮下暗，像被顶灯照着的烤漆。
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: wall.opacity(0.98), location: 0),
                                .init(color: wall, location: 0.35),
                                .init(color: wall.opacity(0.88), location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        // 一道竖向的柔光
                        LinearGradient(colors: [.clear, .white.opacity(0.10), .clear], startPoint: .leading, endPoint: .trailing)
                    }
                PerspectiveWalls(inset: inset, topInset: topInset, wall: wall)

                // 层架
                VStack(spacing: 0) {
                    ForEach(shelves) { spec in
                        ShelfView(theme: theme, spec: spec, isRack: isDoor, isFreezer: isFreezer, inset: inset)
                            .onTapGesture { onSelect(spec.location) }
                    }
                }
                .padding(.top, topInset)
                .padding(.bottom, 4)
            }
            .clipShape(.rect(cornerRadius: 20))
            .overlay {
                // 开口的内框：一圈深色的门封边，带内阴影。
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(theme.exterior.opacity(0.9), lineWidth: 7)
                RoundedRectangle(cornerRadius: 20)
                    .inset(by: 7)
                    .stroke(.black.opacity(0.35), lineWidth: 6)
                    .blur(radius: 5)
                    .clipShape(RoundedRectangle(cornerRadius: 20).inset(by: 7))
            }
        }
    }
}

/// 顶壁、左右侧壁和地板，四个梯形，都是同一种粉色的不同明暗。
private struct PerspectiveWalls: View {
    let inset: CGFloat
    let topInset: CGFloat
    let wall: Color

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w - inset, y: topInset))
                path.addLine(to: CGPoint(x: inset, y: topInset))
                path.closeSubpath()
            }
            .fill(.black.opacity(0.22))
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: inset, y: topInset))
                path.addLine(to: CGPoint(x: inset, y: h))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.closeSubpath()
            }
            .fill(LinearGradient(colors: [.black.opacity(0.20), .black.opacity(0.06)], startPoint: .leading, endPoint: .trailing))
            Path { path in
                path.move(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: w - inset, y: h))
                path.addLine(to: CGPoint(x: w - inset, y: topInset))
                path.closeSubpath()
            }
            .fill(LinearGradient(colors: [.black.opacity(0.06), .black.opacity(0.20)], startPoint: .leading, endPoint: .trailing))
        }
        .allowsHitTesting(false)
    }
}

/// 玻璃层板：从略高处看过去是一个上窄下宽的梯形，前沿是一条亮边。
private nonisolated struct GlassShelfShape: Shape {
    /// 后沿两侧各收进去多少。
    var backInset: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + backInset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - backInset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// 一层架子：顶上有上一层打下来的光，食材站在玻璃板上，前沿一条发亮的灯带。
/// 门架的话前面多一道半透明挡条。
private struct ShelfView: View {
    let theme: FridgeTheme
    let spec: ShelfSpec
    let isRack: Bool
    let isFreezer: Bool
    let inset: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let boardHeight: CGFloat = min(max(proxy.size.height * 0.16, 12), 22)
            let tile: CGFloat = min(max((proxy.size.height - boardHeight) * 0.98, 30), 140)
            let layout = ShelfLayout(items: spec.items, tile: tile, available: proxy.size.width - inset * 2 - 12)

            ZStack(alignment: .bottom) {
                // 这一格的光：顶上亮（上一层板下的灯带），往下渐暗。
                VStack(spacing: 0) {
                    LinearGradient(colors: [.white.opacity(0.7), .white.opacity(0)], startPoint: .top, endPoint: .bottom)
                        .frame(height: proxy.size.height * 0.5)
                    Spacer(minLength: 0)
                    LinearGradient(colors: [.black.opacity(0), .black.opacity(0.20)], startPoint: .top, endPoint: .bottom)
                        .frame(height: proxy.size.height * 0.35)
                }

                // 玻璃层板
                GlassShelfShape(backInset: inset * 0.45)
                    .fill(
                        LinearGradient(
                            colors: [theme.shelfEdge.opacity(0.55), theme.shelfEdge.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: boardHeight)
                    .padding(.horizontal, inset * 0.55)
                    .overlay(alignment: .bottom) {
                        // 前沿的灯带
                        Rectangle()
                            .fill(.white)
                            .frame(height: 2.5)
                            .padding(.horizontal, inset * 0.55)
                            .shadow(color: .white.opacity(0.95), radius: 5, y: 3)
                            .shadow(color: .white.opacity(0.7), radius: 16, y: 10)
                    }

                // 食材：站在层板前沿上，大小略有差别，挨得近一点。
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(layout.visible) { item in
                        ProductView(item: item, size: tile * Self.scale(for: item))
                    }
                    if layout.overflow > 0 {
                        Text("+\(layout.overflow)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.25), in: .capsule)
                            .padding(.bottom, 6)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, inset + 6)
                .padding(.bottom, boardHeight * 0.35)

                if isRack {
                    // 门架前面的半透明挡条
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [.white.opacity(0.30), .white.opacity(0.12)], startPoint: .top, endPoint: .bottom))
                        .frame(height: 24)
                        .overlay(alignment: .top) {
                            Rectangle().fill(.white.opacity(0.75)).frame(height: 1.5)
                        }
                        .padding(.horizontal, inset * 0.55)
                        .padding(.bottom, boardHeight * 0.3)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(spec.location.rawValue)，\(spec.items.count) 样食材")
        .accessibilityAddTraits(.isButton)
    }

    /// 让每样东西大小略有差别，看起来不那么像一排图标。
    private static func scale(for item: FoodItem) -> CGFloat {
        let hash = item.name.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        return 0.86 + CGFloat(hash % 15) / 100
    }
}

/// 架子上放得下几样：数量多的食材占得宽，放不下的折成 "+N"。
private struct ShelfLayout {
    let visible: [FoodItem]
    let overflow: Int

    init(items: [FoodItem], tile: CGFloat, available: CGFloat) {
        var used: CGFloat = 0
        var visible: [FoodItem] = []
        for item in items {
            let width = ProductView.width(for: item, size: tile) * 0.95 + 2
            if used + width > available && !visible.isEmpty { break }
            used += width
            visible.append(item)
        }
        self.visible = visible
        self.overflow = items.count - visible.count
    }
}

/// 一样食材摆在架子上，底下有一团接触阴影。一样东西只画一个。
struct ProductView: View {
    let item: FoodItem
    let size: CGFloat

    static func width(for item: FoodItem, size: CGFloat) -> CGFloat {
        size
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(.black.opacity(0.30))
                .frame(width: size * 0.85, height: size * 0.16)
                .blur(radius: 3)
                .offset(y: size * 0.05)
            FoodArtView(item: item, size: size)
        }
        .frame(width: size, height: size, alignment: .bottom)
        .overlay(alignment: .topTrailing) {
            if item.freshness != .fresh {
                Circle()
                    .fill(FridgeMetrics.freshnessColor(item.freshness))
                    .frame(width: max(size * 0.18, 10), height: max(size * 0.18, 10))
                    .overlay {
                        Circle().strokeBorder(.white, lineWidth: 1.5)
                    }
                    .offset(x: -size * 0.06, y: size * 0.08)
            }
        }
        .accessibilityLabel("\(item.name)，\(item.quantityDescription)，\(item.expiryDescription)")
    }
}

/// 折痕处的合页：两半箱体之间一道深色的缝。
private struct FoldGap: View {
    let isVertical: Bool

    var body: some View {
        LinearGradient(
            colors: [.black.opacity(0.35), .black.opacity(0.85), .black.opacity(0.35)],
            startPoint: isVertical ? .leading : .top,
            endPoint: isVertical ? .trailing : .bottom
        )
    }
}

/// 一样食材的图：资源目录里有生成好的图就用图，没有就用 emoji。
struct FoodArtView: View {
    let item: FoodItem
    let size: CGFloat

    var body: some View {
        if let name = FoodCatalog.artName(for: item.name), let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.22), radius: 2, y: 2)
        } else {
            Text(item.emoji)
                .font(.system(size: size * 0.84))
                .frame(width: size, height: size)
        }
    }
}
