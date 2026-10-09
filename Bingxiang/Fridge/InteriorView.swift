import SwiftUI

/// 展开后看到的冰箱内部：底图是渲染好的空冰箱（光照、反射、景深都是真的），
/// 食材按层板位置用代码摆上去。折痕就是冰箱的合页：一边是门的内侧，另一边是柜体。
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
                // 底图是装饰，不是可点的控件，所以直接画过折痕：两半在折痕中线上贴在一起。
                if let fold, fold.height >= fold.width {
                    HStack(spacing: 0) {
                        doorInside
                            .frame(width: max(fold.midX, 0))
                            .blur(radius: doorBlur)
                        cabinet
                            .frame(width: max(size.width - fold.midX, 0))
                    }
                } else if let fold {
                    VStack(spacing: 0) {
                        cabinet
                            .frame(height: max(fold.midY, 0))
                        doorInside
                            .frame(height: max(size.height - fold.midY, 0))
                            .blur(radius: doorBlur)
                    }
                } else if size.width > size.height {
                    HStack(spacing: 0) {
                        doorInside
                            .frame(width: size.width * 0.5)
                        cabinet
                    }
                } else {
                    VStack(spacing: 0) {
                        cabinet
                            .frame(height: size.height * 0.62)
                        doorInside
                    }
                }
            }
            .animation(.smooth, value: fold)
        }
        .overlay {
            Color.black
                .opacity(isLightOn ? 0 : 0.88)
                .animation(.easeOut(duration: 0.2), value: isLightOn)
                .allowsHitTesting(false)
        }
    }

    // MARK: 两半

    private var cabinet: some View {
        RenderedHalf(theme: theme, imageName: "interior-cabinet", slots: InteriorLayout.cabinet, items: cabinetItems, anchorsLeading: true, onSelect: onSelect)
    }

    private var doorInside: some View {
        RenderedHalf(theme: theme, imageName: "interior-door", slots: InteriorLayout.door, items: doorItems, anchorsLeading: false, onSelect: onSelect)
    }

    /// 柜体每一层放什么：上中下层、保鲜抽屉，冷冻的一半。
    private var cabinetItems: [[FoodItem]] {
        let frozen = splitFreezer(keepEven: true)
        return [
            items(at: .upperShelf), items(at: .middleShelf), items(at: .lowerShelf), items(at: .crisper),
            frozen[0], frozen[1],
        ]
    }

    /// 门架每一层放什么：门架的东西轮流放三层，冷冻的另一半放冷冻门架。
    private var doorItems: [[FoodItem]] {
        let door = items(at: .door)
        let frozen = splitFreezer(keepEven: false)
        return [
            door.enumerated().filter { $0.offset % 3 == 0 }.map(\.element),
            door.enumerated().filter { $0.offset % 3 == 1 }.map(\.element),
            door.enumerated().filter { $0.offset % 3 == 2 }.map(\.element),
            frozen[0], frozen[1],
        ]
    }

    private func items(at location: StorageLocation) -> [FoodItem] {
        items.filter { $0.location == location }
    }

    /// 冷冻食材一半放柜体、一半放冷冻门架，每边再分两层。
    private func splitFreezer(keepEven: Bool) -> [[FoodItem]] {
        let frozen = items(at: .freezer).enumerated()
            .filter { ($0.offset % 2 == 0) == keepEven }
            .map(\.element)
        let half = (frozen.count + 1) / 2
        return [Array(frozen.prefix(half)), Array(frozen.dropFirst(half))]
    }
}

/// 渲染图上一层架子的位置，全是相对于图片宽高的比例（量自 1024×1536 的底图）。
struct ShelfSlot {
    let location: StorageLocation
    /// 物品站的那条线。
    let baseline: CGFloat
    /// 这一层的上边界，决定物品最高能多高。
    let top: CGFloat
    let left: CGFloat
    let right: CGFloat
    /// 门架挡条的上沿；有的话物品下半截会罩一层半透明塑料。
    var lipTop: CGFloat? = nil
}

enum InteriorLayout {
    static let imageSize = CGSize(width: 1024, height: 1536)
    /// 冷冻区在底图里的纵向范围，用来铺霜。
    static let freezerZone: ClosedRange<CGFloat> = 0.655...1.0

    static let cabinet: [ShelfSlot] = [
        ShelfSlot(location: .upperShelf, baseline: 0.142, top: 0.015, left: 0.09, right: 0.91),
        ShelfSlot(location: .middleShelf, baseline: 0.279, top: 0.160, left: 0.09, right: 0.91),
        ShelfSlot(location: .lowerShelf, baseline: 0.422, top: 0.300, left: 0.09, right: 0.91),
        ShelfSlot(location: .crisper, baseline: 0.560, top: 0.440, left: 0.09, right: 0.91),
        ShelfSlot(location: .freezer, baseline: 0.815, top: 0.690, left: 0.10, right: 0.90),
        ShelfSlot(location: .freezer, baseline: 0.943, top: 0.830, left: 0.10, right: 0.90),
    ]

    static let door: [ShelfSlot] = [
        ShelfSlot(location: .door, baseline: 0.166, top: 0.020, left: 0.08, right: 0.92, lipTop: 0.078),
        ShelfSlot(location: .door, baseline: 0.386, top: 0.200, left: 0.08, right: 0.92, lipTop: 0.296),
        ShelfSlot(location: .door, baseline: 0.608, top: 0.420, left: 0.08, right: 0.92, lipTop: 0.514),
        ShelfSlot(location: .freezer, baseline: 0.806, top: 0.680, left: 0.10, right: 0.90, lipTop: 0.736),
        ShelfSlot(location: .freezer, baseline: 0.950, top: 0.830, left: 0.10, right: 0.90, lipTop: 0.866),
    ]
}

/// 一半冰箱：渲染底图铺满（居中裁切），食材按比例坐标摆到每层架子上。
private struct RenderedHalf: View {
    let theme: FridgeTheme
    let imageName: String
    let slots: [ShelfSlot]
    let items: [[FoodItem]]
    /// 柜体靠左边（折痕）对齐，门靠右边（折痕）对齐，多出来的那一点宽度留给外侧的箱体。
    let anchorsLeading: Bool
    let onSelect: (StorageLocation) -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let image = InteriorLayout.imageSize
            // 整张底图完整显示，不裁上下。
            let scale = min(size.width / image.width, size.height / image.height)
            let drawn = CGSize(width: image.width * scale, height: image.height * scale)
            let origin = CGPoint(x: anchorsLeading ? 0 : size.width - drawn.width, y: (size.height - drawn.height) / 2)

            ZStack(alignment: .topLeading) {
                // 箱体：底图没盖到的地方。
                LinearGradient(colors: [theme.exterior, theme.exterior.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    .overlay(.black.opacity(0.3))
                    .frame(width: size.width, height: size.height)

                // 和食材图走同一条路：UIImage 再包成 Image，方便以后换成从文件加载。
                Image(uiImage: UIImage(named: imageName) ?? UIImage())
                    .resizable()
                    .interpolation(.high)
                    .frame(width: drawn.width, height: drawn.height)
                    .modifier(ThemeRecolor(theme: theme))
                    .offset(x: origin.x, y: origin.y)

                // 冷冻区的霜，铺在底图上、食材下。
                FrostOverlay()
                    .frame(width: drawn.width, height: (InteriorLayout.freezerZone.upperBound - InteriorLayout.freezerZone.lowerBound) * drawn.height)
                    .offset(x: origin.x, y: origin.y + InteriorLayout.freezerZone.lowerBound * drawn.height)

                ForEach(Array(slots.enumerated()), id: \.offset) { index, slot in
                    let x0 = origin.x + slot.left * drawn.width
                    let width = (slot.right - slot.left) * drawn.width
                    let baseline = origin.y + slot.baseline * drawn.height
                    let cellHeight = (slot.baseline - slot.top) * drawn.height

                    ShelfRow(items: index < items.count ? items[index] : [], width: width, height: cellHeight)
                        .frame(width: width, height: cellHeight, alignment: .bottomLeading)
                        .offset(x: x0, y: baseline - cellHeight)
                        .contentShape(.rect)
                        .onTapGesture { onSelect(slot.location) }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(slot.location.rawValue)，\(index < items.count ? items[index].count : 0) 样食材")
                        .accessibilityAddTraits(.isButton)

                    if let lipTop = slot.lipTop {
                        // 半透明的塑料挡条，物品下半截在它后面。
                        LinearGradient(colors: [.white.opacity(0.30), .white.opacity(0.14)], startPoint: .top, endPoint: .bottom)
                            .frame(width: width, height: (slot.baseline - lipTop) * drawn.height)
                            .offset(x: x0, y: origin.y + lipTop * drawn.height)
                            .allowsHitTesting(false)
                    }
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .clipped()
        }
    }
}

/// 樱花红是底图本来的颜色，不加任何滤镜；其他颜色靠调色相 / 饱和度 / 亮度派生。
/// 滤镜即使参数为零也会改变渲染，所以默认主题干脆不挂。
private struct ThemeRecolor: ViewModifier {
    let theme: FridgeTheme

    func body(content: Content) -> some View {
        if theme.renderHue == .zero && theme.renderSaturation == 1 && theme.renderBrightness == 0 && theme.renderContrast == 1 {
            content
        } else {
            content
                .hueRotation(theme.renderHue)
                .contrast(theme.renderContrast)
                .saturation(theme.renderSaturation)
                .brightness(theme.renderBrightness)
        }
    }
}

/// 一层架子上的一排食材：从左往右摆，放不下先缩小再折成 +N。
private struct ShelfRow: View {
    let items: [FoodItem]
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let layout = ShelfLayout(items: items, cellHeight: height * 0.96, available: width - 8)
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(layout.visible) { item in
                ProductView(item: item, size: ShelfLayout.size(of: item, cellHeight: height * 0.96, factor: layout.factor) * Self.scale(for: item))
            }
            if layout.overflow > 0 {
                Text("+\(layout.overflow)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.25), in: .capsule)
                    .padding(.bottom, 4)
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 4)
    }

    /// 让每样东西大小略有差别，看起来不那么像一排图标。
    private static func scale(for item: FoodItem) -> CGFloat {
        let hash = item.name.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        return 0.92 + CGFloat(hash % 9) / 100
    }
}

/// 架子上放得下几样：每样按自己的相对大小占位，放不下就整体缩小（最多缩到 58%），还放不下才折成 "+N"。
private struct ShelfLayout {
    let visible: [FoodItem]
    let overflow: Int
    /// 整体缩放系数。
    let factor: CGFloat

    static func size(of item: FoodItem, cellHeight: CGFloat, factor: CGFloat) -> CGFloat {
        // 真实比例再放大一点，不然小东西在架子上看不清。
        cellHeight * min(CGFloat(FoodCatalog.relativeSize(for: item.name)) * 1.5, 1.0) * factor
    }

    init(items: [FoodItem], cellHeight: CGFloat, available: CGFloat) {
        for factor in [1.0, 0.92, 0.84, 0.76, 0.7, 0.64, 0.58] as [CGFloat] {
            let total = items.reduce(CGFloat(0)) { $0 + ProductView.width(for: $1, size: Self.size(of: $1, cellHeight: cellHeight, factor: factor)) + 2 }
            if total <= available {
                self.visible = items
                self.overflow = 0
                self.factor = factor
                return
            }
        }
        let factor: CGFloat = 0.58
        var used: CGFloat = 0
        var visible: [FoodItem] = []
        for item in items {
            let width = ProductView.width(for: item, size: Self.size(of: item, cellHeight: cellHeight, factor: factor)) + 2
            if used + width > available - 36 && !visible.isEmpty { break }
            used += width
            visible.append(item)
        }
        self.visible = visible
        self.overflow = items.count - visible.count
        self.factor = factor
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
