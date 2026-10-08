# 冰箱 · Duo

把 iPhone Duo 的折叠当成冰箱门。

- **合上手机**：外屏是一扇贴满磁贴和便签的冰箱门。
- **慢慢展开**：铰链角度驱动门绕着左边转开，里面先是一片漆黑，开到一定角度灯"咔"地亮起，带触觉和音效。
- **完全展开**：看到冷冻室、三层层架、保鲜抽屉和门架上的所有食材。
- **半折成桌面模式**：上半屏立着冰箱，下半屏是够得着的清单；像书一样半折就是左右分栏。

灵感来自 r/iPhoneDuo 社区里有人做的冰箱 app，以及 [MealPlan 项目的 "Fridge experience" 提案](https://github.com/holgerkrupp/MealPlan/issues/36)。这个仓库是一次复刻，并在它之上加了一批真正能当食材管家用的功能。

## 功能

### 复刻的部分

| | |
|---|---|
| 冰箱门 | 不锈钢门板、两个把手、"N 样快过期"和"购物清单"磁贴、可编辑的彩色便签 |
| 铰链开门 | `onHingeChange` 读角度，`DoorController` 换算成开门进度；12° 以下算关紧，150° 以上算全开 |
| 门控灯 | 开门进度超过 18% 灯亮，触觉 `.impact(.medium)` + 系统音效，跟随静音开关 |
| 冰箱内部 | 冷冻室 / 上中下层 / 保鲜抽屉 / 门架，食材按 emoji 摆在架子上，角上的小点表示快过期或已过期 |
| 围绕折痕布局 | 用 `reservedRegions(kind: .division)` 判断桌面 / 书本姿态，布局听区域的，不听角度的 |
| 无铰链回退 | 普通 iPhone / iPad 点把手开关门；开了「减弱动态效果」只做淡入淡出 |

### 新增的部分

| 功能 | 说明 |
|---|---|
| 食材清单 | SwiftData 持久化；按新鲜度分组、搜索、按位置 / 分类筛选；右滑"吃掉了"，左滑"扔掉了"或"加购" |
| 快速添加 | 60 多种常见食材带默认存放位置和保质期，点一下就入库；手动添加时输入名字自动联想 |
| 到期提醒 | 本地通知，可设提前几天、几点提醒；改设置后自动重排 |
| 购物清单 | 勾掉买到的，一键"放进冰箱"按默认保质期入库；根据最近一个月吃完的东西给补货建议 |
| 今晚吃什么 | 20 多道家常菜与库存匹配，优先推荐能用掉快过期食材的；缺的一键加购，做完一键扣库存 |
| 浪费统计 | Swift Charts 画最近 8 周吃掉 vs 扔掉，本月浪费率，最常被扔掉的分类 |
| 门没关提醒 | 门开太久（默认 1 分 30 秒）弹"门没关好"，模仿真冰箱的蜂鸣 |
| 开门计数 | 冷冻室门上的磁贴显示今天开了几次门 |
| 冰箱便签 | 门上贴便签，五种颜色，随机歪一点 |
| 竖直标签栏 | 用系统 `TabView`，展开时标签栏自动跑到侧边；所有工具栏按钮都带标题和图标 |

## 运行

需要 Xcode 27.1 或更新版本，以及 iPhone Duo 模拟器（iOS 27.1）。

```bash
open Bingxiang.xcodeproj
```

或者命令行构建：

```bash
xcodebuild -project Bingxiang.xcodeproj -scheme Bingxiang \
  -destination 'platform=iOS Simulator,name=iPhone Duo' build
```

在模拟器里转动铰链：Device Hub 里按住 Option 会出现铰链滑块；或者用 [hinge](https://github.com/artemnovichkov/hinge) 命令行工具：

```bash
hinge close        # 0°，看冰箱门
hinge sweep 0 180 3   # 三秒内慢慢打开，看灯亮起
hinge half         # 90°，桌面模式
```

截图：`xcrun simctl io booted screenshot` 拍内屏，加 `--display=1` 拍外屏。

第一次启动会放入一批示例食材、便签和历史记录，方便直接看效果。设置里可以再放一次。

## 工程结构

工程用的是 Xcode 27.1 的 JSON 工程格式（`Bingxiang.xcodeproj/project.xcproj`），每个源文件都在里面显式列出。新增文件时加一行：

```json
{ "path": "NewView.swift", "target-membership": [ "Bingxiang/compile-sources" ] }
```

```
Bingxiang
├── App          # 入口、标签页
├── Models       # SwiftData 模型：FoodItem、ShoppingItem、DoorNote
├── Data         # 常见食材库、菜谱库、示例数据
├── Fridge       # 冰箱门、内部、门控制器、围绕折痕的布局
├── Inventory    # 清单、添加 / 编辑、快速添加
├── Shopping     # 购物清单与补货建议
├── Recipes      # 菜谱匹配与详情
├── Stats        # 浪费统计
├── Settings     # 设置与 AppStorage 键
├── Services     # 本地通知、音效
├── Components   # 共用的行、徽标、滑动操作
└── Resources    # 资源目录
```

构建设置：Swift 6，`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`。自定义 `Layout` / `Shape` 要声明成 `nonisolated struct`。

## 用到的 iPhone Duo API

```swift
// 铰链：只用来做效果和交互
.onHingeChange { _, newContext in
    door.apply(hingeDegrees: newContext.hinge?.angle.degrees)   // nil = 没有铰链
}

// 折痕：用来做布局
GeometryReader { proxy in
    let fold = proxy.reservedRegions(kind: .division).first?.frame
    // fold.width > fold.height → 桌面模式；否则书本模式；nil → 平放或合上
}
```

## 已知限制

- 这个仓库在没有 Xcode 的环境里写成，代码只做过语法检查，还没在 Xcode 27.1 里真正编译和跑过。第一次打开请留意编译器报错。
- 音效用的是系统音效 ID，不是自定义音频。
- 还没做 iCloud 同步和条码扫描，这两项是接下来最值得加的。

## 参考

- [iPhone Duo by Examples](https://github.com/artemnovichkov/iPhone-Duo-by-Examples)：铰链、保留区域、排列视图的示例
- [DuoBird](https://github.com/artemnovichkov/DuoBird)：用铰链当按钮的 Flappy Bird
- [Preparing your app for iPhone Duo](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo)
