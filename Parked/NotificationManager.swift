import Foundation
import UserNotifications

final class NotificationManager {

    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in

                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                    return
                }

                print("Notification permission granted: \(granted)")
            }
    }

    func scheduleParkingReminder(for expirationDate: Date) {

        let reminderDate = expirationDate.addingTimeInterval(-600)

        guard reminderDate > Date() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Parking Expiring Soon"
        content.body = "Your parking expires in 10 minutes."
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: reminderDate
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "parking-expiration-reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("Parking reminder scheduled.")
            }
        }
    }

    func cancelParkingReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["parking-expiration-reminder"]
            )
    }
}
