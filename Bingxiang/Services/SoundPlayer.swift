import AudioToolbox
import Foundation

/// 开门、亮灯时的小音效。用系统音效，跟随静音开关。
enum SoundPlayer {
    enum Effect {
        case latch
        case light
        case drop

        fileprivate var systemSoundID: SystemSoundID {
            switch self {
            case .latch: 1104
            case .light: 1057
            case .drop: 1123
            }
        }
    }

    static func play(_ effect: Effect) {
        guard UserDefaults.standard.object(forKey: SettingsKeys.soundEnabled) as? Bool ?? true else { return }
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }
}
