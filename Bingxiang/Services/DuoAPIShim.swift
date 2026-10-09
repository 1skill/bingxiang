#if DUO_API_SHIM
import SwiftUI

// iPhone Duo 的 API 只在 iOS 27.1 SDK 里有。手头只有 Xcode 27.0 时，
// 在构建命令里加上 SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) DUO_API_SHIM'，
// 这个文件会提供同名的空实现，让其余代码照常编译、在普通 iPhone 模拟器上运行。
// 铰链永远是 nil（门用点击开关），分割区域永远为空（当作平放布局）。
// 正式构建请用 Xcode 27.1，不要带这个条件。

struct DeviceHinge: Hashable {
    struct Status: Hashable {
        static let closed = Status(rawValue: 0)
        static let partiallyOpen = Status(rawValue: 1)
        static let fullyOpen = Status(rawValue: 2)
        let rawValue: Int
    }

    var angle: Angle
    var status: Status
}

struct DeviceHingeContext {
    var hinge: DeviceHinge?
}

extension View {
    func onHingeChange(
        isEnabled: Bool = true,
        _ action: @escaping (DeviceHingeContext, DeviceHingeContext) -> Void
    ) -> some View {
        onAppear {
            action(DeviceHingeContext(), DeviceHingeContext())
        }
    }
}

struct ReservedRegion: Identifiable {
    enum Kind: Hashable {
        case division
        case occlusion
    }

    struct QueryOptions: OptionSet {
        static let includeInactive = QueryOptions(rawValue: 1)
        let rawValue: Int
    }

    let id = UUID()
    var frame: CGRect
    var margins: EdgeInsets
    var isActive: Bool
}

extension GeometryProxy {
    func reservedRegions(kind: ReservedRegion.Kind, options: ReservedRegion.QueryOptions = []) -> [ReservedRegion] {
        []
    }
}
#endif
