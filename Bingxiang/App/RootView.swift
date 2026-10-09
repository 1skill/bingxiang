import SwiftData
import SwiftUI

enum AppTab: String, Hashable {
    case fridge
    case inventory
    case shopping
    case recipes
    case stats
}

/// 五个标签页。冰箱那一页是全屏的，没有标签栏和状态栏，其他页面从它的"…"菜单进。
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selection: AppTab = .fridge

    var body: some View {
        TabView(selection: $selection) {
            Tab("冰箱", systemImage: "refrigerator", value: .fridge) {
                FridgeView(selection: $selection)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab("清单", systemImage: "list.bullet.clipboard", value: .inventory) {
                InventoryListView()
            }
            Tab("购物", systemImage: "cart", value: .shopping) {
                ShoppingListView()
            }
            Tab("菜谱", systemImage: "frying.pan", value: .recipes) {
                RecipesView()
            }
            Tab("统计", systemImage: "chart.bar", value: .stats) {
                StatsView()
            }
        }
        // 👇 冰箱要铺满整块屏幕：不要 iPhone Duo 的竖直栏，冰箱页也不要状态栏和 Home 指示条。
        .toolbarVerticalBehavior(.disabled)
        .statusBarHidden(selection == .fridge)
        .persistentSystemOverlays(selection == .fridge ? .hidden : .automatic)
        .task {
            SampleData.seedIfNeeded(in: modelContext)
            await NotificationService.requestAuthorizationIfNeeded()
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [FoodItem.self, ShoppingItem.self, DoorNote.self, DoorPhoto.self], inMemory: true)
}
