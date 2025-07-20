//
//  SecureStorageService.swift
//  EncryptedMessagingApp
//
//  Created by giora krasilshchik on 15/07/2025.
//

import Foundation
import Security

// MARK: - Secure Storage Protocol
// Protocol for secure storage of cryptographic keys.
protocol SecureStorage {
    func storePrivateKey(_ key: SecKey, for identifier: String) throws
    func storePublicKey(_ key: SecKey, for identifier: String) throws
    func retrievePrivateKey(for identifier: String) throws -> SecKey
    func retrievePublicKey(for identifier: String) throws -> SecKey
}

// MARK: - Keychain Secure Storage Implementation
// Provides secure storage and retrieval of keys using iOS Keychain.
class KeyChainSecureStorage: SecureStorage {
    
    // MARK: - Secure Storage Error
    // Represents errors related to secure storage operations.
    enum SecureStorageError: Error {
        case keyNotFound
        case keychainError(OSStatus)
        
        var localizedDescription: String {
            switch self {
            case .keyNotFound:
                return "Key not found in keychain"
            case .keychainError(let status):
                return "Keychain error: \(status)"
            }
        }
    }
    
    private let keyClass = kSecClassKey
    
    // MARK: - Store Private Key
    // Stores a private key in the keychain.
    func storePrivateKey(_ key: SecKey, for identifier: String) throws {
        let tag = "\(identifier)_private".data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: keyClass,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecValueRef as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing key first
        let deleteQuery: [String: Any] = [
            kSecClass as String: keyClass,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw SecureStorageError.keychainError(status)
        }
    }
    
    // MARK: - Store Public Key
    // Stores a public key in the keychain.
    func storePublicKey(_ key: SecKey, for identifier: String) throws {
        let tag = "\(identifier)_public".data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: keyClass,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecValueRef as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing key first
        let deleteQuery: [String: Any] = [
            kSecClass as String: keyClass,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw SecureStorageError.keychainError(status)
        }
    }
    
    // MARK: - Retrieve Private Key
    // Retrieves a private key from the keychain.
    func retrievePrivateKey(for identifier: String) throws -> SecKey {
        let tag = "\(identifier)_private".data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: keyClass,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            throw SecureStorageError.keyNotFound
        }
        
        if status != errSecSuccess {
            throw SecureStorageError.keychainError(status)
        }
        
        return (result as! SecKey)
    }
    
    // MARK: - Retrieve Public Key
    // Retrieves a public key from the keychain.
    func retrievePublicKey(for identifier: String) throws -> SecKey {
        let tag = "\(identifier)_public".data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: keyClass,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            throw SecureStorageError.keyNotFound
        }
        
        if status != errSecSuccess {
            throw SecureStorageError.keychainError(status)
        }
        
        return (result as! SecKey)
    }
}
