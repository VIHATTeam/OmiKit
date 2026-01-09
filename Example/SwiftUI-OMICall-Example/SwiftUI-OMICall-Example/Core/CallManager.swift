//
//  CallManager.swift
//  SwiftUI-OMICall-Example
//
//  Created by H-Solutions on 9/1/26.
//

import Combine
import Foundation
import OmiKit
import SwiftUI

// MARK: - Call Manager Singleton
class CallManager: ObservableObject {

    static let shared = CallManager()

    // MARK: - Published Properties
    @Published var currentCall: OmiCallModel?
    @Published var callState: CallStateStatus = .null
    @Published var isLoggedIn: Bool = false
    @Published var isMuted: Bool = false
    @Published var isSpeakerOn: Bool = false
    @Published var isOnHold: Bool = false
    @Published var callDuration: Int = 0

    // MARK: - Incoming Call Properties
    @Published var hasIncomingCall: Bool = false
    @Published var hasActiveCall: Bool = false
    @Published var incomingCallerNumber: String = ""
    @Published var incomingCallerName: String = ""
    @Published var isIncomingVideoCall: Bool = false

    // MARK: - OmiKit References
    var omiSIPLib: OMISIPLib {
        return OMISIPLib.sharedInstance()
    }

    // MARK: - Timer
    private var callTimer: Timer?

    private init() {}

    // MARK: - SDK Configuration

    /// Set log level for SDK (1-5)
    /// 1 - OMILogVerbose, 2 - OMILogDebug, 3 - OMILogInfo, 4 - OMILogWarning, 5 - OMILogError
    func setLogLevel(_ level: Int = 2) {
        OmiClient.setLogLevel(Int32(level))
    }

    /// Configure SDK environment
    func configureSDK() {
        // Set environment: "dev" or "prod"
        
#if DEBUG
        OmiClient.setEnviroment(
            KEY_OMI_APP_ENVIROMENT_SANDBOX,
            userNameKey: "full_name",
            maxCall: 1,
            callKitImage: "call_image",
            typePushVoip: TYPE_PUSH_CALLKIT_DEFAULT
        )
#else
        OmiClient.setEnviroment(
            KEY_OMI_APP_ENVIROMENT_PRODUCTION,
            userNameKey: "full_name",
            maxCall: 1,
            callKitImage: "call_image",
            typePushVoip: TYPE_PUSH_CALLKIT_DEFAULT
        )
#endif
        
    }

    // MARK: - Authentication

    /// Initialize SIP connection with credentials
    func login(username: String, password: String, realm: String, completion: @escaping (Bool) -> Void) {
        // Build proxy from realm
        let proxy = realm + ":5222"

        OmiClient.initWithUsername(
            username,
            password: password,
            realm: realm,
            proxy: proxy
        )

        // Configure decline call behavior
        OmiClient.configureDeclineCallBehavior(true)

        // Store login state
        DispatchQueue.main.async {
            self.isLoggedIn = true
        }

        completion(true)
    }

    /// Logout from SIP
    func logout() {
        OmiClient.logout()
        DispatchQueue.main.async {
            self.isLoggedIn = false
            self.currentCall = nil
            self.callState = .null
        }
    }

    // MARK: - Call Operations

    /// Start an outgoing call
    func startCall(to phoneNumber: String, isVideo: Bool = false, completion: @escaping (OMIStartCallStatus) -> Void) {
        OmiClient.startCall(phoneNumber, isVideo: isVideo) { status in
            DispatchQueue.main.async {
                switch status {
                case .startCallSuccess:
                    // Call started successfully
                    break
                default:
                    break
                }
                completion(status)
            }
        }
    }

    /// End current call
    func endCall(completion: @escaping (Bool) -> Void) {
        guard let call = omiSIPLib.getCurrentCall() else {
            completion(false)
            return
        }

        if call.callState != .disconnected {
            omiSIPLib.callManager.end(call) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        print("Error ending call: \(error!)")
                        completion(false)
                    } else {
                        self.stopCallTimer()
                        completion(true)
                    }
                }
            }
        } else {
            completion(true)
        }
    }

    /// Toggle mute
    func toggleMute(completion: @escaping (Bool) -> Void) {
        guard let call = omiSIPLib.getCurrentCall() else {
            completion(false)
            return
        }

        omiSIPLib.callManager.toggleMute(for: call) { error in
            DispatchQueue.main.async {
                if error == nil {
                    self.isMuted.toggle()
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }

    /// Toggle hold
    func toggleHold(completion: @escaping (Bool) -> Void) {
        guard let call = omiSIPLib.getCurrentCall() else {
            completion(false)
            return
        }

        omiSIPLib.callManager.toggleHold(for: call) { error in
            DispatchQueue.main.async {
                if error == nil {
                    self.isOnHold.toggle()
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }

    /// Toggle speaker
    func toggleSpeaker() {
        omiSIPLib.callManager.audioController.output =
            omiSIPLib.callManager.audioController.output == .speaker ? .other : .speaker

        // Ensure UI update on main thread
        if Thread.isMainThread {
            self.isSpeakerOn.toggle()
        } else {
            DispatchQueue.main.async {
                self.isSpeakerOn.toggle()
            }
        }
    }

    /// Send DTMF tone
    func sendDTMF(_ digit: String) {
        guard let call = omiSIPLib.getCurrentCall(),
              call.callState == .confirmed else {
            return
        }

        do {
            try call.sendDTMF(digit)
        } catch {
            print("Error sending DTMF: \(error)")
        }
    }

    /// Transfer call
    func transferCall(to phoneNumber: String) {
        guard let call = omiSIPLib.getCurrentCall() else {
            return
        }

        do {
            try call.blindTransferCall(withNumber: phoneNumber)
        } catch {
            print("Error transferring call: \(error)")
        }
    }

    // MARK: - Call Timer

    func startCallTimer() {
        // Ensure we're on main thread for timer scheduling
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.startCallTimer()
            }
            return
        }

        callDuration = 0
        callTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.callDuration += 1
        }
    }

    func stopCallTimer() {
        // Ensure we're on main thread for timer invalidation
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.stopCallTimer()
            }
            return
        }

        callTimer?.invalidate()
        callTimer = nil
    }

    // MARK: - Call State Processing

    func processCallStateChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let callStateRaw = userInfo[OMINotificationUserInfoCallStateKey] as? Int,
              let newState = CallStateStatus(rawValue: callStateRaw) else {
            return
        }

        // Extract call info before dispatching to main thread
        var callModel: OmiCallModel?
        var isIncoming = false
        var callerNumber = ""
        var callerName = ""
        var isVideo = false

        if let omiCall = userInfo[OMINotificationUserInfoCallKey] as? OMICall {
            callModel = OmiCallModel(from: omiCall)
            isIncoming = omiCall.isIncoming
            callerNumber = omiCall.callerNumber ?? ""
            callerName = omiCall.callerName ?? ""
            isVideo = omiCall.isVideo
        }

        // All UI updates on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Update call model
            if let model = callModel {
                self.currentCall = model

                // Update incoming call info
                if isIncoming {
                    self.incomingCallerNumber = callerNumber
                    self.incomingCallerName = callerName
                    self.isIncomingVideoCall = isVideo
                }
            }

            // Update call state
            self.callState = newState

            switch newState {
            case .incoming:
                // Incoming call - set flag (CallKit will handle UI)
                self.hasIncomingCall = true
                self.hasActiveCall = false
            case .confirmed:
                // Call connected - start timer and set active
                self.hasActiveCall = true
                self.hasIncomingCall = false
                self.startCallTimer()
            case .disconnected:
                // Call ended - stop timer and reset
                self.stopCallTimer()
                self.resetCallState()
            case .calling, .early, .connecting:
                // Outgoing call in progress
                self.hasActiveCall = true
                self.hasIncomingCall = false
            default:
                break
            }
        }
    }

    /// Handle incoming call accepted from CallKit
    func handleIncomingCallAccepted() {
        DispatchQueue.main.async {
            self.hasActiveCall = true
            self.hasIncomingCall = false
        }
    }

    private func resetCallState() {
        // Ensure all @Published updates happen on main thread
        let reset = {
            self.isMuted = false
            self.isSpeakerOn = false
            self.isOnHold = false
            self.callDuration = 0
            self.hasActiveCall = false
            self.hasIncomingCall = false
            self.incomingCallerNumber = ""
            self.incomingCallerName = ""
            self.isIncomingVideoCall = false
            self.currentCall = nil
        }

        if Thread.isMainThread {
            reset()
        } else {
            DispatchQueue.main.async {
                reset()
            }
        }
    }

    // MARK: - Utilities

    func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    /// Get audio output devices
    func getAudioOutputs() -> [[String: String]] {
        return OmiClient.getAudioInDevices()
    }

    /// Set audio output
    func setAudioOutput(_ portType: String) {
        OmiClient.setAudioOutputs(portType)
    }

    /// Close call when app is killed
    func closeCallOnAppTerminate() {
        OmiClient.omiCloseCall()
    }

    /// Set push notification token
    func setPushToken(_ token: String) {
        OmiClient.setUserPushNotificationToken(token)
    }
}

// MARK: - OmiCallModel
struct OmiCallModel: Hashable {
    var callId: Int
    var incoming: Bool = false
    var callState: CallStateStatus = .null
    var callerNumber: String = ""
    var isVideo: Bool = false
    var omiId: String = ""
    var uuid: String = UUID().uuidString
    var callerName: String = ""
    var muted: Bool = false
    var speaker: Bool = false
    var onHold: Bool = false
    var numberToCall: String = ""
    var connected: Bool = false

    init(from omiCall: OMICall) {
        self.callId = omiCall.callId
        self.incoming = omiCall.isIncoming
        self.callState = CallStateStatus(rawValue: omiCall.callState.rawValue) ?? .null
        if let callNumber = omiCall.callerNumber, !callNumber.isEmpty {
            self.callerNumber = callNumber
        }
        self.isVideo = omiCall.isVideo
        self.omiId = omiCall.omiId ?? ""
        self.uuid = omiCall.uuid.uuidString
        self.callerName = omiCall.callerName ?? ""
        self.muted = omiCall.muted
        self.speaker = omiCall.speaker
        self.onHold = omiCall.onHold
        self.numberToCall = omiCall.numberToCall ?? ""
        self.connected = omiCall.connected
    }

    // Simple initializer for outgoing calls
    init(phoneNumber: String, isVideo: Bool = false) {
        self.callId = 0
        self.incoming = false
        self.numberToCall = phoneNumber
        self.isVideo = isVideo
    }
}

// MARK: - CallStateStatus Enum
enum CallStateStatus: Int {
    case null = 0
    case calling = 1
    case incoming = 2
    case early = 3
    case connecting = 4
    case confirmed = 5
    case disconnected = 6
    case hold = 7
    case disconnecting = 12

    var displayText: String {
        switch self {
        case .null: return "Idle"
        case .calling: return "Calling..."
        case .incoming: return "Incoming..."
        case .early: return "Ringing..."
        case .connecting: return "Connecting..."
        case .confirmed: return "Connected"
        case .disconnected: return "Disconnected"
        case .hold: return "On Hold"
        case .disconnecting: return "Ending..."
        }
    }
}

// MARK: - Call Direction
enum CallDirection {
    case incoming
    case outgoing
}
