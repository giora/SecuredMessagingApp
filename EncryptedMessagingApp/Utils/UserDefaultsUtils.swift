//
//  UserDefaultsService.swift
//  EncryptedMessagingApp
//
//  Created by giora krasilshchik on 17/07/2025.
//

import Foundation

// MARK: - User Defaults Service Key
// Keys for user preferences stored in UserDefaults.
struct UserDefaultsUtilsKey {
    static let isBiometricsEnabled = "isBiometricsEnabled"
}

// MARK: - User Defaults Service Protocol
// Protocol for managing user preferences in UserDefaults.
protocol UserDefaultsUtils {
    func setBool(_ value: Bool, forKey key: String)
    func getBool(forKey key: String) -> Bool
}

// MARK: - User Defaults Service Implementation
// Provides access to user preferences using UserDefaults.
class UserDefaultsServiceImpl: UserDefaultsUtils {

    // MARK: - Initialization
    private let userDefaults: UserDefaults

    init() {
        self.userDefaults = .standard
    }

    // MARK: - Public Methods
    func setBool(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func getBool(forKey key: String) -> Bool {
        return userDefaults.bool(forKey: key)
    }
}
