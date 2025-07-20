//
//  MessageRepository.swift
//  EncryptedMessagingApp
//
//  Created by giora krasilshchik on 15/07/2025.
//

import Combine
import Foundation

// MARK: - Encryption Status Events
// Events representing the status of encryption operations.
enum EncryptionStatus {
    case initialState
    case keyPairCreated
    case messageEncrypted
    case messageSigned(EncryptedMessage)
}

// MARK: - Decryption Status Events
// Events representing the status of decryption operations.
enum DycryptionStatus {
    case initialState
    case signatureVerified
    case messageDecrypted(String)
}

// MARK: - Encrypted Message Data Structure
// Structure for holding encrypted message data and signature.
struct EncryptedMessage {
    let encryptedData: Data
    let signature: Data
}

// MARK: - Message Repository Protocol
// Protocol for message encryption, decryption, and storage.
protocol MessageRepository {
    func createEncryptedMessage(text: String) -> AnyPublisher<
        EncryptionStatus, Error
    >
    func decryptMessage(_ encryptedMessage: EncryptedMessage) -> AnyPublisher<
        DycryptionStatus, Error
    >
    func getEncryptedMessage() -> EncryptedMessage?
    func clearMessage()
}

// MARK: - Message Repository Implementation
// Handles encryption, decryption, and message storage.
class MessageRepositoryImpl: MessageRepository {
    // MARK: - Properties
    // Dependencies and storage for encrypted messages.
    private let secureStorage: SecureStorage
    private let encryptionService: EncryptionService
    private(set) var encryptedMessage: EncryptedMessage?

    // MARK: - Initialization
    // Initializes repository with dependencies.
    init(
        secureStorage: SecureStorage,
        encryptionService: EncryptionService
    ) {
        self.secureStorage = secureStorage
        self.encryptionService = encryptionService
    }

    // MARK: - Public Methods
    /// Main API for encryption, decryption, and message management.
    func createEncryptedMessage(text: String) -> AnyPublisher<
        EncryptionStatus, Error
    > {
        // Validate input
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return Fail(error: MessageRepositoryError.emptyMessage)
                .eraseToAnyPublisher()
        }

        let subject = CurrentValueSubject<EncryptionStatus, Error>(
            .initialState)

        Task(priority: .high) {
            do {
                // Generate new encryption key pair for this message
                let encryptionKeyPair = try encryptionService.generateKeyPair(
                    keySize: Constants.keySize)

                // Store private ecnryption key in case the app terminated until the message recieved
                try secureStorage.storePrivateKey(
                    encryptionKeyPair.privateKey,
                    for: Constants.encryptionKeyIdentifier)

                // Generate new signing key pair for this message
                let signingKeyPair = try encryptionService.generateKeyPair(
                    keySize: Constants.keySize)

                // Store public signing key in case the app terminated until the message recieved
                try secureStorage.storePublicKey(
                    signingKeyPair.publicKey,
                    for: Constants.signingKeyIdentifier)

                // Emit keypair created event
                subject.send(.keyPairCreated)

                // Small delay to simulate processing
                try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

                // Encrypt the message using encryption key pair
                let encryptedData = try self.encryptionService.encryptMessage(
                    text, using: encryptionKeyPair.publicKey)

                // Emit message encrypted event
                subject.send(.messageEncrypted)

                // Small delay to simulate processing
                try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

                // Sign the encrypted message using signing key pair
                let signature = try self.encryptionService.signEncryptedMessage(
                    encryptedData, using: signingKeyPair.privateKey)
                
                // Create encrypted message instance
                let encryptedMessage = EncryptedMessage(
                    encryptedData: encryptedData,
                    signature: signature
                )
                
                self.encryptedMessage = encryptedMessage

                // Emit message signed event
                subject.send(.messageSigned(encryptedMessage))

                // Emit completion event
                subject.send(completion: .finished)
            } catch {
                print(
                    "Error encrypting/signing message: \(error.localizedDescription)"
                )
                subject.send(
                    completion: .failure(MessageRepositoryError.encryptionError)
                )
            }
        }

        return subject.eraseToAnyPublisher()
    }

    func decryptMessage(_ encryptedMessage: EncryptedMessage) -> AnyPublisher<
        DycryptionStatus, Error
    > {
        let subject = CurrentValueSubject<DycryptionStatus, Error>(
            .initialState)

        Task(priority: .high) {
            do {

                // Retrieve the key pairs using the message-specific tags
                let encryptionKey = try secureStorage.retrievePrivateKey(
                    for: Constants.encryptionKeyIdentifier)
                let signingKey = try secureStorage.retrievePublicKey(
                    for: Constants.signingKeyIdentifier)

                // Validate signature
                let isValid = try encryptionService.validateSignature(
                    encryptedMessage.signature,
                    for: encryptedMessage.encryptedData,
                    using: signingKey
                )

                guard isValid else {
                    throw MessageRepositoryError.decryptionError
                }

                subject.send(.signatureVerified)

                // Small delay to simulate processing
                try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

                // Decrypt the message
                let message = try encryptionService.decryptMessage(
                    encryptedMessage.encryptedData,
                    using: encryptionKey
                )

                subject.send(.messageDecrypted(message))
                subject.send(completion: .finished)

            } catch {
                print(
                    "Error validate signature/ decrypt message: \(error.localizedDescription)"
                )
                subject.send(
                    completion: .failure(MessageRepositoryError.decryptionError)
                )
            }
        }

        return subject.eraseToAnyPublisher()
    }

    func getEncryptedMessage() -> EncryptedMessage? {
        return encryptedMessage
    }

    func clearMessage() {
        encryptedMessage = nil
    }
}

extension MessageRepositoryImpl {
    fileprivate struct Constants {
        static let encryptionKeyIdentifier = "com.encryptedmessaging.encryption"
        static let signingKeyIdentifier = "com.encryptedmessaging.signing"
        static let keySize: Int = 1024
    }
}

// MARK: - Error Types
enum MessageRepositoryError: Error {
    case emptyMessage
    case encryptionError
    case decryptionError

    var errorDescription: String? {
        switch self {
        case .emptyMessage:
            return "Message cannot be empty"
        case .encryptionError:
            return "Failed to encrypt message"
        case .decryptionError:
            return "Failed to decrypt message"
        }
    }
}
