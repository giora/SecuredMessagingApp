//
//  SendMessageUseCase.swift
//  EncryptedMessagingApp
//
//  Created by giora krasilshchik on 16/07/2025.
//

import Foundation

// MARK: - Send Message Use Case Protocol
// Protocol for sending encrypted messages via notifications.
protocol SendMessageUseCase {
    func execute()
}

// MARK: - Send Message Use Case Implementation
// Handles sending encrypted messages through local notifications.
class SendMessageUseCaseImpl: SendMessageUseCase {
    // MARK: - Properties
    private let notificationUtils: NotificationUtils
    private let messageRepository: MessageRepository

    // MARK: - Initialization
    init(
        notificationUtils: NotificationUtils,
        messageRepository: MessageRepository
    ) {
        self.notificationUtils = notificationUtils
        self.messageRepository = messageRepository
    }

    // MARK: - Public Methods
    // Executes the use case to send a message.
    func execute() {
        Task {
            guard let message = messageRepository.getEncryptedMessage() else {
                print("No encrypted message available")
                return
            }

            // Create userInfo with encrypted message and signature
            let userInfo: [String: Any] = [
                GlobalConsts.encryptedMessage: message.encryptedData,
                GlobalConsts.messageSignature: message.signature,
            ]

            messageRepository.clearMessage()

            // Send notification with userInfo containing encrypted message and signature
            await notificationUtils.scheduleNotification(
                title: Constants.title,
                body: Constants.body,
                identifier:
                    "\(Constants.identifierPrefix)_\(Date().timeIntervalSince1970)",
                delay: Constants.delay,
                userInfo: userInfo
            )
        }
    }
}

extension SendMessageUseCaseImpl {
    fileprivate struct Constants {
        static let title = "Messaging App"
        static let body = "New Message"
        static let delay: TimeInterval = 15.0
        static let identifierPrefix = "message"
    }
}
