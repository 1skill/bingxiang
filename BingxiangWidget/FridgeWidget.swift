import SwiftUI
import WidgetKit

// 桌面和锁屏上的冰箱门。数据来自 App 写在 App Group 里的快照。

struct FridgeEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct FridgeProvider: TimelineProvider {
    func placeholder(in context: Context) -> FridgeEntry {
        FridgeEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (FridgeEntry) -> Void) {
        completion(FridgeEntry(date: .now, snapshot: WidgetSnapshot.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FridgeEntry>) -> Void) {
        let entry = FridgeEntry(date: .now, snapshot: WidgetSnapshot.load() ?? .placeholder)
        // 到期天数是按"今天"算的，过了午夜要重算；平时半小时看一眼就够。
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct FridgeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "FridgeDoor", provider: FridgeProvider()) { entry in
            FridgeWidgetView(entry: entry)
        }
        .configurationDisplayName("冰箱门")
        .description("贴着快过期食材和购物清单的冰箱门。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

struct FridgeWidgetView: View {
    let entry: FridgeEntry
    @Environment(\.widgetFamily) private var family

    private var snapshot: WidgetSnapshot { entry.snapshot }
    private var theme: FridgeTheme { FridgeTheme.named(snapshot.themeID) }

    var body: some View {
        switch family {
        case .accessoryCircular:
            circular
        case .accessoryInline:
            Text("\(snapshot.expiring.count) 样快过期 · \(snapshot.shoppingCount) 样要买")
        case .accessoryRectangular:
            rectangular
        default:
            door
        }
    }

    // MARK: 锁屏

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "refrigerator")
                    .font(.system(size: 14))
                Text("\(snapshot.expiring.count)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
        }
        .containerBackground(.clear, for: .widget)
        .accessibilityLabel("\(snapshot.expiring.count) 样食材快过期")
    }

    private var rectangular: some View {
        HStack(spacing: 8) {
            Image(systemName: "refrigerator")
                .font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text(snapshot.expiring.isEmpty ? "冰箱里都很新鲜" : "\(snapshot.expiring.count) 样快过期")
                    .font(.headline)
                Text(snapshot.expiring.isEmpty
                     ? "\(snapshot.inStockCount) 样在库"
                     : snapshot.expiring.prefix(3).map { "\($0.emoji)\($0.name)" }.joined(separator: " "))
                    .font(.caption)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.clear, for: .widget)
    }

    // MARK: 桌面：一扇冰箱门

    private var door: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let isLarge = family == .systemLarge
            let seamY = isLarge ? h * 0.66 : h

            ZStack(alignment: .topLeading) {
                // 门板
                panel
                    .frame(width: w - 8, height: (isLarge ? seamY - 3 : h) - 8)
                    .offset(x: 4, y: 4)
                if isLarge {
                    panel
                        .frame(width: w - 8, height: h - seamY - 7)
                        .offset(x: 4, y: seamY + 3)
                }

                // 把手
                Capsule()
                    .fill(LinearGradient(colors: [Color(white: 0.6), Color(white: 0.95), Color(white: 0.6)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 6, height: (isLarge ? seamY : h) * 0.36)
                    .position(x: w - 14, y: (isLarge ? seamY : h) * 0.56)
                    .shadow(color: .black.opacity(0.35), radius: 2, x: -1, y: 2)

                Text("DUO")
                    .font(.system(size: family == .systemSmall ? 11 : 13, weight: .heavy, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(LinearGradient(colors: [Color(white: 0.98), Color(white: 0.65)], startPoint: .top, endPoint: .bottom))
                    .position(x: w * 0.5, y: 16)

                // 便签
                Group {
                    if family == .systemSmall {
                        sticky(color: Sticky.yellow, title: "快过期", lines: expiringLines(max: 3), pin: .red)
                            .rotationEffect(.degrees(-3))
                            .frame(width: w - 30)
                            .position(x: w * 0.47, y: h * 0.56)
                    } else {
                        sticky(color: Sticky.yellow, title: "快过期", lines: expiringLines(max: isLarge ? 5 : 3), pin: .red)
                            .rotationEffect(.degrees(-3))
                            .frame(width: w * 0.42)
                            .position(x: w * 0.27, y: (isLarge ? seamY : h) * 0.55)
                        sticky(color: Sticky.sky, title: "要买", lines: shoppingLines(max: isLarge ? 4 : 3), pin: .orange)
                            .rotationEffect(.degrees(2))
                            .frame(width: w * 0.40)
                            .position(x: w * 0.68, y: (isLarge ? seamY : h) * 0.50)
                    }
                }

                if isLarge {
                    ForEach(Array(snapshot.noteTexts.prefix(2).enumerated()), id: \.offset) { index, text in
                        sticky(color: index == 0 ? Sticky.mint : Sticky.pink, title: nil, lines: [text], pin: .red)
                            .rotationEffect(.degrees(index == 0 ? -2 : 3))
                            .frame(width: w * 0.38)
                            .position(x: w * (index == 0 ? 0.28 : 0.68), y: seamY + (h - seamY) * 0.55)
                    }
                    Text("今天开了 \(snapshot.openCount) 次门 · \(snapshot.inStockCount) 样在库")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.doorText.opacity(0.8))
                        .position(x: w * 0.5, y: h - 12)
                }

                // 圆点磁贴
                Circle().fill(Color(red: 1.0, green: 0.8, blue: 0.1).gradient).frame(width: 9, height: 9).position(x: w * 0.22, y: 14)
                Circle().fill(Color(red: 0.2, green: 0.55, blue: 1.0).gradient).frame(width: 9, height: 9).position(x: w * 0.82, y: (isLarge ? seamY : h) * 0.86)
            }
        }
        .containerBackground(for: .widget) {
            theme.exterior.opacity(0.85)
        }
    }

    private var panel: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(LinearGradient(colors: [theme.exteriorHighlight, theme.exterior], startPoint: .top, endPoint: .bottom))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.4), .clear, .black.opacity(0.25)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
    }

    private enum Sticky {
        static let yellow = Color(red: 1.0, green: 0.93, blue: 0.45)
        static let sky = Color(red: 0.70, green: 0.88, blue: 1.0)
        static let pink = Color(red: 1.0, green: 0.76, blue: 0.84)
        static let mint = Color(red: 0.78, green: 0.95, blue: 0.86)
    }

    private func sticky(color: Color, title: String?, lines: [String], pin: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let title {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(.black.opacity(0.78))
        .padding(.horizontal, 7)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(color, in: .rect(cornerRadius: 2))
        .overlay(alignment: .top) {
            Circle().fill(pin.gradient).frame(width: 6, height: 6).offset(y: -2)
        }
        .shadow(color: .black.opacity(0.25), radius: 2, y: 2)
    }

    private func expiringLines(max: Int) -> [String] {
        guard !snapshot.expiring.isEmpty else { return ["都很新鲜 🌿"] }
        var lines = snapshot.expiring.prefix(max).map { item in
            let when: String
            switch item.daysLeft {
            case ..<0: when = "过期"
            case 0: when = "今天"
            case 1: when = "明天"
            default: when = "\(item.daysLeft)天"
            }
            return "\(item.emoji) \(item.name) \(when)"
        }
        if snapshot.expiring.count > max {
            lines.append("…还有 \(snapshot.expiring.count - max) 样")
        }
        return lines
    }

    private func shoppingLines(max: Int) -> [String] {
        guard snapshot.shoppingCount > 0 else { return ["清单是空的"] }
        var lines = snapshot.shoppingNames.prefix(max).map { "· \($0)" }
        if snapshot.shoppingCount > max {
            lines.append("…等 \(snapshot.shoppingCount) 样")
        }
        return lines
    }
}

#Preview(as: .systemMedium) {
    FridgeWidget()
} timeline: {
    FridgeEntry(date: .now, snapshot: .placeholder)
}
