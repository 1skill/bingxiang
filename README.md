# 冰箱 · Duo

把 iPhone Duo 的折叠当成冰箱门。

- **合上手机**：外屏就是一台红色复古双门冰箱的正面，DUO 金属字、圆点磁贴、把手，门上贴着「快过期」「要买」便签和你自己的便签（可以拖着挪）。
- **展开**：折痕就是冰箱的合页。内屏一边是门的内侧（门架上的瓶瓶罐罐），一边是柜体（层架、保鲜抽屉，底下是冷冻区），每层架子下面一条灯带。灯要开到一定角度才亮，带触觉和音效。
- **半折**：门那一半离你远，会像相机景深一样虚化；折得越多越糊。
- **换颜色**：樱花红、夜空、星白、酒红、冰川，外壳和内壁一起换。
- **全屏**：冰箱页没有标签栏、状态栏和 Duo 的竖直栏，其他页面从右下角的「…」菜单进。门上可以贴拍立得照片（相机磁贴选图）和字母磁贴（拼一个词），都能拖。

灵感来自 r/iPhoneDuo 社区里有人做的冰箱 app，以及 [MealPlan 项目的 "Fridge experience" 提案](https://github.com/holgerkrupp/MealPlan/issues/36)。这个仓库是一次复刻，并在它之上加了一批真正能当食材管家用的功能。

## 功能

### 复刻的部分

| | |
|---|---|
| 冰箱门 | 红色烤漆双门、铬把手、DUO 金属字、圆点磁贴；「快过期」「要买」「今天开门」三张系统便签 + 可拖动的用户便签 |
| 铰链 | `onHingeChange` 读角度：`DoorController` 换算成开门进度决定灯亮不亮；角度还决定门那一半的虚化程度 |
| 门控灯 | 开门进度超过 18% 灯亮，触觉 `.impact(.medium)` + 系统音效，跟随静音开关 |
| 冰箱内部 | 折痕两侧：门内侧 3 层门架 + 2 层冷冻门架；柜体上中下层 + 保鲜抽屉 + 2 层冷冻。每层下有灯带，食材 emoji 摆在层板上，角上小点标新鲜度 |
| 围绕折痕布局 | 用 `reservedRegions(kind: .division, options: [.includeInactive])` 拿到折痕位置，把门和柜体分列两侧；书本和桌面姿态都支持 |
| 颜色 | 5 套配色，外壳 / 内壁 / 层板 / 按钮一起换 |
| 无铰链回退 | 普通 iPhone / iPad 点门打开、左上角叉关上；开了「减弱动态效果」不做虚化 |

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
| 冰箱便签 | 门上贴便签，五种颜色，随机歪一点，可以拖到任何位置 |
| 拍立得 | 点门上的相机磁贴从相册选图，缩小后存进 SwiftData，贴成拍立得，点一下可以撕掉 |
| 字母磁贴 | 「…」→ 字母拼字，最多 8 个字，五颜六色的字母磁贴，可以拖 |
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

### 只有 Xcode 27.0 的时候

iPhone Duo 的 API 只在 iOS 27.1 SDK 里有。手头只有 Xcode 27.0 时，可以带上 `DUO_API_SHIM` 编译条件，`Services/DuoAPIShim.swift` 会提供同名的空实现（铰链永远为 nil，分割区域永远为空），其余功能在普通 iPhone 模拟器上照常运行：

```bash
xcodebuild -project Bingxiang.xcodeproj -scheme Bingxiang \
  -destination 'generic/platform=iOS Simulator' \
  IPHONEOS_DEPLOYMENT_TARGET=27.0 \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) DUO_API_SHIM' build
```

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

- 已在 Xcode 27.1 RC + iPhone Duo 模拟器（iOS 27.1）上验证：合上显示冰箱门，`hinge` 转到 60° 门开灯亮、开门计数 +1，180° 切到内屏显示冰箱内部与清单，门开太久会弹「门没关好」。
- 模拟器里只用 `hinge` 改角度不会切换内外屏：到 180° 才会切到内屏。桌面 / 书本姿态的布局要在 Device Hub 里用折叠按钮摆姿势来看。
- 音效用的是系统音效 ID，不是自定义音频。
- 还没做 iCloud 同步和条码扫描，这两项是接下来最值得加的。

## 参考

- [iPhone Duo by Examples](https://github.com/artemnovichkov/iPhone-Duo-by-Examples)：铰链、保留区域、排列视图的示例
- [DuoBird](https://github.com/artemnovichkov/DuoBird)：用铰链当按钮的 Flappy Bird
- [Preparing your app for iPhone Duo](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo)
