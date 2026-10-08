import SwiftUI

/// 冰箱门的外面：不锈钢面板、两个把手、一堆磁贴和便签。
struct DoorView: View {
    let items: [FoodItem]
    let notes: [DoorNote]
    let shoppingCount: Int
    let door: DoorController
    let onAddNote: () -> Void
    let onTapNote: (DoorNote) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var expiringCount: Int {
        items.filter { $0.freshness != .fresh }.count
    }

    private var expiredCount: Int {
        items.filter { $0.freshness == .expired }.count
    }

    var body: some View {
        GeometryReader { proxy in
            let freezerHeight = proxy.size.height * FridgeMetrics.freezerFraction
            VStack(spacing: 0) {
                freezerDoor
                    .frame(height: freezerHeight)
                seam
                fridgeDoor
            }
            .background(FridgeMetrics.doorSteel(colorScheme))
            .overlay(alignment: .trailing) {
                handles(freezerHeight: freezerHeight, totalHeight: proxy.size.height)
            }
            .clipShape(.rect(cornerRadius: FridgeMetrics.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: FridgeMetrics.cornerRadius)
                    .strokeBorder(.white.opacity(colorScheme == .dark ? 0.12 : 0.6), lineWidth: 1.5)
            }
        }
        .contentShape(.rect)
        .onTapGesture {
            guard !door.hasHinge else { return }
            withAnimation(.smooth(duration: 0.6)) {
                door.toggleManually()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("冰箱门")
        .accessibilityHint(door.hasHinge ? "展开手机打开冰箱" : "双击打开冰箱")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: 冷冻室门

    private var freezerDoor: some View {
        HStack(alignment: .top) {
            Magnet(color: .indigo) {
                Label("今天开了 \(door.todayOpenCount) 次", systemImage: "door.left.hand.open")
            }
            .rotationEffect(.degrees(-3))
            Spacer()
            Text("冰箱 · Duo")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.trailing, 36)
        }
        .padding(18)
    }

    private var seam: some View {
        Rectangle()
            .fill(.black.opacity(colorScheme == .dark ? 0.5 : 0.18))
            .frame(height: 3)
    }

    // MARK: 冷藏室门

    private var fridgeDoor: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Magnet(color: expiredCount > 0 ? .red : (expiringCount > 0 ? .orange : .green)) {
                    if expiringCount == 0 {
                        Label("都很新鲜", systemImage: "leaf.fill")
                    } else {
                        Label("\(expiringCount) 样快过期", systemImage: "flame.fill")
                    }
                }
                .rotationEffect(.degrees(2))

                Magnet(color: .teal) {
                    Label("购物清单 \(shoppingCount)", systemImage: "cart.fill")
                }
                .rotationEffect(.degrees(-2))
            }

            FlowingNotes(notes: notes, onTap: onTapNote, onAdd: onAddNote)

            Spacer(minLength: 0)

            hint
        }
        .padding(18)
        .padding(.trailing, 28)
    }

    private var hint: some View {
        HStack(spacing: 6) {
            Image(systemName: door.hasHinge ? "iphone.gen3.motion" : "hand.tap")
            Text(door.hasHinge ? "慢慢展开手机，打开冰箱" : "点一下把手，打开冰箱")
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
    }

    // MARK: 把手

    private func handles(freezerHeight: CGFloat, totalHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(handleStyle)
                .frame(width: 10, height: max(freezerHeight * 0.55, 24))
                .frame(height: freezerHeight)
            Capsule()
                .fill(handleStyle)
                .frame(width: 10, height: max((totalHeight - freezerHeight) * 0.5, 40))
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 28)
        }
        .padding(.trailing, 14)
        .shadow(color: .black.opacity(0.25), radius: 3, x: -2, y: 2)
    }

    private var handleStyle: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(white: 0.55), Color(white: 0.35)]
                : [Color(white: 0.75), Color(white: 0.55)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

/// 圆角的小磁贴。
struct Magnet<Content: View>: View {
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        content
            .font(.caption.weight(.bold))
            .labelStyle(.titleAndIcon)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color.gradient, in: .rect(cornerRadius: 10))
            .shadow(color: .black.opacity(0.18), radius: 3, y: 2)
    }
}

/// 便签们。横着排，排不下就换行。
private struct FlowingNotes: View {
    let notes: [DoorNote]
    let onTap: (DoorNote) -> Void
    let onAdd: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 110, maximum: 160), spacing: 12, alignment: .top)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            ForEach(notes) { note in
                StickyNote(note: note)
                    .onTapGesture { onTap(note) }
            }
            Button(action: onAdd) {
                Label("便签", systemImage: "plus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
            }
            .buttonStyle(.plain)
        }
    }
}

/// 一张贴在门上的便签，带一颗磁钉。
struct StickyNote: View {
    let note: DoorNote

    var body: some View {
        Text(note.text)
            .font(.system(.footnote, design: .rounded).weight(.medium))
            .foregroundStyle(.black.opacity(0.8))
            .multilineTextAlignment(.leading)
            .lineLimit(3)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
            .padding(10)
            .padding(.top, 6)
            .background(note.color, in: .rect(cornerRadius: 6))
            .overlay(alignment: .top) {
                Circle()
                    .fill(.red.gradient)
                    .frame(width: 10, height: 10)
                    .shadow(radius: 1, y: 1)
                    .offset(y: -4)
            }
            .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
            .rotationEffect(.degrees(note.rotation))
            .accessibilityLabel("便签：\(note.text)")
    }
}
