import SwiftUI

/// 一台冰箱：内部在底下，门盖在上面。门随着 `DoorController.openProgress` 绕左侧铰链转开。
struct FridgeStage: View {
    let items: [FoodItem]
    let notes: [DoorNote]
    let shoppingCount: Int
    let door: DoorController
    @Binding var selectedLocation: StorageLocation?
    let onAddNote: () -> Void
    let onTapNote: (DoorNote) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let cabinet = cabinetSize(in: proxy.size)
            ZStack {
                InteriorView(
                    items: items,
                    isLightOn: door.isLightOn,
                    selectedLocation: $selectedLocation
                )
                .accessibilityHidden(!door.isOpen)

                DoorView(
                    items: items,
                    notes: notes,
                    shoppingCount: shoppingCount,
                    door: door,
                    onAddNote: onAddNote,
                    onTapNote: onTapNote
                )
                .modifier(DoorSwing(progress: door.openProgress, reduceMotion: reduceMotion))
                .allowsHitTesting(door.openProgress < 0.3)
                .accessibilityHidden(door.isOpen)
            }
            .frame(width: cabinet.width, height: cabinet.height)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .padding(16)
    }

    /// 冰箱的长宽比别太离谱：竖着最窄 0.62，横着最宽 1.3，其余撑满可用空间。
    private func cabinetSize(in available: CGSize) -> CGSize {
        guard available.width > 0, available.height > 0 else { return .zero }
        let ratio = min(max(available.width / available.height, 0.62), 1.3)
        var width = available.width
        var height = width / ratio
        if height > available.height {
            height = available.height
            width = height * ratio
        }
        return CGSize(width: width, height: height)
    }
}

/// 门绕着左边转开。开了 Reduce Motion 就只做淡出。
private struct DoorSwing: ViewModifier {
    let progress: Double
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        if reduceMotion {
            content
                .opacity(1 - progress)
        } else {
            content
                .shadow(color: .black.opacity(0.35 * (1 - progress)), radius: 18, x: 12 * progress, y: 6)
                .rotation3DEffect(
                    .degrees(-105 * progress),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .leading,
                    anchorZ: 0,
                    perspective: 0.45
                )
                .opacity(progress < 0.82 ? 1 : max(0, 1 - (progress - 0.82) / 0.18))
        }
    }
}
