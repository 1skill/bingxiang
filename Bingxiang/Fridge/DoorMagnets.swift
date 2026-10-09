import PhotosUI
import SwiftData
import SwiftUI

// 贴在冰箱门上的各种东西：便签、拍立得、字母磁贴、相机磁贴，以及让它们能拖动的修饰器。

// MARK: - 拖动

/// 把一个视图放在门上的某个比例位置，并且可以拖着挪。
struct DraggableOnDoor: ViewModifier {
    @Binding var posX: Double
    @Binding var posY: Double
    let bounds: CGSize

    @State private var dragOffset: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .position(
                x: bounds.width * posX + dragOffset.width,
                y: bounds.height * posY + dragOffset.height
            )
            .gesture(
                DragGesture(minimumDistance: 6)
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        let x = (bounds.width * posX + value.translation.width) / bounds.width
                        let y = (bounds.height * posY + value.translation.height) / bounds.height
                        posX = min(max(x, 0.10), 0.90)
                        posY = min(max(y, 0.08), 0.94)
                        dragOffset = .zero
                    }
            )
    }
}

extension View {
    func draggableOnDoor(posX: Binding<Double>, posY: Binding<Double>, bounds: CGSize) -> some View {
        modifier(DraggableOnDoor(posX: posX, posY: posY, bounds: bounds))
    }
}

// MARK: - 便签

/// 贴在门上的便签：顶上一颗磁钉，几行手写体的字。
struct StickyNoteView: View {
    static let yellow = Color(red: 1.0, green: 0.93, blue: 0.45)
    static let sky = Color(red: 0.70, green: 0.88, blue: 1.0)
    static let pink = Color(red: 1.0, green: 0.76, blue: 0.84)

    let color: Color
    let title: String?
    let lines: [String]
    let pin: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let title {
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .padding(.bottom, 1)
            }
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(.black.opacity(0.78))
        .padding(.horizontal, 9)
        .padding(.top, 11)
        .padding(.bottom, 9)
        .frame(width: 112, alignment: .topLeading)
        .background(color, in: .rect(cornerRadius: 3))
        .overlay(alignment: .top) {
            Circle()
                .fill(pin.gradient)
                .frame(width: 9, height: 9)
                .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                .offset(y: -3)
        }
        .shadow(color: .black.opacity(0.3), radius: 3, y: 3)
    }
}

/// 用户贴的便签，拖到哪儿就记在哪儿。
struct DraggableNote: View {
    @Bindable var note: DoorNote
    let bounds: CGSize
    let onTap: () -> Void

    var body: some View {
        StickyNoteView(color: note.color, title: nil, lines: noteLines, pin: .red)
            .rotationEffect(.degrees(note.rotation))
            .onTapGesture(perform: onTap)
            .draggableOnDoor(posX: $note.posX, posY: $note.posY, bounds: bounds)
            .accessibilityLabel("便签：\(note.text)")
    }

    private var noteLines: [String] {
        let parts = note.text.split(separator: "\n").map(String.init)
        return parts.isEmpty ? [note.text] : Array(parts.prefix(3))
    }
}

// MARK: - 拍立得

/// 一张拍立得：白边，下面宽一点，一颗磁钉。
struct PolaroidView: View {
    let imageData: Data

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.gray
                }
            }
            .frame(width: 78, height: 78)
            .clipped()
            .padding(5)
            Spacer(minLength: 0)
        }
        .frame(width: 88, height: 106)
        .background(Color(white: 0.98), in: .rect(cornerRadius: 2))
        .overlay(alignment: .top) {
            Circle()
                .fill(Color.red.gradient)
                .frame(width: 10, height: 10)
                .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                .offset(y: -4)
        }
        .shadow(color: .black.opacity(0.35), radius: 4, y: 3)
    }
}

/// 手写的涂鸦便签：便签纸上一张透明的笔迹图。
struct DrawnNoteView: View {
    let imageData: Data
    let paperColor: String

    var body: some View {
        Group {
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
        .frame(width: 96, height: 96)
        .background(DoorNote.color(named: paperColor), in: .rect(cornerRadius: 3))
        .overlay(alignment: .top) {
            Circle()
                .fill(Color.red.gradient)
                .frame(width: 9, height: 9)
                .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                .offset(y: -3)
        }
        .shadow(color: .black.opacity(0.3), radius: 3, y: 3)
    }
}

/// 马克笔磁贴：点一下写字画画。
struct PenMagnet: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 1.0, green: 0.55, blue: 0.15).gradient)
                    .frame(width: 9, height: 12)
                Capsule()
                    .fill(LinearGradient(colors: [Color(red: 0.25, green: 0.45, blue: 0.95), Color(red: 0.10, green: 0.25, blue: 0.70)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 8, height: 44)
            }
            .rotationEffect(.degrees(8))
            .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("手写便签")
    }
}

struct DraggablePhoto: View {
    @Bindable var photo: DoorPhoto
    let bounds: CGSize
    let onTap: () -> Void

    var body: some View {
        Group {
            if photo.isDrawing {
                DrawnNoteView(imageData: photo.imageData, paperColor: photo.paperColor)
            } else {
                PolaroidView(imageData: photo.imageData)
            }
        }
            .rotationEffect(.degrees(photo.rotation))
            .onTapGesture(perform: onTap)
            .draggableOnDoor(posX: $photo.posX, posY: $photo.posY, bounds: bounds)
            .accessibilityLabel(photo.isDrawing ? "手写便签" : "拍立得照片")
    }
}

/// 相机磁贴：点一下选照片贴上去。
struct CameraMagnet: View {
    @Binding var selection: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selection, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [Color(white: 0.25), Color(white: 0.08)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 40, height: 28)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(white: 0.75))
                    .frame(width: 10, height: 5)
                    .offset(x: -11, y: -9)
                Circle()
                    .fill(RadialGradient(colors: [Color(white: 0.6), Color(white: 0.1)], center: .center, startRadius: 1, endRadius: 9))
                    .frame(width: 16, height: 16)
                    .overlay {
                        Circle().strokeBorder(Color(white: 0.8), lineWidth: 1.5)
                    }
                    .offset(x: 3)
            }
            .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("贴一张照片")
    }
}

/// 把选中的照片缩小后存成 JPEG，门上贴不下大图。
enum DoorPhotoImporter {
    static func imageData(from item: PhotosPickerItem) async -> Data? {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return nil }
        let side: CGFloat = 480
        let scale = side / max(image.size.width, image.size.height, 1)
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let thumbnail = await image.byPreparingThumbnail(ofSize: target) ?? image
        return thumbnail.jpegData(compressionQuality: 0.82)
    }
}

// MARK: - 字母磁贴

/// 一排五颜六色的字母磁贴，拼出一个词。
struct LetterMagnetsView: View {
    let text: String

    private static let colors: [Color] = [
        Color(red: 0.95, green: 0.25, blue: 0.30),
        Color(red: 0.20, green: 0.55, blue: 0.95),
        Color(red: 1.0, green: 0.78, blue: 0.12),
        Color(red: 0.22, green: 0.75, blue: 0.40),
        Color(red: 0.95, green: 0.50, blue: 0.15),
        Color(red: 0.60, green: 0.40, blue: 0.90),
    ]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character).uppercased())
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 30)
                    .background(Self.colors[index % Self.colors.count].gradient, in: .rect(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.35), radius: 2, y: 2)
                    .rotationEffect(.degrees(Double((index * 7) % 11) - 5))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("字母磁贴：\(text)")
    }
}
