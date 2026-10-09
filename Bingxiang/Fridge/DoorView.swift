import PhotosUI
import SwiftData
import SwiftUI

/// 合上手机时看到的冰箱门：上冷藏下冷冻两扇门、两根铬把手、DUO 字母、圆点磁贴和便签。
/// 整块屏幕就是冰箱的正面。
struct DoorView: View {
    let theme: FridgeTheme
    let items: [FoodItem]
    let shoppingItems: [ShoppingItem]
    let notes: [DoorNote]
    let photos: [DoorPhoto]
    let door: DoorController
    let onTapNote: (DoorNote) -> Void
    let onTapPhoto: (DoorPhoto) -> Void
    let onTapPen: () -> Void
    @Binding var pickedPhoto: PhotosPickerItem?

    @AppStorage(SettingsKeys.doorLetters) private var doorLetters = ""
    @AppStorage(SettingsKeys.doorLettersX) private var doorLettersX = 0.42
    @AppStorage(SettingsKeys.doorLettersY) private var doorLettersY = 0.62

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let seamY = height * FridgeMetrics.fridgeFraction
            let fridgeDoor = CGRect(x: 0, y: 0, width: width, height: seamY - 5)
            let freezerDoor = CGRect(x: 0, y: seamY + 5, width: width, height: height - seamY - 5)

            ZStack(alignment: .topLeading) {
                DoorPanel(theme: theme)
                    .frame(width: fridgeDoor.width, height: fridgeDoor.height)
                DoorPanel(theme: theme)
                    .frame(width: freezerDoor.width, height: freezerDoor.height)
                    .offset(y: freezerDoor.minY)

                // 把手
                Handle()
                    .frame(width: 11, height: fridgeDoor.height * 0.40)
                    .position(x: width - 26, y: fridgeDoor.midY + fridgeDoor.height * 0.12)
                Handle()
                    .frame(width: 11, height: freezerDoor.height * 0.42)
                    .position(x: width - 26, y: freezerDoor.minY + freezerDoor.height * 0.36)

                // DUO 字母和装饰磁贴
                ChromeLetters(text: "DUO")
                    .position(x: width * 0.50, y: fridgeDoor.height * 0.33)
                DotMagnet(color: Color(red: 1.0, green: 0.80, blue: 0.10))
                    .position(x: width * 0.50, y: fridgeDoor.height * 0.20)
                DotMagnet(color: Color(red: 0.20, green: 0.55, blue: 1.0))
                    .position(x: width * 0.78, y: fridgeDoor.height * 0.60)
                DotMagnet(color: Color(red: 0.20, green: 0.80, blue: 0.35))
                    .position(x: width * 0.16, y: fridgeDoor.height * 0.90)
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(theme.isDark ? .white.opacity(0.35) : .pink.opacity(0.6))
                    .position(x: width * 0.18, y: fridgeDoor.height * 0.22)

                // 系统便签：快过期、要买、今天开门
                StickyNoteView(color: StickyNoteView.yellow, title: "快过期", lines: expiringLines, pin: .red)
                    .rotationEffect(.degrees(-3))
                    .position(x: width * 0.30, y: fridgeDoor.height * 0.50)
                StickyNoteView(color: StickyNoteView.sky, title: "要买", lines: shoppingLines, pin: .orange)
                    .rotationEffect(.degrees(2))
                    .position(x: width * 0.80, y: fridgeDoor.height * 0.24)
                StickyNoteView(color: StickyNoteView.pink, title: nil, lines: freezerLines, pin: .pink)
                    .rotationEffect(.degrees(-2))
                    .position(x: width * 0.70, y: freezerDoor.minY + freezerDoor.height * 0.62)

                // 相机磁贴：点一下贴照片
                CameraMagnet(selection: $pickedPhoto)
                    .position(x: width * 0.60, y: fridgeDoor.height * 0.47)
                PenMagnet(action: onTapPen)
                    .position(x: width * 0.73, y: fridgeDoor.height * 0.47)

                // 用户贴的东西，都可以拖
                if !doorLetters.isEmpty {
                    LetterMagnetsView(text: doorLetters)
                        .draggableOnDoor(posX: $doorLettersX, posY: $doorLettersY, bounds: fridgeDoor.size)
                }
                ForEach(photos) { photo in
                    DraggablePhoto(photo: photo, bounds: fridgeDoor.size) {
                        onTapPhoto(photo)
                    }
                }
                ForEach(notes) { note in
                    DraggableNote(note: note, bounds: fridgeDoor.size) {
                        onTapNote(note)
                    }
                }
            }
            .contentShape(.rect)
            .onTapGesture {
                guard !door.hasHinge else { return }
                withAnimation(.easeInOut(duration: 0.45)) {
                    door.setManually(open: true)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("冰箱门")
        .accessibilityHint(door.hasHinge ? "展开手机打开冰箱" : "双击打开冰箱")
    }

    // MARK: 便签内容

    private var expiringLines: [String] {
        let expiring = items.filter { $0.freshness != .fresh }
        guard !expiring.isEmpty else { return ["都很新鲜 🌿"] }
        var lines = expiring.prefix(4).map { "\($0.emoji) \($0.name)" }
        if expiring.count > 4 {
            lines.append("…还有 \(expiring.count - 4) 样")
        }
        return lines
    }

    private var shoppingLines: [String] {
        guard !shoppingItems.isEmpty else { return ["清单是空的"] }
        var lines = shoppingItems.prefix(3).map { "\($0.emoji) \($0.name)" }
        if shoppingItems.count > 3 {
            lines.append("…等 \(shoppingItems.count) 样")
        }
        return lines
    }

    private var freezerLines: [String] {
        [
            "今天开了 \(door.todayOpenCount) 次门",
            door.hasHinge ? "展开手机 → 开门" : "点一下门 → 开门",
        ]
    }
}

// MARK: - 零件

/// 一扇有光泽的门板。
private struct DoorPanel: View {
    let theme: FridgeTheme

    var body: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [theme.exteriorHighlight, theme.exterior, theme.exterior.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                // 左上角一团柔光，像灯打在烤漆上。
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(theme.isDark ? 0.22 : 0.5), .clear],
                            center: UnitPoint(x: 0.25, y: 0.1),
                            startRadius: 0,
                            endRadius: 420
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.45), .clear, .black.opacity(0.25)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: .black.opacity(0.35), radius: 6, y: 4)
    }
}

/// 竖着的铬把手。
private struct Handle: View {
    var body: some View {
        Capsule()
            .fill(FridgeMetrics.chrome)
            .overlay {
                Capsule().strokeBorder(.black.opacity(0.2), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.4), radius: 4, x: -2, y: 3)
    }
}

/// 金属字母。
private struct ChromeLetters: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 20, weight: .heavy, design: .rounded))
            .tracking(7)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(white: 0.98), Color(white: 0.70), Color(white: 0.95), Color(white: 0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .black.opacity(0.4), radius: 1, y: 1.5)
    }
}

/// 圆点磁贴。
private struct DotMagnet: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.7), color, color.opacity(0.85)],
                    center: UnitPoint(x: 0.35, y: 0.3),
                    startRadius: 0,
                    endRadius: 14
                )
            )
            .overlay {
                Circle()
                    .fill(.white.opacity(0.55))
                    .frame(width: 6, height: 6)
                    .offset(x: -3, y: -3)
            }
            .frame(width: 18, height: 18)
            .shadow(color: .black.opacity(0.35), radius: 2, y: 2)
    }
}
