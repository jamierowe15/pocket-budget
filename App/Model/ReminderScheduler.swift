import Foundation
import UserNotifications

/// A repeating local notification at 8 PM. Local means the phone schedules it itself:
/// no server, no push certificate.
enum ReminderScheduler {
    static let identifier = "daily-spending-reminder"

    /// Asks permission the first time. Returns false if the person said no.
    static func enable(hour: Int = 20) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return false }
        let content = UNMutableNotificationContent()
        content.title = "Pocket Budget"
        content.body = "Anything to log today? It takes five seconds."
        content.sound = .default
        var time = DateComponents()
        time.hour = hour
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        do {
            try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
            return true
        } catch {
            return false
        }
    }

    static func disable() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
