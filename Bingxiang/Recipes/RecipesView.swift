import SwiftData
import SwiftUI

/// "今晚吃什么"：拿冰箱里的东西去匹配家常菜，优先消耗快过期的。
struct RecipesView: View {
    enum Filter: String, CaseIterable, Identifiable {
        case ready = "现在能做"
        case almost = "差一点"
        case all = "全部"

        var id: String { rawValue }
    }

    @Query(filter: #Predicate<FoodItem> { $0.statusRaw == "inStock" })
    private var items: [FoodItem]

    @State private var filter: Filter = .ready

    private var matches: [RecipeMatch] {
        let all = RecipeCatalog.matches(for: items)
        switch filter {
        case .ready: return all.filter(\.isReady)
        case .almost: return all.filter { !$0.isReady && $0.missing.count <= 1 }
        case .all: return all
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if matches.isEmpty {
                    ContentUnavailableView {
                        Label(filter == .ready ? "现在还做不了什么" : "没有符合的菜", systemImage: "frying.pan")
                    } description: {
                        Text(filter == .ready ? "看看「差一点」，补一两样就能开火。" : "换个筛选试试。")
                    }
                } else {
                    List(matches) { match in
                        NavigationLink(value: match.recipe) {
                            RecipeRow(match: match)
                        }
                    }
                }
            }
            .navigationTitle("菜谱")
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe, items: items)
            }
            .safeAreaInset(edge: .top) {
                Picker("筛选", selection: $filter) {
                    ForEach(Filter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(.bar)
            }
        }
    }
}

private struct RecipeRow: View {
    let match: RecipeMatch

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(match.recipe.emoji)
                .font(.title)
                .frame(width: 48, height: 48)
                .background(.fill.tertiary, in: .rect(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(match.recipe.name)
                        .font(.body.weight(.semibold))
                    Spacer()
                    Label("\(match.recipe.minutes) 分钟", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                IngredientChips(match: match)
                if match.usesExpiringCount > 0 {
                    Label("能用掉 \(match.usesExpiringCount) 样快过期的", systemImage: "flame.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// 食材小标签：有的绿色，缺的灰色加删除线。
struct IngredientChips: View {
    let match: RecipeMatch

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(match.recipe.ingredients, id: \.self) { ingredient in
                let has = match.have.contains(ingredient)
                Text(ingredient)
                    .font(.caption)
                    .strikethrough(!has)
                    .foregroundStyle(has ? Color.green : Color.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((has ? Color.green : Color.secondary).opacity(0.12), in: .capsule)
            }
        }
    }
}

/// 简单的流式布局：放不下就换行。
/// 默认 MainActor 隔离下，`Layout` 的实现要声明成 `nonisolated`。
nonisolated struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width == .infinity ? x : width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
