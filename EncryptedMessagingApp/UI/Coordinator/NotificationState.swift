//
//  ].swift
//  EncryptedMessagingApp
//
//  Created by giora krasilshchik on 18/07/2025.
//

import Foundation

protocol NotificationState {
    func setPendingNotificationData(_ data: EncryptedMessage?)
    func getPendingNotificationData() -> EncryptedMessage?
    func clearPendingNotificationData()
}

/// Service for managing notification state and pending message data.
/// Handles temporary storage of encrypted messages from notifications during app launches.
class NotificationStateImpl: NotificationState {
    private var pendingNotificationData: EncryptedMessage?

    func setPendingNotificationData(_ data: EncryptedMessage?) {
        pendingNotificationData = data
    }

    func getPendingNotificationData() -> EncryptedMessage? {
        return pendingNotificationData
    }

    func clearPendingNotificationData() {
        pendingNotificationData = nil
    }
}
