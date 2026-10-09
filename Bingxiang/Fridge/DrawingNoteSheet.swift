import PencilKit
import SwiftData
import SwiftUI

/// 用手指或 Apple Pencil 在便签纸上写字、画画，贴到门上。
struct DrawingNoteSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var drawing = PKDrawing()
    @State private var paperColor = "yellow"
    @State private var inkColor: InkColor = .black

    enum InkColor: String, CaseIterable, Identifiable {
        case black, red, blue

        var id: String { rawValue }

        var uiColor: UIColor {
            switch self {
            case .black: .black
            case .red: UIColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1)
            case .blue: UIColor(red: 0.15, green: 0.35, blue: 0.85, alpha: 1)
            }
        }

        var color: Color { Color(uiColor: uiColor) }
    }

    private let canvasSize: CGFloat = 280

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DrawingCanvas(drawing: $drawing, inkColor: inkColor.uiColor)
                    .frame(width: canvasSize, height: canvasSize)
                    .background(DoorNote.color(named: paperColor), in: .rect(cornerRadius: 4))
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 4)
                    .padding(.top, 12)

                HStack(spacing: 14) {
                    ForEach(DoorNote.colorNames, id: \.self) { name in
                        Circle()
                            .fill(DoorNote.color(named: name))
                            .frame(width: 30, height: 30)
                            .overlay {
                                if name == paperColor {
                                    Circle().strokeBorder(Color.accentColor, lineWidth: 3)
                                }
                            }
                            .onTapGesture { paperColor = name }
                            .accessibilityLabel("便签纸 \(name)")
                    }
                }

                HStack(spacing: 16) {
                    ForEach(InkColor.allCases) { ink in
                        Button {
                            inkColor = ink
                        } label: {
                            Image(systemName: "pencil.tip")
                                .font(.title3)
                                .foregroundStyle(ink.color)
                                .frame(width: 40, height: 40)
                                .background(ink == inkColor ? AnyShapeStyle(.fill.secondary) : AnyShapeStyle(.clear), in: .circle)
                        }
                        .accessibilityLabel("\(ink.rawValue) 笔")
                    }
                    Button("清空", systemImage: "eraser", role: .destructive) {
                        drawing = PKDrawing()
                    }
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .frame(width: 40, height: 40)
                }

                Text("用手指或 Apple Pencil 写点什么。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .navigationTitle("手写便签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("贴上", systemImage: "checkmark") { save() }
                        .disabled(drawing.strokes.isEmpty)
                }
            }
        }
    }

    private func save() {
        let rect = CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize)
        let image = drawing.image(from: rect, scale: 2)
        guard let data = image.pngData() else { return }
        modelContext.insert(DoorPhoto(imageData: data, isDrawing: true, paperColor: paperColor))
        dismiss()
    }
}

/// PencilKit 的画布。
private struct DrawingCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let inkColor: UIColor

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.delegate = context.coordinator
        canvas.tool = PKInkingTool(.pen, color: inkColor, width: 4)
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        canvas.tool = PKInkingTool(.pen, color: inkColor, width: 4)
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing

        init(drawing: Binding<PKDrawing>) {
            _drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
        }
    }
}
