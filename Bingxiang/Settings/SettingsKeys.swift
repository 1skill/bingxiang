import Foundation

/// `@AppStorage` 和 `UserDefaults` 共用的键。
enum SettingsKeys {
    static let fridgeExperience = "fridgeExperience"
    static let soundEnabled = "soundEnabled"
    static let doorAjarSeconds = "doorAjarSeconds"
    static let expiryLeadDays = "expiryLeadDays"
    static let expiryNotificationHour = "expiryNotificationHour"
    static let hasSeededSampleData = "hasSeededSampleData"
    static let doorOpenCount = "doorOpenCount"
    static let doorOpenCountDay = "doorOpenCountDay"
}
