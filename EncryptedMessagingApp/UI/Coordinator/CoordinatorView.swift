//
//  CoordinatorView.swift
//  EncryptedMessagingApp
//
//  Created by giora krasilshchik on 16/07/2025.
//

import SwiftUI

/// Root coordinator view managing app navigation and notification handling.
/// Provides the main navigation container and routes between send/display message views.
struct CoordinatorView: View {
    // MARK: - State Object
    // Holds the app coordinator for navigation.
    @StateObject private var coordinator = AppCoordinator()

    // MARK: - Main View Body
    // Provides the main navigation container and routes between views.
    var body: some View {
        // Using NavigationView instead NavigationStack to support iOS 15+
        NavigationView {
            currentView
        }
        .navigationViewStyle(StackNavigationViewStyle())  // Ensures proper navigation on all devices
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSNotification.Name(NotificationEvents.notificationTapped))
        ) { notification in
            // Handle notification tap when app is in foreground or background
            coordinator.handleNotificationTap(notification)
        }
    }

    // MARK: - Private Methods
    // View builder for current navigation destination.
    @ViewBuilder
    private var currentView: some View {
        switch coordinator.currentDestination {
        case .sendMessage:
            coordinator.createSendMessageView()
        case .displayMessage:
            coordinator.createDisplayMessageView()
        }
    }
}
