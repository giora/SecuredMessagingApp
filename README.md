# EncryptedMessagingApp

![Simulator Screen Recording - iPhone 16 - 2025-07-20 at 10 49 31](https://github.com/user-attachments/assets/95a772f3-25c9-4978-811a-759656f3a116)

A secure iOS messaging application built with Clean Architecture, featuring end-to-end RSA encryption and biometric authentication.

## Architecture Overview

This project follows **Clean Architecture** principles with clear separation of concerns across multiple layers:

```
┌─────────────────────────────────────────────┐
│                    UI Layer                 │
│  ┌─────────────┐  ┌─────────────────────────┤
│  │ Coordinator │  │ Views & ViewModels      │
│  └─────────────┘  └─────────────────────────┤
├─────────────────────────────────────────────┤
│                Use Cases Layer              │
│  ┌─────────────────────────────────────────┤
│  │ Business Logic                          │
│  └─────────────────────────────────────────┤
├─────────────────────────────────────────────┤
│              Data Access Layer              │
│  ┌─────────────┐  ┌─────────────────────────┤
│  │ Repositories│  │ Services                │
│  └─────────────┘  └─────────────────────────┤
├─────────────────────────────────────────────┤
│                Utilities Layer              │
│  ┌─────────────────────────────────────────┤
│  │ Cross-cutting Concerns & Helpers        │
│  └─────────────────────────────────────────┤
└─────────────────────────────────────────────┘
```

## Project Structure

### 🎯 **Coordinator**

Navigation and app flow management using the Coordinator pattern.

- **`AppCoordinator.swift`** - Main app navigation coordinator
- **`CoordinatorView.swift`** - SwiftUI coordinator integration
- **`NotificationState.swift`** - Global notification state management

**Responsibilities:**

- Screen navigation flow
- Dependency injection coordination
- App state management

### 🏗️ **Services**

Core system services providing low-level functionality.

- **`EncryptionService.swift`** - RSA encryption/decryption and digital signatures
- **`SecureStorageService.swift`** - Keychain and secure data storage

**Characteristics:**

- Protocol-based design for testability
- iOS Security framework integration

### 🗄️ **Repositories**

Data access layer implementing Repository pattern.

- **`MessageRepository.swift`** - Message encryption/decryption persistence and retrieval

**Responsibilities:**

- Data source abstraction
- Caching strategies
- Data transformation between layers

### 💼 **Use Cases**

Business logic and application-specific rules.

- **`SendMessageUseCase.swift`** - Message sending logic workflow
- **`VerifyBiometricsUseCase.swift`** - Biometric authentication workflow

**Characteristics:**

- Single responsibility per use case
- Orchestrates services and repositories

### 🎨 **UI Layer**

#### Views

SwiftUI views for user interface.

- **`SendMessageView.swift`** - Message composition interface
- **`DisplayMessageView.swift`** - Message display interface

#### ViewModels

MVVM pattern implementation with ObservableObject.

- **`SendMessageViewModel.swift`** - Send message business logic
- **`DisplayMessageViewModel.swift`** - Display message business logic

**Characteristics:**

- `@ObservableObject` for reactive UI
- Use case orchestration
- UI state management

### 🛠️ **Utils**

Cross-cutting concerns and helper utilities.

- **`BiometricUtils.swift`** - Biometric authentication helpers
- **`NotificationUtils.swift`** - Push notification utilities
- **`UserDefaultsUtils.swift`** - User preferences management

**Purpose:**

- Shared functionality
- Platform-specific implementations
- Common utilities across layers

### 🔧 **Dependency Injection**

Centralized dependency management.

- **`DIContainer.swift`** - Service registration and resolution

**Benefits:**

- Loose coupling between layers
- Easy testing and mocking
- Single source of truth for dependencies

## Data Flow

### Sending a Message

```
SendMessageView → SendMessageViewModel → SendMessageUseCase → EncryptionService
                                      ↓
MessageRepository ← SecureStorageService ← [Encrypted Message]
```

### Displaying Messages

```
DisplayMessageView → DisplayMessageViewModel → MessageRepository
                                           ↓
[Encrypted Message] → EncryptionService → [Decrypted Message] → UI
```

## Security Features

- **End-to-End Encryption**: RSA with OAEP padding
- **Digital Signatures**: Message authenticity verification
- **Biometric Authentication**: Face ID/Touch ID integration
- **Secure Storage**: iOS Keychain integration
- **Memory Safety**: Non-persistent key generation

## Key Design Principles

1. **Separation of Concerns** - Each layer has distinct responsibilities
2. **Dependency Inversion** - High-level modules don't depend on low-level modules
3. **Single Responsibility** - Each class has one reason to change
4. **Protocol-Oriented** - Interfaces over implementations
5. **Testability** - Dependencies can be easily mocked

## Technology Stack

- **SwiftUI** - Declarative UI framework
- **Combine** - Reactive programming
- **iOS Security Framework** - Cryptographic operations
- **LocalAuthentication** - Biometric authentication
- **Keychain Services** - Secure storage

## Getting Started

1. Clone the repository
2. Open `EncryptedMessagingApp.xcodeproj` in Xcode
3. Build and run the project
4. Ensure device supports biometric authentication for full functionality

Note: RSA can only encrypt data up to a certain size based on the key size and padding scheme.
With OAEP-SHA256 padding and a typical RSA key, you can only encrypt about 190 bytes directly.
For longer messages, we need to implement hybrid encryption - using AES for the message and RSA for the AES key.
But as I understood that wasn't part of the exercise
