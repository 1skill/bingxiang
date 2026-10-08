import SwiftData
import SwiftUI

/// 冰箱主界面。
///
/// - 合上 iPhone Duo：外屏显示冰箱门，门上贴着磁贴和便签。
/// - 慢慢展开：铰链角度驱动门打开，先是漆黑的内部，开到一定角度灯"咔"地亮起。
/// - 完全展开：看到所有层架和抽屉。半折成桌面模式时，上半屏是冰箱，下半屏是清单。
///
/// 铰链只用来做效果和交互；布局听 `reservedRegions(kind: .division)` 的。
/// 没有铰链的设备（普通 iPhone、iPad）点把手开关门。
struct FridgeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Query(filter: #Predicate<FoodItem> { $0.statusRaw == "inStock" }, sort: \FoodItem.expiryDate)
    private var items: [FoodItem]
    @Query(filter: #Predicate<ShoppingItem> { $0.isChecked == false })
    private var shoppingItems: [ShoppingItem]
    @Query(sort: \DoorNote.createdDate)
    private var notes: [DoorNote]

    @AppStorage(SettingsKeys.fridgeExperience) private var fridgeExperience = true
    @AppStorage(SettingsKeys.doorAjarSeconds) private var doorAjarSeconds = 90

    @State private var door = DoorController()
    @State private var selectedLocation: StorageLocation?
    @State private var isAddPresented = false
    @State private var isQuickAddPresented = false
    @State private var isSettingsPresented = false
    @State private var editingNote: DoorNote?
    @State private var isNewNotePresented = false
    @State private var isAjarWarningShown = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                // 👇 只取"活跃"的分割区域：设备半折时才有，平放和合上时没有。
                let fold = proxy.reservedRegions(kind: .division).first?.frame
                layout(fold: fold, size: proxy.size)
                    .animation(.smooth, value: fold)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("冰箱")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("设置", systemImage: "gearshape") {
                        isSettingsPresented = true
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu("添加", systemImage: "plus") {
                        Button("快速添加常见食材", systemImage: "square.grid.2x2") {
                            isQuickAddPresented = true
                        }
                        Button("手动添加", systemImage: "square.and.pencil") {
                            isAddPresented = true
                        }
                        Button("贴一张便签", systemImage: "note.text.badge.plus") {
                            isNewNotePresented = true
                        }
                    }
                }
            }
            .sheet(isPresented: $isAddPresented) {
                ItemFormView(mode: .add(location: selectedLocation))
            }
            .sheet(isPresented: $isQuickAddPresented) {
                QuickAddView(defaultLocation: selectedLocation)
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
            .sheet(isPresented: $isNewNotePresented) {
                DoorNoteEditor(note: nil)
            }
            .sheet(item: $editingNote) { note in
                DoorNoteEditor(note: note)
            }
        }
        // 👇 铰链 API：角度喂给 DoorController，由它决定门开多少、灯亮不亮。
        .onHingeChange { _, newContext in
            guard fridgeExperience else { return }
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .smooth(duration: 0.35)) {
                door.apply(hingeDegrees: newContext.hinge?.angle.degrees)
            }
        }
        .onChange(of: fridgeExperience, initial: true) { _, isEnabled in
            if !isEnabled {
                door.setManually(open: true)
            }
        }
        .onChange(of: door.isLightOn) { _, isOn in
            if isOn {
                SoundPlayer.play(.light)
            }
        }
        .onChange(of: door.isOpen) { _, isOpen in
            SoundPlayer.play(.latch)
            if !isOpen {
                isAjarWarningShown = false
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: door.isLightOn) { _, isOn in isOn }
        .sensoryFeedback(.impact(weight: .light), trigger: door.isOpen)
        .task(id: door.openedAt) {
            await watchDoorAjar()
        }
    }

    // MARK: 布局

    @ViewBuilder
    private func layout(fold: CGRect?, size: CGSize) -> some View {
        if let fold, fold.width > fold.height {
            // 桌面模式：冰箱立在上半屏，清单放在下半屏，手指够得着。
            VStack(spacing: 0) {
                stage
                    .frame(height: max(fold.minY, 0))
                Color.clear
                    .frame(height: fold.height)
                panel
                    .frame(height: max(size.height - fold.maxY, 0))
            }
        } else if let fold {
            // 书本模式：左边冰箱，右边清单。
            HStack(spacing: 0) {
                stage
                    .frame(width: max(fold.minX, 0))
                Color.clear
                    .frame(width: fold.width)
                panel
                    .frame(width: max(size.width - fold.maxX, 0))
            }
        } else if horizontalSizeClass == .regular || size.width > size.height {
            // 完全展开或 iPad：并排。
            HStack(spacing: 0) {
                stage
                    .frame(width: size.width * 0.52)
                Divider()
                panel
            }
        } else {
            // 外屏或普通 iPhone：只放冰箱，点层架弹出清单。
            stage
                .sheet(item: $selectedLocation) { location in
                    ShelfSheet(location: location, items: items)
                }
        }
    }

    private var stage: some View {
        FridgeStage(
            items: items,
            notes: notes,
            shoppingCount: shoppingItems.count,
            door: door,
            selectedLocation: $selectedLocation,
            onAddNote: { isNewNotePresented = true },
            onTapNote: { editingNote = $0 }
        )
        .overlay(alignment: .top) {
            if isAjarWarningShown {
                ajarWarning
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var panel: some View {
        ShelfPanel(items: items, selectedLocation: $selectedLocation) {
            isAddPresented = true
        }
    }

    private var ajarWarning: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("门没关好")
                    .font(.subheadline.weight(.semibold))
                Text(door.hasHinge ? "合上手机把门关好，冷气都跑了。" : "点一下把手把门关上。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button("知道了") {
                withAnimation { isAjarWarningShown = false }
            }
            .font(.caption.weight(.semibold))
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
        .padding(12)
        .frame(maxWidth: 420)
        .glassEffect(in: .rect(cornerRadius: 18))
        .padding(.horizontal)
    }

    // MARK: 门没关提醒

    private func watchDoorAjar() async {
        guard door.openedAt != nil, doorAjarSeconds > 0 else { return }
        try? await Task.sleep(for: .seconds(doorAjarSeconds))
        guard !Task.isCancelled, door.isOpen else { return }
        withAnimation(.snappy) {
            isAjarWarningShown = true
        }
        SoundPlayer.play(.drop)
    }
}

/// 外屏 / 普通 iPhone 上点层架弹出来的清单。有自己的选中状态，切换时不会把 sheet 关掉。
private struct ShelfSheet: View {
    let items: [FoodItem]
    @State private var selectedLocation: StorageLocation?
    @State private var isAddPresented = false

    init(location: StorageLocation, items: [FoodItem]) {
        self.items = items
        _selectedLocation = State(initialValue: location)
    }

    var body: some View {
        NavigationStack {
            ShelfPanel(items: items, selectedLocation: $selectedLocation) {
                isAddPresented = true
            }
            .navigationTitle(selectedLocation?.rawValue ?? "全部")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isAddPresented) {
                ItemFormView(mode: .add(location: selectedLocation))
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    FridgeView()
        .modelContainer(for: [FoodItem.self, ShoppingItem.self, DoorNote.self], inMemory: true)
}
