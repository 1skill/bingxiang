import PhotosUI
import SwiftData
import SwiftUI

/// 冰箱主界面。手机本身就是冰箱门：
///
/// - 合上 iPhone Duo：外屏是一台红色复古冰箱的正面，贴着磁贴和便签。
/// - 展开：内屏以折痕为合页，一边是门的内侧（门架），一边是柜体（层架 + 冷冻区）。
///   灯要开到一定角度才亮；半折时门那一半会虚化。
/// - 没有铰链的设备：点一下门打开，左上角的叉关上。
///
/// 铰链只用来做效果；布局听 `reservedRegions(kind: .division)` 的。
struct FridgeView: View {
    @Binding var selection: AppTab

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Query(filter: #Predicate<FoodItem> { $0.statusRaw == "inStock" }, sort: \FoodItem.expiryDate)
    private var items: [FoodItem]
    @Query(filter: #Predicate<ShoppingItem> { $0.isChecked == false })
    private var shoppingItems: [ShoppingItem]
    @Query(sort: \DoorNote.createdDate)
    private var notes: [DoorNote]
    @Query(sort: \DoorPhoto.createdDate)
    private var photos: [DoorPhoto]

    @AppStorage(SettingsKeys.fridgeExperience) private var fridgeExperience = true
    @AppStorage(SettingsKeys.doorAjarSeconds) private var doorAjarSeconds = 90
    @AppStorage(SettingsKeys.fridgeTheme) private var themeID = FridgeTheme.cherryBlossom.id
    @AppStorage(SettingsKeys.doorLetters) private var doorLetters = ""

    @State private var door = DoorController()
    @State private var hingeDegrees: Double?
    @State private var selectedLocation: StorageLocation?
    @State private var isAddPresented = false
    @State private var isQuickAddPresented = false
    @State private var isSettingsPresented = false
    @State private var isColoursPresented = false
    @State private var isNewNotePresented = false
    @State private var editingNote: DoorNote?
    @State private var photoToDelete: DoorPhoto?
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var isLettersPresented = false
    @State private var lettersDraft = ""
    @State private var isAjarWarningShown = false

    private var theme: FridgeTheme { FridgeTheme.named(themeID) }

    /// 有铰链的设备：展开后内屏是 regular 宽度，那就是"门开了"。
    /// 没铰链的：看用户有没有点开门。
    private var showsInterior: Bool {
        guard fridgeExperience else { return true }
        return door.hasHinge ? horizontalSizeClass == .regular : door.isOpen
    }

    /// 门那一半的虚化：全平 0，越折越糊。
    private var doorBlur: CGFloat {
        guard let hingeDegrees, !reduceMotion else { return 0 }
        let amount = min(max((168 - hingeDegrees) / 80, 0), 1)
        return CGFloat(amount) * 9
    }

    var body: some View {
        ZStack {
            (showsInterior ? Color.black : theme.exterior.opacity(0.85))
                .ignoresSafeArea()

            if showsInterior {
                InteriorView(theme: theme, items: items, isLightOn: door.isLightOn || !fridgeExperience, doorBlur: doorBlur) { location in
                    selectedLocation = location
                }
                .transition(.opacity)
            } else {
                DoorView(
                    theme: theme,
                    items: items,
                    shoppingItems: shoppingItems,
                    notes: notes,
                    photos: photos,
                    door: door,
                    onTapNote: { editingNote = $0 },
                    onTapPhoto: { photoToDelete = $0 },
                    pickedPhoto: $pickedPhoto
                )
                .ignoresSafeArea(edges: [.top, .bottom])
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showsInterior)
        .overlay(alignment: .bottomTrailing) {
            moreMenu
                .padding(18)
        }
        .overlay(alignment: .topLeading) {
            if showsInterior && !door.hasHinge && fridgeExperience {
                Button("关门", systemImage: "xmark") {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        door.setManually(open: false)
                    }
                }
                .labelStyle(.iconOnly)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.black.opacity(0.45), in: .circle)
                .padding(16)
            }
        }
        .overlay(alignment: .top) {
            if isAjarWarningShown {
                ajarWarning
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(item: $selectedLocation) { location in
            ShelfSheet(location: location, items: items)
        }
        .sheet(isPresented: $isAddPresented) {
            ItemFormView(mode: .add(location: nil))
        }
        .sheet(isPresented: $isQuickAddPresented) {
            QuickAddView(defaultLocation: nil)
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView()
        }
        .sheet(isPresented: $isColoursPresented) {
            ColourPickerView()
        }
        .sheet(isPresented: $isNewNotePresented) {
            DoorNoteEditor(note: nil)
        }
        .sheet(item: $editingNote) { note in
            DoorNoteEditor(note: note)
        }
        .confirmationDialog("撕掉这张照片？", isPresented: Binding(
            get: { photoToDelete != nil },
            set: { if !$0 { photoToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("撕掉", role: .destructive) {
                if let photoToDelete {
                    modelContext.delete(photoToDelete)
                }
                photoToDelete = nil
            }
        }
        .alert("字母拼字", isPresented: $isLettersPresented) {
            TextField("最多 8 个字", text: $lettersDraft)
            Button("贴上") {
                doorLetters = String(lettersDraft.trimmingCharacters(in: .whitespaces).prefix(8))
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("用五颜六色的字母磁贴在门上拼一个词，贴上以后可以拖。清空就是拿掉。")
        }
        .onChange(of: pickedPhoto) { _, item in
            guard let item else { return }
            Task {
                if let data = await DoorPhotoImporter.imageData(from: item) {
                    modelContext.insert(DoorPhoto(imageData: data))
                }
                pickedPhoto = nil
            }
        }
        // 👇 铰链 API：角度喂给 DoorController，由它决定灯亮不亮、门算不算开了。
        .onHingeChange { _, newContext in
            hingeDegrees = newContext.hinge?.angle.degrees
            guard fridgeExperience else { return }
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .smooth(duration: 0.3)) {
                door.apply(hingeDegrees: newContext.hinge?.angle.degrees)
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

    // MARK: "…" 菜单

    private var moreMenu: some View {
        Menu {
            Section("食材") {
                Button("快速添加常见食材", systemImage: "square.grid.2x2") { isQuickAddPresented = true }
                Button("手动添加", systemImage: "square.and.pencil") { isAddPresented = true }
            }
            Section("冰箱门") {
                Button("贴一张便签", systemImage: "note.text.badge.plus") { isNewNotePresented = true }
                Button("字母拼字", systemImage: "textformat.abc") {
                    lettersDraft = doorLetters
                    isLettersPresented = true
                }
                Button("颜色", systemImage: "paintpalette") { isColoursPresented = true }
            }
            Section("更多") {
                Button("清单", systemImage: "list.bullet.clipboard") { selection = .inventory }
                Button("购物", systemImage: "cart") { selection = .shopping }
                Button("菜谱", systemImage: "frying.pan") { selection = .recipes }
                Button("统计", systemImage: "chart.bar") { selection = .stats }
                Button("设置", systemImage: "gearshape") { isSettingsPresented = true }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(theme.isDark ? .white : .black.opacity(0.7))
                .frame(width: 46, height: 46)
                .background(theme.menuTint.opacity(0.9), in: .circle)
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
        }
        .accessibilityLabel("更多")
    }

    private var ajarWarning: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("门没关好")
                    .font(.subheadline.weight(.semibold))
                Text(door.hasHinge ? "合上手机把门关好，冷气都跑了。" : "点左上角的叉把门关上。")
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

/// 点某一层弹出来的清单。有自己的选中状态，切换层架不会把 sheet 关掉。
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
    @Previewable @State var selection: AppTab = .fridge
    FridgeView(selection: $selection)
        .modelContainer(for: [FoodItem.self, ShoppingItem.self, DoorNote.self, DoorPhoto.self], inMemory: true)
}
