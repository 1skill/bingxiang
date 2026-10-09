import Foundation
import UserNotifications

/// 到期提醒：在到期前 N 天的早上提醒一次。
enum NotificationService {
    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func schedule(for item: FoodItem) {
        guard item.isInStock else {
            cancel(for: item)
            return
        }
        guard let identifier = item.notificationID else { return }

        let defaults = UserDefaults.standard
        let leadDays = defaults.object(forKey: SettingsKeys.expiryLeadDays) as? Int ?? 1
        let hour = defaults.object(forKey: SettingsKeys.expiryNotificationHour) as? Int ?? 9

        let calendar = Calendar.current
        guard let remindDay = calendar.date(byAdding: .day, value: -leadDays, to: item.expiryDate) else { return }
        var components = calendar.dateComponents([.year, .month, .day], from: remindDay)
        components.hour = hour
        components.minute = 0
        guard let fireDate = calendar.date(from: components), fireDate > .now else {
            cancel(for: item)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "\(item.emoji) \(item.name) 快到期了"
        content.body = leadDays == 0 ? "今天就要吃掉它。" : "还有 \(leadDays) 天到期，想想今天怎么吃？"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request)
    }

    static func cancel(for item: FoodItem) {
        guard let identifier = item.notificationID else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// 设置变了以后，把所有在库食材的提醒重排一遍。
    static func reschedule(all items: [FoodItem]) {
        for item in items {
            schedule(for: item)
        }
    }
}
