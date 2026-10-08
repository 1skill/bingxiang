import SwiftData
import SwiftUI

/// 写一张贴在门上的便签。`note` 为 nil 就是新建。
struct DoorNoteEditor: View {
    let note: DoorNote?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var colorName: String

    init(note: DoorNote?) {
        self.note = note
        _text = State(initialValue: note?.text ?? "")
        _colorName = State(initialValue: note?.colorName ?? "yellow")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("内容") {
                    TextField("比如：周末火锅、记得买酱油", text: $text, axis: .vertical)
                        .lineLimit(2...5)
                }
                Section("颜色") {
                    HStack(spacing: 14) {
                        ForEach(DoorNote.colorNames, id: \.self) { name in
                            Circle()
                                .fill(DoorNote.color(named: name))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if name == colorName {
                                        Circle().strokeBorder(Color.accentColor, lineWidth: 3)
                                    }
                                }
                                .onTapGesture { colorName = name }
                                .accessibilityLabel(name)
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                    .padding(.vertical, 4)
                }
                if let note {
                    Section {
                        Button("撕掉这张便签", systemImage: "trash", role: .destructive) {
                            modelContext.delete(note)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(note == nil ? "新便签" : "编辑便签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("贴上", systemImage: "checkmark") { save() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let note {
            note.text = trimmed
            note.colorName = colorName
        } else {
            modelContext.insert(DoorNote(text: trimmed, colorName: colorName))
        }
        dismiss()
    }
}
