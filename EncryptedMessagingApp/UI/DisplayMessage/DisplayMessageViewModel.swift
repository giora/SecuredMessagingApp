//
//  DisplayMessageViewModel.swift
//  EncryptedMessagingApp
//
//  Created by giora krasilshchik on 16/07/2025.
//

import Combine
import Foundation



// MARK: - Display Message View Model
// View model for displaying and decrypting messages with biometric verification.
// Using ObservableObject instead @Observable to support iOS 15+
@MainActor
class DisplayMessageViewModel: ObservableObject {
    
    // MARK: - Message Decryption State Enum
    // Represents the state of the message decryption process.
    enum MessageDycryptionState {
        case initial
        case messageProccesing(MessageStatus)
        case fail(String)
    }
    
    // MARK: - Message Status Enum
    // Represents the status of the message decryption process.
    enum MessageStatus {
        case initial
        case signatureVerified
        case messageDecrypted
    }

    // MARK: - Navigation Event Enum
    // Events for navigation actions from the view model.
    enum NavigationEvent {
        case navigateToSendMessage
    }
    
    
    // MARK: - Published Properties
    // State variables for UI binding and decryption status.
    @Published var messageDecryptionState: MessageDycryptionState = .initial
    @Published var decryptedMessage: String = ""
    
    
    // MARK: - Navigation Event Publisher
    // Publishes navigation events to the coordinator.
    private let navigationEventSubject = PassthroughSubject<NavigationEvent, Never>()
    var navigationEventPublisher: AnyPublisher<NavigationEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Dependencies
    // Services and repositories used by the view model.
    private let messageRepository: MessageRepository = DIContainer.shared.resolve(MessageRepository.self)!
    private let verifyBiometricsUseCase: VerifyBiometricsUseCase = DIContainer.shared.resolve(VerifyBiometricsUseCase.self)!
    private let encryptedMessage: EncryptedMessage?
    private var cancellables = Set<AnyCancellable>()
    
    
    // MARK: - Initialization
    // Verifies biometrics and loads message on initialization.
    init(encryptedMessage: EncryptedMessage?) {
        self.encryptedMessage = encryptedMessage
        verifyAndLoadMessage()
    }
    
    // MARK: - Public Methods
    // Handles verification and loading of the message.
    func verifyAndLoadMessage() {
        Task {
            messageDecryptionState = .messageProccesing(.initial)
            let verificationResult = await verifyBiometricsUseCase.execute()

            switch verificationResult {
            case .success:
                loadMessage()
            case .failure(let error):
                messageDecryptionState = .fail(error)
            }

        }
    }
    
    // MARK: - Navigation Methods
    // Handles navigation actions from the view.
    func onSendMessageAction() {
        navigationEventSubject.send(.navigateToSendMessage)
    }
}


// MARK: - Private Methods
// Helpers for loading and decrypting messages.
private extension DisplayMessageViewModel {
    
     func loadMessage() {
        if let encryptedMessage = encryptedMessage {
            messageRepository.decryptMessage(encryptedMessage)
                .receive(on: RunLoop.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        guard let self = self else { return }

                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            messageDecryptionState = .fail(
                                error.localizedDescription)
                        }
                    },
                    receiveValue: { [weak self] status in
                        guard let self = self else { return }

                        switch status {
                        case .signatureVerified:
                            self.messageDecryptionState = .messageProccesing(
                                .signatureVerified)
                        case .messageDecrypted(let message):
                            self.decryptedMessage = message
                            self.messageDecryptionState = .messageProccesing(
                                .messageDecrypted)
                        case .initialState:
                            break
                        }
                    }
                )
                .store(in: &cancellables)
        }
    }
}
