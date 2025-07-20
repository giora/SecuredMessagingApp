//
//  VerifyBiometricsUseCase.swift
//  EncryptedMessagingApp
//
//  Created by giora krasilshchik on 18/07/2025.
//

import Foundation

// MARK: - Verification Result
// Represents the result of a biometric verification attempt.
enum VerificationResult {
    case success
    case failure(String)
}

// MARK: - Verify Biometrics Use Case Protocol
// Protocol for verifying biometric authentication based on user settings.
protocol VerifyBiometricsUseCase {
    func execute() async -> VerificationResult
}

// MARK: - Verify Biometrics Use Case Implementation
// Handles biometric verification logic using user settings and biometric service.
class VerifyBiometricsUseCaseImpl: VerifyBiometricsUseCase {

    // MARK: - Properties
    private let biometricUtils: BiometricUtils
    private let userDefaultsUtils: UserDefaultsUtils

    // MARK: - Initialization
    init(
        biometricUtils: BiometricUtils, userDefaultsService: UserDefaultsUtils
    ) {
        self.biometricUtils = biometricUtils
        self.userDefaultsUtils = userDefaultsService
    }

    // MARK: - Public Methods
    // Executes the biometric verification use case.
    func execute() async -> VerificationResult {
        let isBiometricsEnabled = userDefaultsUtils.getBool(
            forKey: UserDefaultsUtilsKey.isBiometricsEnabled)

        if isBiometricsEnabled {
            let result = await biometricUtils.authenticate()
            switch result {
            case .success:
                return .success
            case .failure(let error):
                return .failure(error)
            }
        } else {
            return .success
        }
    }
}
