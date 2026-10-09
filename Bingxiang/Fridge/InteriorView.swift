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

/// 一个有深度的格子：看得见侧壁、顶壁和地板，层板有厚度，层板下面有灯带。
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
            // 透视：侧壁往里收这么多，就像从正前方略高一点看进去。
            let inset = min(size.width * 0.07, 34)
            let topInset = min(size.height * 0.06, 24)
            ZStack {
                // 后壁：中间亮，四周暗。
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [wall.opacity(0.95), wall, wall.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                // 顶壁、侧壁、地板
                PerspectiveWalls(inset: inset, topInset: topInset, wall: wall)
                // 顶上的灯带
                Capsule()
                    .fill(.white)
                    .frame(width: size.width - inset * 2 - 24, height: 4)
                    .shadow(color: .white.opacity(0.9), radius: 10)
                    .shadow(color: .white.opacity(0.6), radius: 24)
                    .position(x: size.width / 2, y: topInset + 3)

                // 层架
                VStack(spacing: 0) {
                    ForEach(shelves) { spec in
                        ShelfView(theme: theme, spec: spec, isRack: isDoor, isFreezer: isFreezer)
                            .onTapGesture { onSelect(spec.location) }
                    }
                }
                .padding(.horizontal, inset)
                .padding(.top, topInset)
                .padding(.bottom, 6)
            }
            .clipShape(.rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.black.opacity(0.25), lineWidth: 1)
            }
        }
    }
}

/// 顶壁、左右侧壁和地板，四个梯形。
private struct PerspectiveWalls: View {
    let inset: CGFloat
    let topInset: CGFloat
    let wall: Color

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            // 顶壁最暗
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w - inset, y: topInset))
                path.addLine(to: CGPoint(x: inset, y: topInset))
                path.closeSubpath()
            }
            .fill(.black.opacity(0.28))
            // 左侧壁
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: inset, y: topInset))
                path.addLine(to: CGPoint(x: inset, y: h))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.closeSubpath()
            }
            .fill(LinearGradient(colors: [.black.opacity(0.22), .black.opacity(0.10)], startPoint: .leading, endPoint: .trailing))
            // 右侧壁
            Path { path in
                path.move(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: w - inset, y: h))
                path.addLine(to: CGPoint(x: w - inset, y: topInset))
                path.closeSubpath()
            }
            .fill(LinearGradient(colors: [.black.opacity(0.10), .black.opacity(0.22)], startPoint: .leading, endPoint: .trailing))
            // 地板最亮
            Path { path in
                path.move(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: w - inset, y: h - 6))
                path.addLine(to: CGPoint(x: inset, y: h - 6))
                path.closeSubpath()
            }
            .fill(.white.opacity(0.25))
        }
        .allowsHitTesting(false)
    }
}

/// 一层架子：食材站在层板上，层板有顶面和前沿，前沿下面一条亮灯带。
/// 门架的话前面多一道半透明挡条。
private struct ShelfView: View {
    let theme: FridgeTheme
    let spec: ShelfSpec
    let isRack: Bool
    let isFreezer: Bool

    var body: some View {
        GeometryReader { proxy in
            let boardHeight: CGFloat = spec.isDrawer ? 16 : 12
            let tile: CGFloat = min(max((proxy.size.height - boardHeight) * (isRack ? 0.66 : 0.74), 30), 84)
            let layout = ShelfLayout(items: spec.items, tile: tile, available: proxy.size.width - 28)

            ZStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(layout.visible) { item in
                        ProductView(item: item, size: tile)
                    }
                    if layout.overflow > 0 {
                        Text("+\(layout.overflow)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.35), in: .capsule)
                            .padding(.bottom, 8)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, boardHeight + 2)

                // 层板：顶面 + 前沿 + 前沿下面的灯带
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(LinearGradient(colors: [theme.shelfEdge, theme.shelfEdge.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                        .frame(height: boardHeight * 0.45)
                    Rectangle()
                        .fill(LinearGradient(colors: [theme.shelf, theme.shelf.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                        .frame(height: boardHeight * 0.55)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(.white.opacity(0.95))
                                .frame(height: 2)
                                .shadow(color: .white, radius: 6, y: 4)
                                .shadow(color: .white.opacity(0.8), radius: 14, y: 8)
                        }
                }
                .padding(.horizontal, -2)

                if isRack {
                    // 门架前面的挡条，半透明塑料。
                    Rectangle()
                        .fill(theme.shelfEdge.opacity(0.42))
                        .frame(height: 22)
                        .overlay(alignment: .top) {
                            Rectangle().fill(.white.opacity(0.7)).frame(height: 1.5)
                        }
                        .padding(.bottom, boardHeight)
                        .allowsHitTesting(false)
                }

                if spec.isDrawer {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.white.opacity(0.6), lineWidth: 2)
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                        .padding(.bottom, boardHeight + 2)
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
}

/// 架子上放得下几样：数量多的食材占得宽，放不下的折成 "+N"。
private struct ShelfLayout {
    let visible: [FoodItem]
    let overflow: Int

    init(items: [FoodItem], tile: CGFloat, available: CGFloat) {
        var used: CGFloat = 0
        var visible: [FoodItem] = []
        for item in items {
            let width = ProductView.width(for: item, size: tile) + 8
            if used + width > available && !visible.isEmpty { break }
            used += width
            visible.append(item)
        }
        self.visible = visible
        self.overflow = items.count - visible.count
    }
}

/// 一样食材摆在架子上：数量多的显示好几份叠在一起，底下有一团接触阴影。
struct ProductView: View {
    let item: FoodItem
    let size: CGFloat

    /// 这些单位是一个一个数的，多买了就摆好几个；"份"之类的只摆一个。
    private static let countableUnits: Set<String> = ["个", "根", "盒", "瓶", "罐", "杯", "块", "袋", "包", "串", "颗", "条", "头", "把"]

    static func copies(for item: FoodItem) -> Int {
        guard countableUnits.contains(item.unit) else { return 1 }
        return max(1, min(Int(item.quantity.rounded()), 3))
    }

    static func width(for item: FoodItem, size: CGFloat) -> CGFloat {
        size + CGFloat(copies(for: item) - 1) * size * 0.42
    }

    var body: some View {
        let copies = Self.copies(for: item)
        ZStack(alignment: .bottomLeading) {
            // 接触阴影
            Ellipse()
                .fill(.black.opacity(0.28))
                .frame(width: Self.width(for: item, size: size) * 0.9, height: size * 0.18)
                .blur(radius: 3)
                .offset(x: Self.width(for: item, size: size) * 0.05, y: size * 0.06)
            ForEach(0..<copies, id: \.self) { index in
                FoodArtView(item: item, size: size)
                    .offset(x: CGFloat(index) * size * 0.42, y: CGFloat(index) * -1.5)
            }
        }
        .frame(width: Self.width(for: item, size: size), height: size, alignment: .bottomLeading)
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
                .frame(width: size * 1.08, height: size * 1.08)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 2)
        } else {
            Text(item.emoji)
                .font(.system(size: size * 0.84))
                .frame(width: size, height: size)
        }
    }
}
