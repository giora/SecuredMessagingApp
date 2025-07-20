//
//  LocalNotificationService.swift
//  EncryptedMessagingApp
//
//  Created by giora krasilshchik on 15/07/2025.
//

import Foundation
import UserNotifications

// MARK: - Notification Service Protocol
// Protocol for local notification scheduling and permission management.
protocol NotificationUtils {
    func requestPermission() async -> Bool
    func scheduleNotification(
        title: String, body: String, identifier: String, delay: TimeInterval?,
        userInfo: [String: Any]) async
}

// MARK: - Local Notification Service Implementation
// Provides scheduling and management of local notifications.
class LocalNotificationService: NotificationUtils {

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Permission Management
    // Requests notification permissions from the user.
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound]
            )
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    // MARK: - Scheduling Notifications
    // Schedules a local notification with optional delay and payload.
    func scheduleNotification(
        title: String, body: String, identifier: String,
        delay: TimeInterval? = nil, userInfo: [String: Any] = [:]
    ) async {
        let content = createNotificationContent(
            title: title, body: body, userInfo: userInfo)

        let trigger: UNNotificationTrigger?
        if let delay = delay, delay > 0 {
            trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: delay, repeats: false)
        } else {
            trigger = nil  // Immediate notification
        }

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        await addNotificationRequest(request)
    }

}

// MARK: - Private Methods
// Private helpers for notification content and request management.
extension LocalNotificationService {
    fileprivate func createNotificationContent(
        title: String, body: String, userInfo: [String: Any] = [:]
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.userInfo = userInfo
        return content
    }

    fileprivate func addNotificationRequest(_ request: UNNotificationRequest)
        async
    {
        do {
            try await notificationCenter.add(request)
            print("Notification scheduled: \(request.identifier)")
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
}
