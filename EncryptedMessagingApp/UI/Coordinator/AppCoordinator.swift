//
//  AppCoordinator.swift
//  EncryptedMessagingApp
//
//  Created by giora krasilshchik on 16/07/2025.
//

import Combine
import Foundation
import SwiftUI
import UserNotifications

// MARK: - App Entry Type Enum
// Represents the entry point type for the app (normal or push notification).
enum AppEntryType {
    case normal
    case pushNotification
}

// MARK: - Navigation Destination Enum
// Represents navigation destinations in the app.
enum NavigationDestination {
    case sendMessage
    case displayMessage
}

// MARK: - App Coordinator
// Main navigation coordinator managing app flow and view creation.
@MainActor
class AppCoordinator: ObservableObject {
    // MARK: - Published Properties
    // State for current navigation destination.
    @Published var currentDestination: NavigationDestination = .sendMessage

    // MARK: - Private Properties
    // Internal state and dependencies.
    private var entryType: AppEntryType = .normal
    private var notificationEncryptedMessage: EncryptedMessage?
    private let notificationState: NotificationState = DIContainer.shared
        .resolve(NotificationState.self)!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    // Checks for pending notifications and sets initial destination.
    init() {
        checkForPendingNotification()
        determineInitialDestination()
    }

    // MARK: - View Creation Methods
    // Creates views for navigation destinations.
    func createSendMessageView() -> SendMessageView {
        let viewModel = createSendMessageViewModel()
        return SendMessageView(viewModel: viewModel)
    }

    func createDisplayMessageView() -> DisplayMessageView {
        let viewModel = createDisplayMessageViewModel()
        viewModel.navigationEventPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                self?.handleNavigationEvent(event)
            }
            .store(in: &cancellables)
        return DisplayMessageView(viewModel: viewModel)
    }

    // MARK: - Public Methods
    // Handles app entry, navigation, and notification taps.
    func handleAppEntry(_ entryType: AppEntryType) {
        self.entryType = entryType
        determineInitialDestination()
    }

    func navigateToSendMessage() {
        // Clear any pending notification data when navigating to send message
        notificationEncryptedMessage = nil
        currentDestination = .sendMessage
    }

    func navigateToDisplayMessage() {
        currentDestination = .displayMessage
    }

    func handleNotificationTap(_ notification: Notification) {
        notificationState.clearPendingNotificationData()
        // Extract encrypted message from notification object
        if let encryptedMessage = notification.object as? EncryptedMessage {
            self.notificationEncryptedMessage = encryptedMessage
            handleAppEntry(.pushNotification)
        }
    }
}

// MARK: - Private Methods
// Helpers for view model creation, notification checks, and navigation events.
extension AppCoordinator {

    fileprivate func createSendMessageViewModel() -> SendMessageViewModel {
        return SendMessageViewModel()
    }

    fileprivate func createDisplayMessageViewModel() -> DisplayMessageViewModel
    {
        // Use encrypted message from notification if available, otherwise use empty message
        let encryptedMessage = notificationEncryptedMessage
        return DisplayMessageViewModel(encryptedMessage: encryptedMessage)
    }

    fileprivate func checkForPendingNotification() {
        // Check if app was launched from notification (cold start)
        if let pendingData = notificationState.getPendingNotificationData() {
            self.notificationEncryptedMessage = pendingData
            self.entryType = .pushNotification

            // Clear the pending data to avoid reusing it
            notificationState.clearPendingNotificationData()
        }
    }

    fileprivate func determineInitialDestination() {
        switch entryType {
        case .normal:
            currentDestination = .sendMessage
        case .pushNotification:
            currentDestination = .displayMessage
        }
    }

    // MARK: - Navigation Event Handling
    fileprivate func handleNavigationEvent(
        _ event: DisplayMessageViewModel.NavigationEvent
    ) {
        switch event {
        case .navigateToSendMessage:
            navigateToSendMessage()
        }
    }
}
