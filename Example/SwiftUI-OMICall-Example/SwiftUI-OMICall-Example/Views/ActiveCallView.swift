//
//  ActiveCallView.swift
//  SwiftUI-OMICall-Example
//
//  Created by H-Solutions on 9/1/26.
//

import AVFoundation
import OmiKit
import SwiftUI

struct ActiveCallView: View {
    let phoneNumber: String
    let isVideo: Bool
    @Binding var isPresented: Bool

    @EnvironmentObject var callManager: CallManager

    @State private var callState: CallStateStatus = .calling
    @State private var showKeypad: Bool = false
    @State private var showTransfer: Bool = false
    @State private var transferNumber: String = ""

    // Network quality tracking
    @State private var networkQuality: Float = 5.0
    @State private var networkQualityColor: Color = .green

    // Audio route
    @State private var currentAudioRoute: String = "Receiver"

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            VStack(spacing: 0) {
                // Top Section - Caller Info
                callerInfoSection

                // Middle Section - Controls or Keypad
                if showKeypad {
                    dtmfKeypadSection
                } else {
                    callControlsSection
                }

                Spacer()

                // Bottom Section - End Call
                endCallSection
            }
        }
        .onAppear {
            setupCallStateObserver()
        }
        .onDisappear {
            removeObservers()
        }
        // Listen for call state changes from OmiKit SDK
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.OMICallStateChanged)) { notification in
            handleOMICallStateChange(notification)
        }
        // Listen for custom call state changes
        .onReceive(NotificationCenter.default.publisher(for: .callStateDidChange)) { notification in
            handleCallStateChange(notification)
        }
        // Listen for call ended
        .onReceive(NotificationCenter.default.publisher(for: .callDidEnd)) { _ in
            // Call ended - dismiss view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPresented = false
            }
        }
        // Listen for network quality updates from OmiKit SDK
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.OMICallNetworkQuality)) { notification in
            handleNetworkQualityUpdate(notification)
        }
        // Listen for audio route changes from OmiKit SDK
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.OMICallAudioRouteChange)) { notification in
            handleAudioRouteChange(notification)
        }
        // Listen for video info updates (if video call)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.OMICallVideoInfo)) { notification in
            handleVideoInfoUpdate(notification)
        }
        .sheet(isPresented: $showTransfer) {
            transferCallSheet
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Caller Info Section

    private var callerInfoSection: some View {
        VStack(spacing: 12) {
            Spacer()
                .frame(height: 60)

            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: isVideo ? "video.fill" : "person.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }

            // Phone Number
            Text(phoneNumber)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.primary)

            // Call Status
            HStack(spacing: 8) {
                if callState == .calling || callState == .connecting || callState == .early {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                Text(callStatusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Network Quality Indicator (only when connected)
            if callState == .confirmed {
                networkQualityIndicator
            }

            Spacer()
        }
    }

    // MARK: - Network Quality Indicator

    private var networkQualityIndicator: some View {
        HStack(spacing: 4) {
            // Signal bars
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < Int(networkQuality) ? networkQualityColor : Color.gray.opacity(0.3))
                    .frame(width: 4, height: CGFloat(6 + index * 3))
            }

            Text(networkQualityText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var networkQualityText: String {
        switch networkQuality {
        case 4.0...: return "Excellent"
        case 3.0..<4.0: return "Good"
        case 2.0..<3.0: return "Fair"
        default: return "Poor"
        }
    }

    // MARK: - Call Status Text

    private var callStatusText: String {
        switch callState {
        case .calling:
            return "Calling..."
        case .early:
            return "Ringing..."
        case .connecting:
            return "Connecting..."
        case .confirmed:
            return callManager.formatDuration(callManager.callDuration)
        case .hold:
            return "On Hold - \(callManager.formatDuration(callManager.callDuration))"
        case .disconnected, .disconnecting:
            return "Call Ended"
        default:
            return callState.displayText
        }
    }

    // MARK: - Call Controls Section

    private var callControlsSection: some View {
        VStack(spacing: 24) {
            // First row of controls
            HStack(spacing: 40) {
                CallControlButton(
                    icon: callManager.isMuted ? "mic.slash.fill" : "mic.fill",
                    label: "Mute",
                    isActive: callManager.isMuted,
                    isEnabled: isCallConnected
                ) {
                    callManager.toggleMute { _ in }
                }

                CallControlButton(
                    icon: "circle.grid.3x3.fill",
                    label: "Keypad",
                    isActive: false,
                    isEnabled: isCallConnected
                ) {
                    showKeypad = true
                }

                CallControlButton(
                    icon: callManager.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill",
                    label: "Speaker",
                    isActive: callManager.isSpeakerOn,
                    isEnabled: true
                ) {
                    callManager.toggleSpeaker()
                }
            }

            // Second row of controls
            HStack(spacing: 40) {
                CallControlButton(
                    icon: "arrow.right.arrow.left",
                    label: "Transfer",
                    isActive: false,
                    isEnabled: isCallConnected
                ) {
                    showTransfer = true
                }

                CallControlButton(
                    icon: callManager.isOnHold ? "play.fill" : "pause.fill",
                    label: callManager.isOnHold ? "Resume" : "Hold",
                    isActive: callManager.isOnHold,
                    isEnabled: isCallConnected
                ) {
                    callManager.toggleHold { _ in }
                }

                // Placeholder for video toggle (if video call)
                if isVideo {
                    CallControlButton(
                        icon: "video.fill",
                        label: "Camera",
                        isActive: false,
                        isEnabled: isCallConnected
                    ) {
                        // Toggle camera
                    }
                } else {
                    // Empty placeholder
                    Color.clear
                        .frame(width: 60, height: 80)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - DTMF Keypad Section

    private var dtmfKeypadSection: some View {
        VStack(spacing: 8) {
            Button(action: { showKeypad = false }) {
                Text("Hide Keypad")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 8)

            DTMFKeypadView { digit in
                callManager.sendDTMF(digit)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - End Call Section

    private var endCallSection: some View {
        Button(action: endCall) {
            VStack(spacing: 8) {
                Image(systemName: "phone.down.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 70, height: 70)
                    .background(Color.red)
                    .clipShape(Circle())

                Text("End Call")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 50)
    }

    // MARK: - Transfer Call Sheet

    private var transferCallSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Enter phone number to transfer", text: $transferNumber)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.phonePad)
                    .padding()

                Button(action: performTransfer) {
                    Text("Transfer Call")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(transferNumber.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(transferNumber.isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Transfer Call")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showTransfer = false
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var isCallConnected: Bool {
        callState == .confirmed
    }

    // MARK: - Actions

    private func setupCallStateObserver() {
        // Initial state is calling for outgoing calls
        if callManager.callState != .null {
            callState = callManager.callState
        }
    }

    private func removeObservers() {
        // Cleanup if needed
    }

    private func handleCallStateChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let stateRaw = userInfo[OMINotificationUserInfoCallStateKey] as? Int,
              let newState = CallStateStatus(rawValue: stateRaw) else {
            return
        }

        DispatchQueue.main.async {
            callState = newState

            if newState == .disconnected {
                // Call ended - dismiss after brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isPresented = false
                }
            }
        }
    }

    /// Handle direct call state changes from OmiKit SDK
    private func handleOMICallStateChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let stateRaw = userInfo[OMINotificationUserInfoCallStateKey] as? Int,
              let newState = CallStateStatus(rawValue: stateRaw) else {
            return
        }

        // Extract call info if available
        if let omiCall = userInfo[OMINotificationUserInfoCallKey] as? OMICall {
            print("Call state changed: \(newState.displayText), isVideo: \(omiCall.isVideo), incoming: \(omiCall.isIncoming)")
        }

        DispatchQueue.main.async {
            self.callState = newState

            switch newState {
            case .calling:
                print("📞 Outgoing call initiated")
            case .incoming:
                print("📞 Incoming call received")
            case .early:
                print("📞 Call ringing")
            case .connecting:
                print("📞 Call connecting")
            case .confirmed:
                print("📞 Call connected")
            case .hold:
                print("📞 Call on hold")
            case .disconnected:
                print("📞 Call disconnected")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isPresented = false
                }
            default:
                break
            }
        }
    }

    /// Handle network quality updates from OmiKit SDK (MOS score)
    private func handleNetworkQualityUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else { return }

        // Get MOS (Mean Opinion Score) - ranges from 1.0 (poor) to 5.0 (excellent)
        if let mos = userInfo[OMINotificationMOSKey] as? Float {
            DispatchQueue.main.async {
                self.networkQuality = mos

                // Update color based on quality
                switch mos {
                case 4.0...:
                    self.networkQualityColor = .green
                case 3.0..<4.0:
                    self.networkQualityColor = .yellow
                case 2.0..<3.0:
                    self.networkQualityColor = .orange
                default:
                    self.networkQualityColor = .red
                }
            }
        }

        // Optional: Log additional network stats
        if let jitter = userInfo[OMINotificationJitterKey] as? Float {
            print("📶 Jitter: \(jitter)ms")
        }
        if let latency = userInfo[OMINotificationLatencyKey] as? Float {
            print("📶 Latency: \(latency)ms")
        }
        if let ppl = userInfo[OMINotificationPPLKey] as? Float {
            print("📶 Packet Loss: \(ppl)%")
        }
    }

    /// Handle audio route changes from OmiKit SDK
    private func handleAudioRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any],
              let audioRoute = userInfo["type"] as? String else { return }

        DispatchQueue.main.async {
            self.currentAudioRoute = audioRoute

            // Update speaker state based on audio route
            switch audioRoute {
            case "Speaker":
                if !callManager.isSpeakerOn {
                    callManager.isSpeakerOn = true
                }
            case "Receiver", "Bluetooth", "Headphones":
                if callManager.isSpeakerOn {
                    callManager.isSpeakerOn = false
                }
            default:
                break
            }

            print("🔊 Audio route changed to: \(audioRoute)")
        }
    }

    /// Handle video info updates from OmiKit SDK (for video calls)
    private func handleVideoInfoUpdate(_ notification: Notification) {
        guard isVideo else { return }

        if let userInfo = notification.userInfo as? [String: Any] {
            print("📹 Video info updated: \(userInfo)")
            // Handle video-specific updates here
            // e.g., remote video started/stopped, camera switched, etc.
        }
    }

    private func endCall() {
        callManager.endCall { success in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isPresented = false
                }
            }
        }
    }

    private func performTransfer() {
        guard !transferNumber.isEmpty else { return }
        callManager.transferCall(to: transferNumber)
        showTransfer = false
    }
}

// MARK: - Call Control Button

struct CallControlButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isActive ? .white : (isEnabled ? .primary : .gray))
                    .frame(width: 60, height: 60)
                    .background(isActive ? Color.blue : Color(.systemGray5))
                    .clipShape(Circle())
                    .opacity(isEnabled ? 1.0 : 0.5)

                Text(label)
                    .font(.caption)
                    .foregroundColor(isEnabled ? .secondary : .gray)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - DTMF Keypad View

struct DTMFKeypadView: View {
    let onDigitPressed: (String) -> Void

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["*", "0", "#"]
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 20) {
                    ForEach(row, id: \.self) { digit in
                        Button(action: {
                            onDigitPressed(digit)
                            // Haptic feedback
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }) {
                            Text(digit)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 60, height: 60)
                                .background(Color(.systemGray5))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview("Active Call") {
    ActiveCallView(
        phoneNumber: "0123456789",
        isVideo: false,
        isPresented: .constant(true)
    )
    .environmentObject(CallManager.shared)
}

#Preview("Video Call") {
    ActiveCallView(
        phoneNumber: "0987654321",
        isVideo: true,
        isPresented: .constant(true)
    )
    .environmentObject(CallManager.shared)
}
