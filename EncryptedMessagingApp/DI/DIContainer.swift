//
//  DIContainer.swift
//  EncryptedMessagingApp
//
//  Created by giora krasilshchik on 16/07/2025.
//

import Foundation

// MARK: - Dependency Injection Container
// Manages object dependencies and lifecycles (factory and singleton patterns).
class DIContainer {
    static let shared = DIContainer()

    // Storage for factory closures (creates new instance each time)
    private var factories: [String: () -> Any] = [:]

    // Storage for singleton instances (cached instances)
    private var singletonInstances: [String: Any] = [:]

    private init() {}

    // MARK: - Registration Methods
    // Methods for registering factories and singletons.
    func registerFactory<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }

    func registerSingleton<T>(_ type: T.Type, _ singleton: T) {
        let key = String(describing: type)
        singletonInstances[key] = singleton
    }

    // MARK: - Resolution Methods
    // Methods for resolving dependencies by type.
    /// Resolve a dependency by type
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)

        // Check if it's a singleton instance first
        if let instance = singletonInstances[key] as? T {
            return instance
        }

        // Check if it's a factory
        if let factory = factories[key] {
            return factory() as? T
        }

        return nil
    }
}

// MARK: - Dependency Setup
// Configures and registers all application dependencies.
func setupDependencies() {
    let container = DIContainer.shared

    container.registerFactory(NotificationUtils.self) {
        LocalNotificationService()
    }

    container.registerSingleton(NotificationState.self, NotificationStateImpl())

    container.registerFactory(BiometricUtils.self) {
        BiometricUtilsImpl()
    }

    container.registerFactory(EncryptionService.self) {
        RSAEncryptionService()
    }

    container.registerSingleton(
        UserDefaultsUtils.self, UserDefaultsServiceImpl())
    container.registerSingleton(SecureStorage.self, KeyChainSecureStorage())

    container.registerSingleton(
        MessageRepository.self,
        MessageRepositoryImpl(
            secureStorage: container.resolve(SecureStorage.self)!,
            encryptionService: container.resolve(EncryptionService.self)!)
    )

    container.registerFactory(SendMessageUseCase.self) {
        SendMessageUseCaseImpl(
            notificationUtils: container.resolve(NotificationUtils.self)!,
            messageRepository: container.resolve(MessageRepository.self)!)
    }

    container.registerFactory(VerifyBiometricsUseCase.self) {
        VerifyBiometricsUseCaseImpl(
            biometricUtils: container.resolve(BiometricUtils.self)!,
            userDefaultsService: container.resolve(UserDefaultsUtils.self)!)
    }
}
