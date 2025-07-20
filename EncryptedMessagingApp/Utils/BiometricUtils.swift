//
//  BiometricService.swift
//  EncryptedMessagingApp
//
//  Created by giora krasilshchik on 17/07/2025.
//

import Foundation
import LocalAuthentication

// MARK: - Biometric Authentication Result
// Represents the result of a biometric authentication attempt.
enum BiometricAuthResult {
    case success
    case failure(String)
}

// MARK: - Biometric Service Protocol
// Protocol for biometric authentication service abstraction.
protocol BiometricUtils {
    func authenticate() async -> BiometricAuthResult
}

// MARK: - Biometric Service Implementation
// Provides biometric authentication using LocalAuthentication framework.
class BiometricUtilsImpl: BiometricUtils {

    // MARK: - Authentication Method
    // Performs biometric authentication and returns the result.
    func authenticate() async -> BiometricAuthResult {
        let context = LAContext()

        var error: NSError?
        // First check if any secure auth (biometric or passcode) is possible
        guard
            context.canEvaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics, error: &error)
        else {
            return .failure(
                error?.localizedDescription ?? "Authentication not available")
        }

        let reason = "Authenticate using Face ID, Touch ID, or device passcode"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication, localizedReason: reason)
            return success ? .success : .failure("Authentication failed")
        } catch {
            return .failure(error.localizedDescription)
        }
    }
}
