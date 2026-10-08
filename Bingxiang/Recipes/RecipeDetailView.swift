import SwiftData
import SwiftUI

/// 一道菜的详情：食材对照、步骤，缺的加购，做完扣库存。
struct RecipeDetailView: View {
    let recipe: Recipe
    let items: [FoodItem]

    @Environment(\.modelContext) private var modelContext
    @State private var isCookConfirmed = false
    @State private var didCook = false
    @State private var didAddMissing = false

    private var match: RecipeMatch {
        RecipeCatalog.matches(for: items).first { $0.recipe == recipe }
            ?? RecipeMatch(recipe: recipe, have: [], missing: recipe.ingredients, usesExpiringCount: 0)
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Text(recipe.emoji)
                        .font(.system(size: 56))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(recipe.name)
                            .font(.title2.bold())
                        Label("\(recipe.minutes) 分钟", systemImage: "clock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(match.isReady ? "食材齐了，可以开火。" : "还缺 \(match.missing.count) 样。")
                            .font(.subheadline)
                            .foregroundStyle(match.isReady ? .green : .orange)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("食材") {
                ForEach(recipe.ingredients, id: \.self) { ingredient in
                    let stocked = stockedItem(for: ingredient)
                    HStack {
                        Image(systemName: stocked == nil ? "circle" : "checkmark.circle.fill")
                            .foregroundStyle(stocked == nil ? Color.secondary : Color.green)
                        Text(ingredient)
                        Spacer()
                        if let stocked {
                            FreshnessBadge(item: stocked)
                        } else {
                            Text("缺")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("步骤") {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.accentColor, in: .circle)
                        Text(step)
                    }
                    .padding(.vertical, 2)
                }
            }

            Section {
                if !match.missing.isEmpty {
                    Button(didAddMissing ? "已加入购物清单" : "缺的 \(match.missing.count) 样加入购物清单", systemImage: "cart.badge.plus") {
                        addMissingToShoppingList()
                    }
                    .disabled(didAddMissing)
                }
                Button(didCook ? "已扣掉用到的食材" : "做好了，扣掉用到的食材", systemImage: "fork.knife") {
                    isCookConfirmed = true
                }
                .disabled(didCook || match.have.isEmpty)
                .confirmationDialog("把用到的 \(match.have.count) 样食材标记为吃掉了？", isPresented: $isCookConfirmed, titleVisibility: .visible) {
                    Button("标记为吃掉了") { cook() }
                } message: {
                    Text("每样食材只扣掉最早到期的那一份。")
                }
            }
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: didCook)
    }

    /// 同名食材里挑最早到期的那一份。
    private func stockedItem(for ingredient: String) -> FoodItem? {
        items
            .filter { $0.isInStock && RecipeCatalog.matches(ingredient: ingredient, itemName: $0.name) }
            .min { $0.expiryDate < $1.expiryDate }
    }

    private func addMissingToShoppingList() {
        for ingredient in match.missing {
            let entry = FoodCatalog.entry(named: ingredient)
            ItemActions.addToShoppingList(
                name: ingredient,
                emoji: entry?.emoji ?? FoodCatalog.guessEmoji(for: ingredient, category: .other),
                unit: entry?.unit ?? "份",
                in: modelContext,
                source: .recipe
            )
        }
        withAnimation { didAddMissing = true }
    }

    private func cook() {
        for ingredient in match.have {
            if let item = stockedItem(for: ingredient) {
                ItemActions.markEaten(item, in: modelContext)
            }
        }
        withAnimation { didCook = true }
    }
}
