import Foundation
import Observation

/// 冰箱门的语义状态。视图只关心"门开了多少、灯亮没亮"，
/// 不关心是铰链在动还是手指在点，所以在模拟器和普通 iPhone 上都能测。
@Observable
final class DoorController {
    enum Source {
        case hinge
        case manual
    }

    /// 0 表示关紧，1 表示完全打开。
    private(set) var openProgress: Double = 0
    /// 门开到一定角度灯才会亮，模仿真冰箱的门控开关。
    private(set) var isLightOn = false
    private(set) var source: Source = .manual
    /// 当前设备有没有铰链。没有的话，门用点击来开关。
    private(set) var hasHinge = false
    /// 这次开门的时间，关门后清空。用来做"门没关好"提醒。
    private(set) var openedAt: Date?
    /// 今天开了几次门。
    private(set) var todayOpenCount = 0

    /// 铰链角度（度）与门的映射。小于 `closedAngle` 视为关紧，大于 `fullyOpenAngle` 视为全开。
    static let closedAngle = 12.0
    static let fullyOpenAngle = 150.0
    /// 门开过这个比例灯才亮。
    static let lightThreshold = 0.18
    /// 门开过这个比例才算"开了门"。
    static let openThreshold = 0.05

    init() {
        todayOpenCount = Self.loadTodayOpenCount()
    }

    var isOpen: Bool { openProgress > Self.openThreshold }
    var isFullyOpen: Bool { openProgress >= 0.98 }

    /// 把铰链角度喂进来。`nil` 表示这个设备没有铰链。
    func apply(hingeDegrees: Double?) {
        guard let hingeDegrees else {
            hasHinge = false
            return
        }
        hasHinge = true
        source = .hinge
        let progress = (hingeDegrees - Self.closedAngle) / (Self.fullyOpenAngle - Self.closedAngle)
        setProgress(min(max(progress, 0), 1))
    }

    /// 没有铰链时的备用方案：点一下开，再点一下关。
    func toggleManually() {
        source = .manual
        setProgress(isOpen ? 0 : 1)
    }

    func setManually(open: Bool) {
        source = .manual
        setProgress(open ? 1 : 0)
    }

    private func setProgress(_ progress: Double) {
        let wasOpen = isOpen
        openProgress = progress
        isLightOn = progress > Self.lightThreshold
        let nowOpen = isOpen

        if !wasOpen && nowOpen {
            openedAt = .now
            registerOpen()
        } else if wasOpen && !nowOpen {
            openedAt = nil
        }
    }

    // MARK: 开门计数

    private func registerOpen() {
        todayOpenCount = Self.loadTodayOpenCount() + 1
        let defaults = UserDefaults.standard
        defaults.set(todayOpenCount, forKey: SettingsKeys.doorOpenCount)
        defaults.set(Self.todayKey, forKey: SettingsKeys.doorOpenCountDay)
    }

    private static var todayKey: String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    /// 统计页也想知道今天开了几次门。
    static func todayOpenCountFromDefaults() -> Int {
        loadTodayOpenCount()
    }

    private static func loadTodayOpenCount() -> Int {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: SettingsKeys.doorOpenCountDay) == todayKey else { return 0 }
        return defaults.integer(forKey: SettingsKeys.doorOpenCount)
    }
}
