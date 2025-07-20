//
//  SendMessageViewModel.swift
//  EncryptedMessagingApp
//
//  Created by giora krasilshchik on 15/07/2025.
//

import Combine
import Foundation

// MARK: - Send Message View Model
// View model for message composition, encryption, and biometric settings.
// Using ObservableObject instead @Observable to support iOS 15+
@MainActor
class SendMessageViewModel: ObservableObject {

    // MARK: - Encryption Status Enum
    // Represents the status of the encryption process.
    enum EncryptionStatus {
        case idle
        case starting
        case creatingKeys
        case messageEncrypted
        case messageSigned
        case completed
        case error
    }

    // MARK: - Published Properties
    // State variables for UI binding and encryption status.
    @Published var isSending: Bool = false
    @Published var canSendMessage: Bool = false
    @Published var encryptionStatus: EncryptionStatus = .idle
    @Published var isBiometricsEnabled: Bool = false {
        didSet {
            updateBimotricState(isON: isBiometricsEnabled)
        }
    }

    var messageText: String = "" {
        didSet {
            updateCanSendMessage()
        }
    }

    // MARK: - Dependencies
    // Services and repositories used by the view model.
    private let messageRepository: MessageRepository = DIContainer.shared
        .resolve(MessageRepository.self)!
    private let notificationService: NotificationUtils = DIContainer.shared
        .resolve(NotificationUtils.self)!
    private let userDefaultsService: UserDefaultsUtils = DIContainer.shared
        .resolve(UserDefaultsUtils.self)!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        loadBiometricsState()
    }

    // MARK: - Public Methods
    // Handles sending the message with biometric state.
    func sendMessage() {
        guard canSendMessage else { return }

        isSending = true
        encryptionStatus = .starting

        Task {
            if await notificationService.requestPermission() {
                messageRepository.createEncryptedMessage(text: messageText)
                    .receive(on: RunLoop.main)
                    .sink(
                        receiveCompletion: { [weak self] completion in
                            guard let self = self else { return }

                            switch completion {
                            case .finished:
                                self.encryptionStatus = .completed
                                self.messageText = ""
                                self.isSending = false
                            case .failure(_):
                                self.isSending = false
                                self.encryptionStatus = .error
                            }
                        },
                        receiveValue: { [weak self] status in
                            guard let self = self else { return }

                            switch status {
                            case .keyPairCreated:
                                self.encryptionStatus = .creatingKeys
                            case .messageEncrypted:
                                self.encryptionStatus = .messageEncrypted
                            case .messageSigned:
                                self.encryptionStatus = .messageSigned
                            case .initialState:
                                break
                            }
                        }
                    )
                    .store(in: &cancellables)
            }
        }
    }
}

// MARK: - Private Methods
// Helpers for updating state and loading biometric settings.
extension SendMessageViewModel {
    fileprivate func updateCanSendMessage() {
        canSendMessage =
            !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSending
    }

    fileprivate func updateBimotricState(isON: Bool) {
        userDefaultsService.setBool(
            isON, forKey: UserDefaultsUtilsKey.isBiometricsEnabled)
    }

    fileprivate func loadBiometricsState() {
        isBiometricsEnabled = userDefaultsService.getBool(
            forKey: UserDefaultsUtilsKey.isBiometricsEnabled)
    }
}
