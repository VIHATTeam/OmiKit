//
//  CallingView.swift
//  SwiftUI-OMICall-Example
//
//  Created by H-Solutions on 9/1/26.
//

import AVFoundation
import OmiKit
import SwiftUI

struct CallingView: View {
    @EnvironmentObject var callManager: CallManagerV2
    @Environment(\.dismiss) private var dismiss

    @State private var phoneNumber: String = "0398627673"
    @State private var isCallActive: Bool = false
    @State private var isVideoCall: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var showLogoutConfirmation: Bool = false

    // Get saved username for display
    @AppStorage("saved_username") private var savedUsername: String = ""

    // Dialpad digits
    private let dialpadRows: [[DialpadButton]] = [
        [.init(digit: "1", letters: ""), .init(digit: "2", letters: "ABC"), .init(digit: "3", letters: "DEF")],
        [.init(digit: "4", letters: "GHI"), .init(digit: "5", letters: "JKL"), .init(digit: "6", letters: "MNO")],
        [.init(digit: "7", letters: "PQRS"), .init(digit: "8", letters: "TUV"), .init(digit: "9", letters: "WXYZ")],
        [.init(digit: "*", letters: ""), .init(digit: "0", letters: "+"), .init(digit: "#", letters: "")]
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Connection Status with Username
            VStack(spacing: 4) {
                HStack {
                    Circle()
                        .fill(callManager.isLoggedIn ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    Text(callManager.isLoggedIn ? "Connected" : "Disconnected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !savedUsername.isEmpty {
                    Text("Logged in as: \(savedUsername)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.top, 10)

            // Phone Number Display
            VStack(spacing: 8) {
                Text(phoneNumber.isEmpty ? "Enter phone number" : phoneNumber)
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(phoneNumber.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(height: 44)

                if !phoneNumber.isEmpty {
                    Button(action: clearPhoneNumber) {
                        Text("Clear")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.top, 10)

            Spacer()

            // Dialpad
            VStack(spacing: 16) {
                ForEach(dialpadRows, id: \.self) { row in
                    HStack(spacing: 24) {
                        ForEach(row, id: \.digit) { button in
                            DialpadButtonView(button: button) {
                                appendDigit(button.digit)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Action Buttons
            HStack(spacing: 30) {
                // Delete Button
                Button(action: deleteLastDigit) {
                    Image(systemName: "delete.left.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(width: 60, height: 60)
                }
                .opacity(phoneNumber.isEmpty ? 0 : 1)

                // Audio Call Button
                Button(action: { makeCall(isVideo: false) }) {
                    VStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(canMakeCall ? Color.green : Color.gray)
                            .clipShape(Circle())

                        Text("Audio")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(!canMakeCall || isLoading)

                // Video Call Button
                Button(action: { makeCall(isVideo: true) }) {
                    VStack(spacing: 4) {
                        Image(systemName: "video.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(canMakeCall ? Color.blue : Color.gray)
                            .clipShape(Circle())

                        Text("Video")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(!canMakeCall || isLoading)

                // Placeholder for symmetry
                Color.clear
                    .frame(width: 60, height: 60)
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Dialer")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: logout) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Call Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Logout", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("Are you sure you want to logout? Your saved credentials will be cleared.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .callDidEndV2)) { notification in
            // Handle call end with error message if any
            isLoading = false
            if let message = notification.userInfo?["message"] as? String,
               message != "Call Ended" {
                errorMessage = message
                showError = true
            }
        }
        .onChange(of: callManager.hasActiveCall) { hasActive in
            // Reset loading state when call state changes
            if hasActive {
                isLoading = false
            }
        }
        .overlay {
            if isLoading {
                ProgressView("Calling...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
    }

    // MARK: - Computed Properties

    private var canMakeCall: Bool {
        !phoneNumber.isEmpty && callManager.isLoggedIn
    }

    // MARK: - Actions

    private func appendDigit(_ digit: String) {
        guard phoneNumber.count < 15 else { return }
        phoneNumber += digit

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    private func deleteLastDigit() {
        guard !phoneNumber.isEmpty else { return }
        phoneNumber.removeLast()
    }

    private func clearPhoneNumber() {
        phoneNumber = ""
    }

    private func makeCall(isVideo: Bool) {
        guard canMakeCall else { return }

        isVideoCall = isVideo

        // Request permissions before making call using async/await
        Task {
            let granted = await requestPermissions(forVideo: isVideo)

            guard granted else {
                if isVideo {
                    errorMessage = "Microphone and Camera permissions are required for video calls. Please enable them in Settings."
                } else {
                    errorMessage = "Microphone permission is required for calls. Please enable it in Settings."
                }
                showError = true
                return
            }

            // Permissions granted, proceed with call
            isLoading = true

            do {
                // Use CallManagerV2 to start call via OmiKit with async/await
                let status = try await callManager.startCall(to: phoneNumber, isVideo: isVideo)

                isLoading = false

                // Call started successfully - navigate to ActiveCallView immediately
                isCallActive = true

                // Post notification to show ActiveCallView immediately
                NotificationCenter.default.post(
                    name: .outgoingCallStartedV2,
                    object: nil,
                    userInfo: ["phoneNumber": self.phoneNumber, "isVideo": isVideo]
                )
            } catch let error as CallManagerError {
                isLoading = false

                switch error {
                case .callStartFailed(let status):
                    switch status {
                    case .invalidPhoneNumber:
                        errorMessage = "Invalid phone number"
                    case .samePhoneNumber:
                        errorMessage = "Cannot call your own number"
                    case .permissionDenied:
                        errorMessage = "Microphone permission denied. Please enable it in Settings."
                    case .couldNotFindEndpoint:
                        errorMessage = "Connection error. Please login again."
                    case .accountRegisterFailed:
                        errorMessage = "Account not registered. Please login again."
                    case .haveAnotherCall:
                        errorMessage = "Another call is in progress"
                    case .maxRetry:
                        errorMessage = "Maximum retry attempts reached"
                    default:
                        errorMessage = "Failed to start call"
                    }
                default:
                    errorMessage = error.localizedDescription
                }
                showError = true
            } catch {
                isLoading = false
                errorMessage = "Failed to start call: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    // MARK: - Permission Handling (Async/Await)

    private func requestPermissions(forVideo: Bool) async -> Bool {
        // Check and request microphone permission
        let micGranted = await requestMicrophonePermission()
        guard micGranted else { return false }

        if forVideo {
            // Also request camera permission for video calls
            let camGranted = await requestCameraPermission()
            return camGranted
        }

        return true
    }

    private func requestMicrophonePermission() async -> Bool {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }

    private func requestCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        @unknown default:
            return false
        }
    }

    private func logout() {
        showLogoutConfirmation = true
    }

    private func performLogout() {
        // Clear saved credentials
        LoginView.clearSavedCredentials()

        // Logout from OmiKit
        callManager.logout()

        // Navigate back to login
        dismiss()
    }
}

// MARK: - Supporting Types

struct DialpadButton: Hashable {
    let digit: String
    let letters: String
}

struct DialpadButtonView: View {
    let button: DialpadButton
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(button.digit)
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.primary)

                if !button.letters.isEmpty {
                    Text(button.letters)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80, height: 80)
            .background(Color(.systemGray6))
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CallingView()
            .environmentObject(CallManagerV2.shared)
    }
}
