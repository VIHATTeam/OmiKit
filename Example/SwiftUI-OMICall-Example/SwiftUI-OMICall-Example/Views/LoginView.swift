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

    // Toggle between SIP login and UUID login
    @State private var useUUIDLogin: Bool = false

    // SIP Login fields
    @State private var username: String = "100" // Please connect with Sale or Development team to get test account
    @State private var realm: String = "luuphuongmytrinh9a2"
    @State private var password: String = "iT2OjDYA0H"

    // UUID Login fields
    @State private var usrUuid: String = ""
    @State private var fullName: String = ""
    @State private var apiKey: String = ""
    @State private var phone: String = ""

    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoggedIn: Bool = false

    // Saved credentials - SIP
    @AppStorage("saved_username") private var savedUsername: String = ""
    @AppStorage("saved_realm") private var savedRealm: String = ""
    @AppStorage("saved_password") private var savedPassword: String = ""

    // Saved credentials - UUID
    @AppStorage("saved_uuid") private var savedUuid: String = ""
    @AppStorage("saved_fullname") private var savedFullName: String = ""
    @AppStorage("saved_apikey") private var savedApiKey: String = ""
    @AppStorage("saved_phone") private var savedPhone: String = ""
    @AppStorage("saved_use_uuid_login") private var savedUseUUIDLogin: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
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

                        Text(useUUIDLogin ? "Login with UUID & Phone" : "Login to your SIP account")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // Login Type Toggle
                    Toggle(isOn: $useUUIDLogin) {
                        HStack {
                            Image(systemName: useUUIDLogin ? "key.fill" : "person.fill")
                                .foregroundColor(.blue)
                            Text(useUUIDLogin ? "UUID Login" : "SIP Login")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 24)

                    // Input Fields
                    VStack(spacing: 16) {
                        if useUUIDLogin {
                            // UUID Login Fields
                            uuidLoginFields
                        } else {
                            // SIP Login Fields
                            sipLoginFields
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
                    Text(useUUIDLogin
                        ? "Enter your UUID and Phone credentials provided by your OMICall administrator"
                        : "Enter your SIP credentials provided by your OMICall administrator")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Spacer()
                }
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
                if savedUseUUIDLogin && hasSavedUUIDCredentials {
                    useUUIDLogin = true
                    usrUuid = savedUuid
                    fullName = savedFullName
                    apiKey = savedApiKey
                    phone = savedPhone
                    // Auto login
                    performLogin()
                } else if hasSavedSIPCredentials {
                    useUUIDLogin = false
                    username = savedUsername
                    realm = savedRealm
                    password = savedPassword
                    // Auto login
                    performLogin()
                }
            }
        }
    }

    // MARK: - SIP Login Fields View
    private var sipLoginFields: some View {
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
    }

    // MARK: - UUID Login Fields View
    private var uuidLoginFields: some View {
        VStack(spacing: 16) {
            // User UUID Field
            VStack(alignment: .leading, spacing: 6) {
                Text("User UUID")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Enter user UUID", text: $usrUuid)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }

            // Full Name Field (Optional)
            VStack(alignment: .leading, spacing: 6) {
                Text("Full Name (Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Enter display name", text: $fullName)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .autocorrectionDisabled()
            }

            // API Key Field
            VStack(alignment: .leading, spacing: 6) {
                Text("API Key")
                    .font(.caption)
                    .foregroundColor(.secondary)

                SecureField("Enter API key", text: $apiKey)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }

            // Phone Field
            VStack(alignment: .leading, spacing: 6) {
                Text("Phone Number")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Enter phone number", text: $phone)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.phonePad)
            }
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        if useUUIDLogin {
            return !usrUuid.isEmpty && !apiKey.isEmpty && !phone.isEmpty
        } else {
            return !username.isEmpty && !realm.isEmpty && !password.isEmpty
        }
    }

    private var hasSavedSIPCredentials: Bool {
        !savedUsername.isEmpty && !savedRealm.isEmpty && !savedPassword.isEmpty
    }

    private var hasSavedUUIDCredentials: Bool {
        !savedUuid.isEmpty && !savedApiKey.isEmpty && !savedPhone.isEmpty
    }

    // MARK: - Actions (Async/Await)

    private func performLogin() {
        isLoading = true

        Task {
            do {
                let success: Bool

                if useUUIDLogin {
                    // UUID Login
                    success = try await callManager.loginWithUUID(
                        usrUuid: usrUuid,
                        fullName: fullName.isEmpty ? nil : fullName,
                        apiKey: apiKey,
                        phone: phone
                    )
                } else {
                    // SIP Login
                    success = try await callManager.login(
                        username: username,
                        password: password,
                        realm: realm
                    )
                }

                // Handle success on main thread (already @MainActor)
                isLoading = false

                if success {
                    // Save credentials after successful login
                    if useUUIDLogin {
                        savedUuid = usrUuid
                        savedFullName = fullName
                        savedApiKey = apiKey
                        savedPhone = phone
                        savedUseUUIDLogin = true
                        // Clear SIP credentials
                        savedUsername = ""
                        savedRealm = ""
                        savedPassword = ""
                    } else {
                        savedUsername = username
                        savedRealm = realm
                        savedPassword = password
                        savedUseUUIDLogin = false
                        // Clear UUID credentials
                        savedUuid = ""
                        savedFullName = ""
                        savedApiKey = ""
                        savedPhone = ""
                    }
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
        // Clear SIP credentials
        UserDefaults.standard.removeObject(forKey: "saved_username")
        UserDefaults.standard.removeObject(forKey: "saved_realm")
        UserDefaults.standard.removeObject(forKey: "saved_password")
        // Clear UUID credentials
        UserDefaults.standard.removeObject(forKey: "saved_uuid")
        UserDefaults.standard.removeObject(forKey: "saved_fullname")
        UserDefaults.standard.removeObject(forKey: "saved_apikey")
        UserDefaults.standard.removeObject(forKey: "saved_phone")
        UserDefaults.standard.removeObject(forKey: "saved_use_uuid_login")
        UserDefaults.standard.synchronize() // Force immediate save
    }
}

#Preview {
    LoginView()
        .environmentObject(CallManagerV2.shared)
}
