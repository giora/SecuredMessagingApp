//
//  SendMessage.swift
//  EncryptedMessagingApp
//
//  Created by giora krasilshchik on 15/07/2025.
//

import SwiftUI

// MARK: - Send Message View
// Main view for composing and sending encrypted messages.
struct SendMessageView: View {
    @ObservedObject private var viewModel: SendMessageViewModel

    // MARK: - Initialization
    // Initializes the view with a view model.
    init(viewModel: SendMessageViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Main View Body
    // Layout for message input, status, biometrics, and send button.
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)

                    Text("Encrypted Messaging")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top, 40)

                Spacer()

                // Message input section
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.headline)
                            .foregroundColor(.primary)

                        TextField(
                            "Type your message here...",
                            text: $viewModel.messageText
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(minHeight: 44)
                        .disabled(viewModel.isSending)
                    }

                    // Encryption Status Display
                    VStack(spacing: 8) {
                        HStack {
                            if viewModel.isSending {
                                ProgressView()
                            }
                            Text(encryptionStatusMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 4)

                    // Biometric toggle
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "faceid")
                                .foregroundColor(.blue)

                            Text("Biometric Authentication")
                                .font(.body)

                            Spacer()

                            Toggle("", isOn: $viewModel.isBiometricsEnabled)
                                .labelsHidden()
                                .disabled(viewModel.isSending)
                        }

                        Text(
                            "Enable biometric authentication for enhanced security"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)

                    // Send button
                    Button(action: {
                        viewModel.sendMessage()
                    }) {
                        HStack {
                            if viewModel.isSending {
                                ProgressView()
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }

                            Text(
                                viewModel.isSending
                                    ? "Sending..." : "Send Message")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            viewModel.canSendMessage ? Color.blue : Color.gray
                        )
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.canSendMessage)
                }
                .padding(.horizontal, 20)
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .navigationTitle("Send Message")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Computed Properties
    // Provides a status message for the encryption process.
    private var encryptionStatusMessage: String {
        switch viewModel.encryptionStatus {
        case .idle:
            return ""
        case .starting:
            return "Starting encryption..."
        case .creatingKeys:
            return "Creating encryption keys..."
        case .messageEncrypted:
            return "Message encrypted..."
        case .messageSigned:
            return "Message signed..."
        case .completed:
            return "Timer Set!"
        case .error:
            return "Error occurred"
        }
    }
}

#Preview {
    SendMessageView(viewModel: SendMessageViewModel())
}
