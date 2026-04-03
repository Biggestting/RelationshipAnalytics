import Foundation
import UserNotifications
import Contacts

/// Tracks incoming message notifications to count messages per contact.
///
/// How it works:
/// - Registers as a UNUserNotificationCenter delegate
/// - When a message notification arrives, extracts the sender name
/// - Increments the received count for that contact in LiveDataStore
///
/// Limitations:
/// - Only counts messages received while the app is in foreground
/// - Cannot read message content (privacy)
/// - For background tracking, a Notification Service Extension is needed
///   (separate target, can be added later)
final class MessageTracker: NSObject, ObservableObject {
    static let shared = MessageTracker()

    private let store = LiveDataStore.shared
    @Published var isTracking = false

    private override init() {
        super.init()
    }

    func startTracking() {
        requestNotificationPermission()
        isTracking = true
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UNUserNotificationCenter.current().delegate = self
                }
            }
        }
    }

    /// Manually log a received message (for Shortcuts integration)
    func logReceivedMessage(from contact: String) {
        store.logMessageNotification(from: contact)
        NotificationCenter.default.post(name: .messageTracked, object: contact)
    }

    /// Manually log a sent message (for Shortcuts integration)
    func logSentMessage(to contact: String) {
        store.logMessageSent(to: contact)
        NotificationCenter.default.post(name: .messageTracked, object: contact)
    }
}

extension MessageTracker: UNUserNotificationCenterDelegate {
    /// Called when a notification is received while the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let content = notification.request.content

        // Check if this is a Messages notification
        let bundleID = notification.request.content.targetContentIdentifier ?? ""
        let categoryID = content.categoryIdentifier

        // Messages notifications typically have the sender in the title
        let sender = content.title
        if !sender.isEmpty {
            store.logMessageNotification(from: sender)
            NotificationCenter.default.post(name: .messageTracked, object: sender)
        }

        // Still show the notification
        completionHandler([.banner, .sound, .badge])
    }

    /// Called when user taps on a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
