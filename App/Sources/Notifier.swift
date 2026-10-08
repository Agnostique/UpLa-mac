import AppKit
import Foundation
import UserNotifications

// Receives notification clicks. Not actor-isolated because the system may call it on any queue.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let link = response.notification.request.content.userInfo[Notifier.linkKey] as? String

        // Only web links are opened; the deletion link is never put into a notification.
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier, let url = AppEnvironment.webURL(link) {
            Task { @MainActor in
                NSWorkspace.shared.open(url)
            }
        }

        completionHandler()
    }
}

// Upload results as notifications. Failures fall back to an alert when notifications are not allowed, so they are
// never lost.
@MainActor
final class Notifier {
    nonisolated static let linkKey = "link"

    private var askedForAuthorization = false

    // Asks for permission once, at the first upload (macOS shows its prompt only the first time).
    func prepare() {
        guard !askedForAuthorization else {
            return
        }

        askedForAuthorization = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                appLog.error("Notification permission request failed: \(error.localizedDescription, privacy: .public)")
            } else if !granted {
                appLog.notice("Notifications are not allowed")
            }
        }
    }

    func post(title: String, body: String, link: String? = nil, isError: Bool = false) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        if let link {
            content.userInfo = [Notifier.linkKey: link]
        }

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settings in
            let allowed = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional

            if allowed {
                center.add(request) { error in
                    if let error {
                        appLog.error("Posting a notification failed: \(error.localizedDescription, privacy: .public)")
                    }
                }
            } else if isError {
                Task { @MainActor in
                    Notifier.showAlert(title: title, message: body)
                }
            }
        }
    }

    static func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: String(localized: "OK"))
        NSApp.activate()
        alert.runModal()
    }
}
