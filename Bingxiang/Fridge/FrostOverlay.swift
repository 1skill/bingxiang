import SwiftUI

/// 冷冻室的霜：边缘和角落结一层白霜，上面撒细小的冰晶和亮点，整体偏冷的蓝白调。
/// 画在渲染底图上面、食材下面。
struct FrostOverlay: View {
    /// 霜的浓淡，0...1。
    var intensity: Double = 1

    var body: some View {
        ZStack {
            // 冷调
            LinearGradient(
                colors: [Color(red: 0.78, green: 0.90, blue: 1.0).opacity(0.22 * intensity), Color(red: 0.85, green: 0.93, blue: 1.0).opacity(0.10 * intensity)],
                startPoint: .top,
                endPoint: .bottom
            )
            // 四周的霜
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                ZStack {
                    LinearGradient(colors: [.white.opacity(0.30 * intensity), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: h * 0.22)
                        .frame(maxHeight: .infinity, alignment: .top)
                    LinearGradient(colors: [.white.opacity(0.22 * intensity), .clear], startPoint: .bottom, endPoint: .top)
                        .frame(height: h * 0.14)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    LinearGradient(colors: [.white.opacity(0.26 * intensity), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: w * 0.16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    LinearGradient(colors: [.white.opacity(0.26 * intensity), .clear], startPoint: .trailing, endPoint: .leading)
                        .frame(width: w * 0.16)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    ForEach(0..<4, id: \.self) { corner in
                        RadialGradient(colors: [.white.opacity(0.42 * intensity), .clear], center: .center, startRadius: 0, endRadius: min(w, h) * 0.38)
                            .frame(width: min(w, h) * 0.9, height: min(w, h) * 0.9)
                            .position(x: corner % 2 == 0 ? 0 : w, y: corner < 2 ? 0 : h)
                    }
                }
            }
            // 冰晶
            Canvas { context, size in
                var random = SeededRandom(seed: 7)
                let count = Int(220 * intensity) + 60
                for _ in 0..<count {
                    // 往边上靠：半径用平方根分布，边缘更密。
                    let edgeBias = random.next()
                    let x = random.next() * size.width
                    let y = random.next() * size.height
                    let distanceToEdge = min(x, size.width - x, y, size.height - y) / min(size.width, size.height)
                    // 只在靠边的地方结冰晶，中间留干净。
                    guard distanceToEdge < 0.06 + 0.16 * edgeBias * edgeBias else { continue }
                    let radius = 1.5 + random.next() * 4.5
                    let alpha = (0.18 + random.next() * 0.32) * intensity
                    let center = CGPoint(x: x, y: y)
                    var path = Path()
                    for arm in 0..<3 {
                        let angle = Double(arm) * .pi / 3 + random.next() * 0.3
                        let dx = cos(angle) * radius
                        let dy = sin(angle) * radius
                        path.move(to: CGPoint(x: center.x - dx, y: center.y - dy))
                        path.addLine(to: CGPoint(x: center.x + dx, y: center.y + dy))
                    }
                    context.stroke(path, with: .color(.white.opacity(alpha)), lineWidth: radius > 4 ? 0.9 : 0.6)
                    if radius > 4.5 {
                        // 大一点的冰晶带小分枝
                        var branches = Path()
                        for arm in 0..<6 {
                            let angle = Double(arm) * .pi / 3
                            let tip = CGPoint(x: center.x + cos(angle) * radius * 0.6, y: center.y + sin(angle) * radius * 0.6)
                            for side in [-1.0, 1.0] {
                                let a = angle + side * .pi / 3
                                branches.move(to: tip)
                                branches.addLine(to: CGPoint(x: tip.x + cos(a) * radius * 0.25, y: tip.y + sin(a) * radius * 0.25))
                            }
                        }
                        context.stroke(branches, with: .color(.white.opacity(alpha * 0.8)), lineWidth: 0.7)
                    }
                }
                // 亮点
                for _ in 0..<Int(40 * intensity) {
                    let x = random.next() * size.width
                    let y = random.next() * size.height
                    let r = 0.5 + random.next() * 1.0
                    context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(.white.opacity((0.4 + random.next() * 0.5) * intensity)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// 固定种子的随机数，每次画出来的霜一样。
private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &* 6364136223846793005 &+ 1442695040888963407
    }

    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double((state >> 11) & 0x1FFFFFFFFFFFFF) / Double(0x20000000000000)
    }
}
