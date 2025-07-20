import Foundation
import Security

// MARK: - Encryption Service Protocol
// Protocol for cryptographic operations: key generation, encryption, decryption, signing, and validation.
protocol EncryptionService {
    func generateKeyPair(keySize: Int) throws -> (publicKey: SecKey, privateKey: SecKey)
    func encryptMessage(_ message: String, using publicKey: SecKey) throws -> Data
    func decryptMessage(_ encryptedData: Data, using privateKey: SecKey) throws -> String
    func signEncryptedMessage(_ encryptedData: Data, using privateKey: SecKey) throws -> Data
    func validateSignature(_ signature: Data, for encryptedData: Data, using publicKey: SecKey) throws -> Bool
}

// MARK: - RSA Encryption Service Implementation
// Provides RSA-based cryptographic operations using iOS Security framework.
class RSAEncryptionService: EncryptionService {
    
    // MARK: - Encryption Errors
    // Represents errors that can occur during cryptographic operations.
    enum EncryptionError: Error {
        case keyGenerationFailed(CFError?)
        case encryptionFailed(CFError?)
        case decryptionFailed(CFError?)
        case signingFailed(CFError?)
        case signatureValidationFailed(CFError)
        case invalidMessageData
        case invalidDecryptedData
        
        var localizedDescription: String {
            switch self {
            case .keyGenerationFailed(let error):
                return "Key generation failed: \(error?.localizedDescription ?? "Unknown error")"
            case .encryptionFailed(let error):
                return "Encryption failed: \(error?.localizedDescription ?? "Unknown error")"
            case .decryptionFailed(let error):
                return "Decryption failed: \(error?.localizedDescription ?? "Unknown error")"
            case .signingFailed(let error):
                return "Signing failed: \(error?.localizedDescription ?? "Unknown error")"
            case .signatureValidationFailed(let error):
                return "Signature validation failed: \(error.localizedDescription)"
            case .invalidMessageData:
                return "Invalid message data for encryption"
            case .invalidDecryptedData:
                return "Invalid decrypted data - unable to convert to string"
            }
        }
    }

    // MARK: - Key Generation
    // Generates a new RSA key pair.
    func generateKeyPair(keySize: Int) throws -> (publicKey: SecKey, privateKey: SecKey) {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: keySize,
            kSecAttrIsPermanent as String: false,
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw EncryptionError.keyGenerationFailed(error?.takeRetainedValue())
        }
        
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw EncryptionError.keyGenerationFailed(nil)
        }
        
        return (publicKey: publicKey, privateKey: privateKey)
    }
    
    // MARK: - Message Encryption
    // Encrypts a message using the provided public key.
    func encryptMessage(_ message: String, using publicKey: SecKey) throws -> Data {
        guard let messageData = message.data(using: .utf8) else {
            throw EncryptionError.invalidMessageData
        }
        
        var error: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(
            publicKey,
            .rsaEncryptionOAEPSHA256,
            messageData as CFData,
            &error
        ) else {
            throw EncryptionError.encryptionFailed(error?.takeRetainedValue())
        }
        
        return encryptedData as Data
    }
    
    // MARK: - Message Decryption
    // Decrypts encrypted data using the provided private key.
    func decryptMessage(_ encryptedData: Data, using privateKey: SecKey) throws -> String {
        var error: Unmanaged<CFError>?
        guard let decryptedData = SecKeyCreateDecryptedData(
            privateKey,
            .rsaEncryptionOAEPSHA256,
            encryptedData as CFData,
            &error
        ) else {
            throw EncryptionError.decryptionFailed(error?.takeRetainedValue())
        }
        
        guard let decryptedString = String(data: decryptedData as Data, encoding: .utf8) else {
            throw EncryptionError.invalidDecryptedData
        }
        
        return decryptedString
    }
    
    // MARK: - Message Signing
    // Signs encrypted data using the provided private key.
    func signEncryptedMessage(_ encryptedData: Data, using privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            encryptedData as CFData,
            &error
        ) else {
            throw EncryptionError.signingFailed(error?.takeRetainedValue())
        }
        
        return signature as Data
    }
    
    // MARK: - Signature Validation
    // Validates a signature for the given encrypted data and public key.
    func validateSignature(_ signature: Data, for encryptedData: Data, using publicKey: SecKey) throws -> Bool {
        var error: Unmanaged<CFError>?
        let isValid = SecKeyVerifySignature(
            publicKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            encryptedData as CFData,
            signature as CFData,
            &error
        )
        
        if let error = error {
            throw EncryptionError.signatureValidationFailed(error.takeRetainedValue())
        }
        
        return isValid
    }
}
