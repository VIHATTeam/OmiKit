//
//  LoginView.swift
//  SwiftUI-OMICall-Example
//
//  Created by H-Solutions on 9/1/26.
//

import OmiKit
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var callManager: CallManagerV2

    @State private var username: String = "100" // Please connect with Sale or Development team to get test account
    @State private var realm: String = "namplh"
    @State private var password: String = "Matkhau@2025"

    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoggedIn: Bool = false

    // Saved credentials
    @AppStorage("saved_username") private var savedUsername: String = ""
    @AppStorage("saved_realm") private var savedRealm: String = ""
    @AppStorage("saved_password") private var savedPassword: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Logo/Header
                VStack(spacing: 8) {
                    Image(systemName: "phone.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)

                    Text("OMICall")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Login to your SIP account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                // Input Fields
                VStack(spacing: 16) {
                    // Username Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Username (Extension)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("Enter SIP username", text: $username)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .textContentType(.username)
                    }

                    // Realm Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Realm (Domain)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("e.g., vh.omicrm.com", text: $realm)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                    }

                    // Password Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        SecureField("Enter SIP password", text: $password)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .textContentType(.password)
                    }
                }
                .padding(.horizontal, 24)

                // Login Button
                Button(action: performLogin) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "phone.arrow.right")
                            Text("Connect")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!isFormValid || isLoading)
                .padding(.horizontal, 24)

                // Info Text
                Text("Enter your SIP credentials provided by your OMICall administrator")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                CallingView()
            }
            .alert("Connection Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Check if has saved credentials - auto login
                if hasSavedCredentials {
                    username = savedUsername
                    realm = savedRealm
                    password = savedPassword
                    // Auto login
                    performLogin()
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !username.isEmpty && !realm.isEmpty && !password.isEmpty
    }

    private var hasSavedCredentials: Bool {
        !savedUsername.isEmpty && !savedRealm.isEmpty && !savedPassword.isEmpty
    }

    // MARK: - Actions (Async/Await)

    private func performLogin() {
        isLoading = true

        // Use CallManagerV2 to login via OmiKit with async/await
        Task {
            do {
                let success = try await callManager.login(
                    username: username,
                    password: password,
                    realm: realm
                )

                // Handle success on main thread (already @MainActor)
                isLoading = false

                if success {
                    // Save credentials after successful login
                    savedUsername = username
                    savedRealm = realm
                    savedPassword = password
                    isLoggedIn = true
                } else {
                    errorMessage = "Failed to connect. Please check your credentials and try again."
                    showError = true
                }
            } catch {
                // Handle error
                isLoading = false
                errorMessage = "Login failed: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    // MARK: - Static method to clear credentials
    static func clearSavedCredentials() {
        UserDefaults.standard.removeObject(forKey: "saved_username")
        UserDefaults.standard.removeObject(forKey: "saved_realm")
        UserDefaults.standard.removeObject(forKey: "saved_password")
    }
}

#Preview {
    LoginView()
        .environmentObject(CallManagerV2.shared)
}
