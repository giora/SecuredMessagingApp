//
//  DisplayMessageView.swift
//  EncryptedMessagingApp
//
//  Created by giora krasilshchik on 16/07/2025.
//

import SwiftUI

// MARK: - Display Message View
// Main view for displaying decrypted messages and status.
struct DisplayMessageView: View {
    @ObservedObject private var viewModel: DisplayMessageViewModel

    // MARK: - Initialization
    init(viewModel: DisplayMessageViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Main View Body
    // Layout for displaying decrypted message, status, and actions.
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(viewModel.decryptedMessage)
                    .font(.body)
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )

                content
                Spacer()
                // Navigation and action buttons
                VStack(spacing: 12) {
                    // Navigation back to Send Message
                    Button(action: {
                        viewModel.onSendMessageAction()
                    }) {
                        HStack {
                            Image(systemName: "square.and.pencil")
                            Text("Send New Message")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - View Components
    // View builder for message status and error display.
    @ViewBuilder
    private var content: some View {
        switch viewModel.messageDecryptionState {
        case .initial:
            EmptyView()
        case .messageProccesing(let status):
            statusView(status: status)
        case .fail(let errorMessage):
            errorView(errorMessage: errorMessage)
        }
    }

    // MARK: - Status View
    // Displays the current status of message decryption.
    private func statusView(status: DisplayMessageViewModel.MessageStatus)
        -> some View
    {
        HStack {
            switch status {
            case .initial:
                ProgressView()
                Text("Verifying...")
            case .signatureVerified:
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
                Text("Signature Verified")
            case .messageDecrypted:
                Image(systemName: "lock.open.fill")
                    .foregroundColor(.green)
                Text("Message Decrypted")
            }
        }
        .font(.headline)
        .foregroundColor(.secondary)
    }

    // MARK: - Error View
    // Displays error messages and retry actions.
    private func errorView(errorMessage: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("Decryption Failed")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if errorMessage.contains("Biometric verification failed") {
                Button(action: {
                    viewModel.verifyAndLoadMessage()
                }) {
                    Text("Retry")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let viewModel = DisplayMessageViewModel(
        encryptedMessage: EncryptedMessage(
            encryptedData: Data(), signature: Data()))
    viewModel.decryptedMessage = "This is a decrypted message for preview."
    viewModel.messageDecryptionState = .messageProccesing(.messageDecrypted)

    return DisplayMessageView(viewModel: viewModel)
}
