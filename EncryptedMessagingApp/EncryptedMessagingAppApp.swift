//
//  EncryptedMessagingAppApp.swift
//  EncryptedMessagingApp
//
//  Created by giora krasilshchik on 15/07/2025.
//

import SwiftUI
import UserNotifications

@main
struct EncryptedMessagingAppApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        setupDependencies()
    }

    var body: some Scene {
        WindowGroup {
            CoordinatorView()
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .background:
                        print("App went to background")
                        DIContainer.shared.resolve(SendMessageUseCase.self)?
                            .execute()
                    case .inactive:
                        print("App is inactive")
                    case .active:
                        print("App is active")
                    @unknown default:
                        break
                    }
                }
        }
    }
}

// MARK: - App Delegate
/// App delegate handling application lifecycle and notification setup.
/// Configures notification center delegate for handling push notifications.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Setup notification center
        UNUserNotificationCenter.current().delegate = self

        return true
    }
}

// MARK: - Notification Delegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Extract encrypted message data from userInfo
        if let encryptedData = userInfo[GlobalConsts.encryptedMessage] as? Data,
            let signature = userInfo[GlobalConsts.messageSignature] as? Data
        {
            let encryptedMessage = EncryptedMessage(
                encryptedData: encryptedData, signature: signature)

            // Store the data using the service
            let notificationStateService = DIContainer.shared.resolve(
                NotificationState.self)
            notificationStateService?.setPendingNotificationData(
                encryptedMessage)

            // Also try to post notification for running apps (if view is already listening)
            NotificationCenter.default.post(
                name: NSNotification.Name(
                    NotificationEvents.notificationTapped),
                object: encryptedMessage
            )
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (
            UNNotificationPresentationOptions
        ) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}
