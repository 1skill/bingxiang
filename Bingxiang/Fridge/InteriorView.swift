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

/// 一半冰箱：一整个柜体，上面冷藏，下面冷冻，中间一块隔板，外面薄薄一圈红色箱体。
private struct CompartmentColumn: View {
    let theme: FridgeTheme
    let fridgeShelves: [ShelfSpec]
    let freezerShelves: [ShelfSpec]
    let isDoor: Bool
    let onSelect: (StorageLocation) -> Void

    var body: some View {
        CompartmentBox(theme: theme, fridgeShelves: fridgeShelves, freezerShelves: freezerShelves, isDoor: isDoor, onSelect: onSelect)
            .padding(EdgeInsets(top: 5, leading: isDoor ? 5 : 2, bottom: 5, trailing: isDoor ? 2 : 5))
            .background(
                LinearGradient(colors: [theme.exterior, theme.exterior.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    .overlay(.black.opacity(0.3))
            )
    }
}

/// 一个有深度的柜体：从略高处往里看，看得见顶壁、侧壁和地板；玻璃层板带透视；每层顶上有灯打下来。
private struct CompartmentBox: View {
    let theme: FridgeTheme
    let fridgeShelves: [ShelfSpec]
    let freezerShelves: [ShelfSpec]
    let isDoor: Bool
    let onSelect: (StorageLocation) -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            // 透视：侧壁往里收这么多。
            let inset = min(size.width * 0.12, 64)
            let topInset = min(size.height * 0.07, 40)
            let dividerHeight: CGFloat = 16
            let fridgeHeight = size.height * FridgeMetrics.fridgeFraction

            ZStack {
                // 后壁：冷藏区粉，冷冻区偏白，都是上亮下暗。
                VStack(spacing: 0) {
                    wall(theme.interior)
                        .frame(height: fridgeHeight)
                    wall(theme.freezerInterior)
                }
                PerspectiveWalls(inset: inset, topInset: topInset, wall: theme.interior)

                // 冷藏和冷冻之间的隔板
                VStack(spacing: 0) {
                    Rectangle().fill(theme.shelfEdge).frame(height: dividerHeight * 0.45)
                    Rectangle().fill(theme.shelf).frame(height: dividerHeight * 0.55)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(.white.opacity(0.9)).frame(height: 2)
                                .shadow(color: .white, radius: 6, y: 4)
                                .shadow(color: .white.opacity(0.7), radius: 16, y: 10)
                        }
                }
                .frame(height: dividerHeight)
                .position(x: size.width / 2, y: fridgeHeight)

                // 层架
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        ForEach(fridgeShelves) { spec in
                            ShelfView(theme: theme, spec: spec, isRack: isDoor, inset: inset)
                                .onTapGesture { onSelect(spec.location) }
                        }
                    }
                    .frame(height: max(fridgeHeight - topInset - dividerHeight / 2, 0))
                    Color.clear
                        .frame(height: dividerHeight)
                    VStack(spacing: 0) {
                        ForEach(freezerShelves) { spec in
                            ShelfView(theme: theme, spec: spec, isRack: isDoor, inset: inset)
                                .onTapGesture { onSelect(spec.location) }
                        }
                    }
                }
                .padding(.top, topInset)
                .padding(.bottom, 4)
            }
            .clipShape(.rect(cornerRadius: 16))
            .overlay {
                // 开口的门封边：薄薄一圈，带内阴影。
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(theme.exterior.opacity(0.85), lineWidth: 4)
                RoundedRectangle(cornerRadius: 16)
                    .inset(by: 4)
                    .stroke(.black.opacity(0.4), lineWidth: 8)
                    .blur(radius: 6)
                    .clipShape(RoundedRectangle(cornerRadius: 16).inset(by: 4))
            }
        }
    }

    private func wall(_ color: Color) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: color.opacity(0.98), location: 0),
                        .init(color: color, location: 0.4),
                        .init(color: color.opacity(0.86), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                LinearGradient(colors: [.clear, .white.opacity(0.12), .clear], startPoint: .leading, endPoint: .trailing)
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
            // 地板：最亮
            Path { path in
                path.move(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: w - inset, y: h - topInset * 0.6))
                path.addLine(to: CGPoint(x: inset, y: h - topInset * 0.6))
                path.closeSubpath()
            }
            .fill(.white.opacity(0.22))
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
    let inset: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let boardHeight: CGFloat = min(max(proxy.size.height * 0.2, 14), 28)
            let tile: CGFloat = min(max((proxy.size.height - boardHeight * 0.6) * 0.98, 30), 150)
            let layout = ShelfLayout(items: spec.items, tile: tile, available: proxy.size.width - inset * 2 + 8)

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
                GlassShelfShape(backInset: inset * 0.8)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.45), theme.shelfEdge.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: boardHeight)
                    .padding(.horizontal, inset * 0.35)
                    .overlay(alignment: .bottom) {
                        // 前沿的灯带
                        Rectangle()
                            .fill(.white)
                            .frame(height: 2.5)
                            .padding(.horizontal, inset * 0.35)
                            .shadow(color: .white.opacity(0.95), radius: 5, y: 3)
                            .shadow(color: .white.opacity(0.7), radius: 16, y: 10)
                    }

                // 食材：站在层板前沿上，大小略有差别，挨得近一点。
                HStack(alignment: .bottom, spacing: -2) {
                    ForEach(layout.visible) { item in
                        ProductView(item: item, size: layout.tile * Self.scale(for: item))
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
                .padding(.horizontal, inset * 0.8)
                .padding(.bottom, boardHeight * 0.3)

                if isRack {
                    // 门架前面的半透明挡条
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [.white.opacity(0.30), .white.opacity(0.12)], startPoint: .top, endPoint: .bottom))
                        .frame(height: 24)
                        .overlay(alignment: .top) {
                            Rectangle().fill(.white.opacity(0.75)).frame(height: 1.5)
                        }
                        .padding(.horizontal, inset * 0.35)
                        .padding(.bottom, boardHeight * 0.28)
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

/// 架子上放得下几样：放不下就先把东西整体缩小一点（最多缩到 58%），还放不下才折成 "+N"。
private struct ShelfLayout {
    let visible: [FoodItem]
    let overflow: Int
    /// 实际使用的尺寸，可能比传进来的小。
    let tile: CGFloat

    init(items: [FoodItem], tile: CGFloat, available: CGFloat) {
        for factor in [1.0, 0.92, 0.84, 0.76, 0.7, 0.64, 0.58] {
            let scaled = tile * factor
            let total = items.reduce(CGFloat(0)) { $0 + ProductView.width(for: $1, size: scaled * 0.93) - 2 }
            if total <= available {
                self.visible = items
                self.overflow = 0
                self.tile = scaled
                return
            }
        }
        let scaled = tile * 0.58
        var used: CGFloat = 0
        var visible: [FoodItem] = []
        for item in items {
            let width = ProductView.width(for: item, size: scaled * 0.93) - 2
            if used + width > available - 36 && !visible.isEmpty { break }
            used += width
            visible.append(item)
        }
        self.visible = visible
        self.overflow = items.count - visible.count
        self.tile = scaled
    }
}

/// 一样食材摆在架子上，底下有一团接触阴影。一样东西只画一个。
struct ProductView: View {
    let item: FoodItem
    let size: CGFloat

    /// 按图片的宽高比占位：瓶子窄，面包宽。没有图的 emoji 按正方形。
    static func width(for item: FoodItem, size: CGFloat) -> CGFloat {
        size * FoodArt.aspect(for: item.name)
    }

    var body: some View {
        let width = Self.width(for: item, size: size)
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(.black.opacity(0.30))
                .frame(width: width * 0.9, height: size * 0.14)
                .blur(radius: 3)
                .offset(y: size * 0.04)
            FoodArtView(item: item, size: size)
        }
        .frame(width: width, height: size, alignment: .bottom)
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
            colors: [.black.opacity(0.3), .black.opacity(0.75), .black.opacity(0.3)],
            startPoint: isVertical ? .leading : .top,
            endPoint: isVertical ? .trailing : .bottom
        )
        .background(Color(red: 0.45, green: 0.03, blue: 0.06))
    }
}

/// 食材图的查找和宽高比，带缓存。
enum FoodArt {
    private static var cache: [String: (image: UIImage?, aspect: CGFloat)] = [:]

    static func image(for name: String) -> UIImage? {
        entry(for: name).image
    }

    /// 宽 / 高，限制在 0.45...1.6 之间；没有图就是 1。
    static func aspect(for name: String) -> CGFloat {
        entry(for: name).aspect
    }

    private static func entry(for name: String) -> (image: UIImage?, aspect: CGFloat) {
        if let cached = cache[name] { return cached }
        var result: (image: UIImage?, aspect: CGFloat) = (nil, 1)
        if let assetName = FoodCatalog.artName(for: name), let uiImage = UIImage(named: assetName) {
            let ratio = uiImage.size.width / max(uiImage.size.height, 1)
            result = (uiImage, min(max(ratio, 0.45), 1.6))
        }
        cache[name] = result
        return result
    }
}

/// 一样食材的图：资源目录里有生成好的图就用图，没有就用 emoji。
struct FoodArtView: View {
    let item: FoodItem
    let size: CGFloat

    var body: some View {
        if let uiImage = FoodArt.image(for: item.name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: size * FoodArt.aspect(for: item.name), height: size)
                .shadow(color: .black.opacity(0.22), radius: 2, y: 2)
        } else {
            Text(item.emoji)
                .font(.system(size: size * 0.84))
                .frame(width: size, height: size)
        }
    }
}
