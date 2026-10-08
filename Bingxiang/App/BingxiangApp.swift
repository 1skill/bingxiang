import SwiftData
import SwiftUI

@main
struct BingxiangApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [FoodItem.self, ShoppingItem.self, DoorNote.self])
    }
}
