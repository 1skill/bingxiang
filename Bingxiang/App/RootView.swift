import SwiftData
import SwiftUI

/// 五个标签页。在展开的 iPhone Duo 上，标签栏会自动跑到侧边的竖直栏里。
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            Tab("冰箱", systemImage: "refrigerator") {
                FridgeView()
            }
            Tab("清单", systemImage: "list.bullet.clipboard") {
                InventoryListView()
            }
            Tab("购物", systemImage: "cart") {
                ShoppingListView()
            }
            Tab("菜谱", systemImage: "frying.pan") {
                RecipesView()
            }
            Tab("统计", systemImage: "chart.bar") {
                StatsView()
            }
        }
        .task {
            SampleData.seedIfNeeded(in: modelContext)
            await NotificationService.requestAuthorizationIfNeeded()
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [FoodItem.self, ShoppingItem.self, DoorNote.self], inMemory: true)
}
