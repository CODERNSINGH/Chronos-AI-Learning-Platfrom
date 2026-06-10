import Foundation
import UserNotifications

enum NotificationService {
    static func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    static func scheduleDailyReminder(at hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["chronos.daily.reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Time to practice DSA! 🧠"
        content.body = "Keep your streak alive — 5 minutes of Chronos is all it takes."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: "chronos.daily.reminder",
                                            content: content,
                                            trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    static func cancelReminders() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["chronos.daily.reminder"])
    }
}
