import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsKeys.fridgeExperience) private var fridgeExperience = true
    @AppStorage(SettingsKeys.soundEnabled) private var soundEnabled = true
    @AppStorage(SettingsKeys.doorAjarSeconds) private var doorAjarSeconds = 90
    @AppStorage(SettingsKeys.expiryLeadDays) private var expiryLeadDays = 1
    @AppStorage(SettingsKeys.expiryNotificationHour) private var expiryNotificationHour = 9

    @Query(filter: #Predicate<FoodItem> { $0.statusRaw == "inStock" })
    private var stockItems: [FoodItem]

    @State private var isResetConfirmed = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("冰箱门体验", systemImage: "door.left.hand.open", isOn: $fridgeExperience)
                    Toggle("开门音效", systemImage: "speaker.wave.2", isOn: $soundEnabled)
                        .disabled(!fridgeExperience)
                    Picker("门没关提醒", systemImage: "exclamationmark.triangle", selection: $doorAjarSeconds) {
                        Text("关闭").tag(0)
                        Text("30 秒").tag(30)
                        Text("1 分 30 秒").tag(90)
                        Text("3 分钟").tag(180)
                    }
                    .disabled(!fridgeExperience)
                } header: {
                    Text("iPhone Duo")
                } footer: {
                    Text("在 iPhone Duo 上，合上手机就是关门，展开就是开门。关掉以后冰箱一直是打开的，当普通清单用。")
                }

                Section {
                    Picker("提前提醒", systemImage: "bell.badge", selection: $expiryLeadDays) {
                        Text("当天").tag(0)
                        Text("1 天").tag(1)
                        Text("2 天").tag(2)
                        Text("3 天").tag(3)
                    }
                    Picker("提醒时间", systemImage: "clock", selection: $expiryNotificationHour) {
                        ForEach([7, 8, 9, 10, 12, 18, 20], id: \.self) { hour in
                            Text("\(hour):00").tag(hour)
                        }
                    }
                } header: {
                    Text("到期提醒")
                } footer: {
                    Text("改了以后会给所有在库食材重新安排一次提醒。")
                }
                .onChange(of: expiryLeadDays) { _, _ in NotificationService.reschedule(all: stockItems) }
                .onChange(of: expiryNotificationHour) { _, _ in NotificationService.reschedule(all: stockItems) }

                Section("数据") {
                    Button("重新放入示例数据", systemImage: "sparkles") {
                        isResetConfirmed = true
                    }
                    .confirmationDialog("放入示例数据？", isPresented: $isResetConfirmed, titleVisibility: .visible) {
                        Button("放入") {
                            SampleData.insertSamples(in: modelContext)
                        }
                    } message: {
                        Text("会在现有数据之外再加一批示例食材、便签和历史记录。")
                    }
                }

                Section("关于") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("冰箱 · Duo")
                            .font(.headline)
                        Text("把 iPhone Duo 的折叠当成冰箱门：合上是贴满磁贴的门，展开是亮着灯的冰箱。记录食材、提醒过期、推荐今晚吃什么，顺便看看自己浪费了多少。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("灵感来自 r/iPhoneDuo 社区的冰箱 app，以及 MealPlan 项目的「Fridge experience」提案。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成", systemImage: "checkmark") { dismiss() }
                }
            }
        }
    }
}
