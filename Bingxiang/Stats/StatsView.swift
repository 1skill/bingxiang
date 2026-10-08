import Charts
import SwiftData
import SwiftUI

/// 吃了多少、扔了多少。看着浪费率下降是件挺有成就感的事。
struct StatsView: View {
    @Query private var allItems: [FoodItem]

    private struct WeekStat: Identifiable {
        let weekStart: Date
        let eaten: Int
        let wasted: Int

        var id: Date { weekStart }
    }

    private var stock: [FoodItem] { allItems.filter(\.isInStock) }

    private var thisMonthResolved: [FoodItem] {
        let calendar = Calendar.current
        return allItems.filter { item in
            guard let resolved = item.resolvedDate, item.status != .inStock else { return false }
            return calendar.isDate(resolved, equalTo: .now, toGranularity: .month)
        }
    }

    private var wasteRate: Double {
        let total = thisMonthResolved.count
        guard total > 0 else { return 0 }
        return Double(thisMonthResolved.filter { $0.status == .wasted }.count) / Double(total)
    }

    private var weeks: [WeekStat] {
        let calendar = Calendar.current
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        return (0..<8).reversed().compactMap { offset in
            guard let start = calendar.date(byAdding: .weekOfYear, value: -offset, to: thisWeek),
                  let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) else { return nil }
            let resolved = allItems.filter { item in
                guard let date = item.resolvedDate, item.status != .inStock else { return false }
                return date >= start && date < end
            }
            return WeekStat(
                weekStart: start,
                eaten: resolved.filter { $0.status == .eaten }.count,
                wasted: resolved.filter { $0.status == .wasted }.count
            )
        }
    }

    private var wastedByCategory: [(FoodCategory, Int)] {
        var counts: [FoodCategory: Int] = [:]
        for item in allItems where item.status == .wasted {
            counts[item.category, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    tiles
                    chart
                    if !wastedByCategory.isEmpty {
                        categoryRanking
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("统计")
        }
    }

    private var tiles: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            StatTile(title: "在库", value: "\(stock.count)", symbol: "refrigerator", tint: .teal)
            StatTile(title: "快过期 / 已过期", value: "\(stock.filter { $0.freshness == .soon }.count) / \(stock.filter { $0.freshness == .expired }.count)", symbol: "flame", tint: .orange)
            StatTile(title: "本月浪费率", value: wasteRate.formatted(.percent.precision(.fractionLength(0))), symbol: "trash", tint: wasteRate > 0.3 ? .red : .green)
            StatTile(title: "今天开门", value: "\(DoorController.todayOpenCountFromDefaults()) 次", symbol: "door.left.hand.open", tint: .indigo)
        }
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近 8 周：吃掉 vs 扔掉")
                .font(.headline)
            Chart {
                ForEach(weeks) { week in
                    BarMark(
                        x: .value("周", week.weekStart, unit: .weekOfYear),
                        y: .value("数量", week.eaten)
                    )
                    .foregroundStyle(by: .value("结果", "吃掉了"))
                    BarMark(
                        x: .value("周", week.weekStart, unit: .weekOfYear),
                        y: .value("数量", week.wasted)
                    )
                    .foregroundStyle(by: .value("结果", "扔掉了"))
                }
            }
            .chartForegroundStyleScale(["吃掉了": Color.green, "扔掉了": Color.red.opacity(0.8)])
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.defaultDigits).day(), centered: true)
                }
            }
            .frame(height: 220)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
    }

    private var categoryRanking: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最常被扔掉的")
                .font(.headline)
            ForEach(wastedByCategory, id: \.0) { category, count in
                HStack {
                    Text(category.emoji)
                    Text(category.rawValue)
                    Spacer()
                    Text("\(count) 次")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .font(.subheadline)
            }
            Text("买这些的时候少买一点，或者放到更显眼的层架上。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(tint)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [FoodItem.self, ShoppingItem.self, DoorNote.self], inMemory: true)
}
