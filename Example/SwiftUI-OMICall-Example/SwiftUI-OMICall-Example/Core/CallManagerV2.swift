//
//  CallManagerV2.swift
//  SwiftUI-OMICall-Example
//
//  Created by H-Solutions on 9/1/26.
//
//  Async/Await version of CallManager for customers who prefer modern Swift concurrency.
//
//  ✅ SWIFT 6 COMPATIBLE (requires OmiKit >= 1.10.8)
//  This version is fully compatible with Swift 6 strict concurrency when using OmiKit 1.10.8+.
//  The OmiKit.podspec includes `SWIFT_STRICT_CONCURRENCY = minimal` configuration to prevent
//  `dispatch_assert_queue_fail` crashes.
//
//  Key Swift 6 optimizations:
//  - Uses `@preconcurrency import OmiKit` for smooth integration
//  - All NotificationCenter observers use closure-based pattern with `queue: .main`
//  - All notification handling logic is inlined in closures to avoid Sendable issues
//  - No `@objc` selectors that can cause queue assertion failures
//

import AVFoundation
import Combine
import Foundation
@preconcurrency import OmiKit
import PushKit
import SwiftUI
import UIKit
import UserNotifications

// MARK: - Notification Names Extension
extension Notification.Name {
    static let callStateDidChangeV2 = Notification.Name("callStateDidChangeV2")
    static let callDidEndV2 = Notification.Name("callDidEndV2")
    static let incomingCallReceivedV2 = Notification.Name("incomingCallReceivedV2")
    static let incomingCallAcceptedV2 = Notification.Name("incomingCallAcceptedV2")
    static let outgoingCallStartedV2 = Notification.Name("outgoingCallStartedV2")
    static let missedCallTappedV2 = Notification.Name("missedCallTappedV2")
}

// MARK: - Call Manager Error
enum CallManagerError: Error, LocalizedError {
    case noActiveCall
    case callNotConnected
    case operationFailed(String)
    case loginFailed
    case callStartFailed(OMIStartCallStatus)

    var errorDescription: String? {
        switch self {
        case .noActiveCall:
            return "No active call"
        case .callNotConnected:
            return "Call is not connected"
        case .operationFailed(let message):
            return message
        case .loginFailed:
            return "Login failed"
        case .callStartFailed(let status):
            return "Failed to start call with status: \(status)"
        }
    }
}

// MARK: - Call Manager V2 Singleton (Async/Await Version)
/// Central manager for OmiKit SDK - handles all call operations using modern async/await.
/// This version provides async alternatives to callback-based methods.
///
/// Example usage:
/// ```swift
/// // Login
/// let success = try await CallManagerV2.shared.login(username: "user", password: "pass", realm: "realm")
///
/// // Start call
/// let status = try await CallManagerV2.shared.startCall(to: "0123456789")
///
/// // End call
/// try await CallManagerV2.shared.endCall()
/// ```
class CallManagerV2: NSObject, ObservableObject {

    @MainActor static let shared = CallManagerV2()

    // MARK: - Published Properties (for SwiftUI)
    @Published var currentCall: OmiCallModelV2?
    @Published var callState: CallStateStatusV2 = .null
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

    // MARK: - UI Navigation State (for SwiftUI)
    @Published var shouldShowActiveCallView: Bool = false

    // MARK: - OmiKit References
    var omiSIPLib: OMISIPLib {
        return OMISIPLib.sharedInstance()
    }

    // MARK: - Internal Components
    private(set) var callKitProviderDelegate: CallKitProviderDelegate?
    private(set) var pushKitManager: PushKitManager?
    private var voipRegistry: PKPushRegistry?

    // MARK: - Timer
    private var callTimer: Timer?

    // MARK: - Notification Observer Tokens (for closure-based observers)
    private var callStateChangedObserver: NSObjectProtocol?
    private var callDeallocObserver: NSObjectProtocol?
    private var outboundCallStartedObserver: NSObjectProtocol?
    private var inboundCallAcceptedObserver: NSObjectProtocol?
    private var inboundCallRejectedObserver: NSObjectProtocol?

    // MARK: - Missed Call Tracking
    private var lastIncomingCallerNumber: String = ""
    private var lastIncomingCallerName: String = ""
    private var lastIncomingCallTime: Date?
    private var wasCallAnswered: Bool = false

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - SDK Initialization (Call this from AppDelegate)

    /// Initialize OmiKit SDK with all required components.
    /// Call this method once in `application(_:didFinishLaunchingWithOptions:)`.
    ///
    /// Example:
    /// ```swift
    /// func application(_ application: UIApplication,
    ///                  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    ///     Task { @MainActor in
    ///         await CallManagerV2.shared.initialize(application: application)
    ///     }
    ///     return true
    /// }
    /// ```
    @MainActor
    func initialize(application: UIApplication, logLevel: Int = 5) async {
        // 1. Configure SDK log level and environment
        setLogLevel(logLevel)
        configureSDK()

        // 2. Setup CallKit provider delegate
        callKitProviderDelegate = CallKitProviderDelegate(
            callManager: omiSIPLib.callManager
        )

        // 3. Setup PushKit for VoIP notifications
        // PushKitManager is provided by OmiKit SDK
        voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        pushKitManager = PushKitManager(voipRegistry: voipRegistry!)

        // 4. Setup observers for SDK notifications
        setupObservers()
        
        OmiClient.setIsPartialPhoneNumber(true)
        
        // 5. Request notification permissions for missed calls
        await requestNotificationPermissions(application)
    }

    /// Clean up resources when app terminates.
    /// Call this in `applicationWillTerminate(_:)`.
    func cleanup() {
        closeCallOnAppTerminate()
        removeObservers()
    }

    // MARK: - SDK Configuration

    /// Set log level for SDK (1-5)
    /// 1 - OMILogVerbose, 2 - OMILogDebug, 3 - OMILogInfo, 4 - OMILogWarning, 5 - OMILogError
    func setLogLevel(_ level: Int = 2) {
        OmiClient.setLogLevel(Int32(level))

    }

    /// Configure SDK environment
    func configureSDK() {
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
        OmiClient.setFcmProjectId(PROJECT_ID_DEFAULT)
    }

    // MARK: - Notification Permissions (Async)

    /// Request notification permissions asynchronously
    /// - Parameter application: UIApplication instance
    /// - Returns: Whether permission was granted
    @discardableResult
    func requestNotificationPermissions(_ application: UIApplication) async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            if granted {
                application.registerForRemoteNotifications()
            }
            return granted
        } catch {
            print("Error requesting notification permissions: \(error)")
            return false
        }
    }

    // MARK: - Observers Setup

    private func setupObservers() {
        // All observers use closure-based pattern with OperationQueue.main for Swift 6 compatibility
        // This prevents dispatch_assert_queue_fail crashes

        // 1. Listen for call state changes from OmiKit SDK
        callStateChangedObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.OMICallStateChanged,
            object: nil,
            queue: .main  // Force main queue to avoid Swift 6 concurrency issues
        ) { [weak self] notification in
            // Swift 6: Extract ALL data from userInfo BEFORE entering MainActor context
            guard let userInfo = notification.userInfo,
                  let callStateRaw = userInfo[OMINotificationUserInfoCallStateKey] as? Int,
                  let newState = CallStateStatusV2(rawValue: callStateRaw)
            else { return }

            // Extract call info if available
            var callModel: OmiCallModelV2?
            var isIncoming = false
            var callerNumber = ""
            var callerName = ""
            var isVideo = false

            if let omiCall = userInfo[OMINotificationUserInfoCallKey] as? OMICall {
                callModel = OmiCallModelV2(from: omiCall)
                isIncoming = omiCall.isIncoming
                callerNumber = omiCall.callerNumber ?? ""
                callerName = omiCall.callerName ?? ""
                isVideo = omiCall.isVideo
            }

            // Now safely enter MainActor context with extracted data
            MainActor.assumeIsolated {
                guard let self = self else { return }

                // Update model (safe to update @Published on Main Thread)
                if let model = callModel {
                    self.currentCall = model

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
                    self.hasIncomingCall = true
                    self.hasActiveCall = false
                    // Track incoming call for missed call detection
                    self.lastIncomingCallerNumber = callerNumber
                    self.lastIncomingCallerName = callerName
                    self.lastIncomingCallTime = Date()
                    self.wasCallAnswered = false
                    print("📞 Incoming call from: \(callerNumber)")

                case .confirmed:
                    self.hasActiveCall = true
                    self.hasIncomingCall = false
                    self.wasCallAnswered = true
                    self.startCallTimer()
                    print("📞 Call answered")

                case .disconnected:
            
                    print("📞 [StateChange->Disconnected] Status text: %@", callModel?.lastStatus ?? "Unknown");
                    self.stopCallTimer()
                    self.resetCallState()

                case .calling, .early, .connecting:
                    self.hasActiveCall = true
                    self.hasIncomingCall = false

                default:
                    break
                }
            }

            // Post notification for SwiftUI (outside MainActor.assumeIsolated to avoid Sendable warning)
            // Safe because we're already on main queue (queue: .main)
            NotificationCenter.default.post(
                name: .callStateDidChangeV2,
                object: nil,
                userInfo: userInfo
            )
        }

        // 2. Listen for call dealloc (end reasons)
        callDeallocObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.OMICallDealloc,
            object: nil,
            queue: .main  // Force main queue
        ) { [weak self] notification in
            // Swift 6: Extract ALL data from userInfo BEFORE entering MainActor context
            guard let userInfo = notification.userInfo,
                  let endCause = userInfo[OMINotificationEndCauseKey] as? Int
            else { return }

            print("Call ended with cause: \(endCause) ---> userInfo: \(userInfo)")

            // Get end cause message before entering MainActor context
            var message: String = ""

            // Now safely enter MainActor context with extracted data
            MainActor.assumeIsolated {
                guard let self = self else { return }

                // Check for missed call
                if !self.wasCallAnswered && !self.lastIncomingCallerNumber.isEmpty && self.lastIncomingCallTime != nil {
                    let callerNumber = self.lastIncomingCallerNumber
                    let callerName = self.lastIncomingCallerName
                    let callTime = self.lastIncomingCallTime!

                    Task {
                        await self.showMissedCallNotification(
                            callerNumber: callerNumber,
                            callerName: callerName,
                            callTime: callTime
                        )
                    }

                    self.lastIncomingCallerNumber = ""
                    self.lastIncomingCallerName = ""
                    self.lastIncomingCallTime = nil
                }

                // Reset answered flag
                self.wasCallAnswered = false

                // Get end cause message
                message = self.getEndCauseMessage(endCause)
            }

            // Post notification outside MainActor.assumeIsolated to avoid Sendable warning
            // Safe because we're already on main queue (queue: .main)
            NotificationCenter.default.post(
                name: .callDidEndV2,
                object: nil,
                userInfo: ["message": message, "cause": endCause]
            )
        }

        // 3. CallKit inbound call accepted
        inboundCallAcceptedObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.CallKitProviderDelegateInboundCallAccepted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleInboundCallAcceptedClosure()
            }
        }

        // 4. CallKit outbound call started
        outboundCallStartedObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.CallKitProviderDelegateOutboundCallStarted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleOutboundCallStartedClosure()
            }
        }

        // 5. CallKit inbound call rejected
        inboundCallRejectedObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.CallKitProviderDelegateInboundCallRejected,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleInboundCallRejectedClosure()
            }
        }
    }


    private func removeObservers() {
        // Remove all closure-based observers
        if let observer = callStateChangedObserver {
            NotificationCenter.default.removeObserver(observer)
            callStateChangedObserver = nil
        }
        if let observer = callDeallocObserver {
            NotificationCenter.default.removeObserver(observer)
            callDeallocObserver = nil
        }
        if let observer = outboundCallStartedObserver {
            NotificationCenter.default.removeObserver(observer)
            outboundCallStartedObserver = nil
        }
        if let observer = inboundCallAcceptedObserver {
            NotificationCenter.default.removeObserver(observer)
            inboundCallAcceptedObserver = nil
        }
        if let observer = inboundCallRejectedObserver {
            NotificationCenter.default.removeObserver(observer)
            inboundCallRejectedObserver = nil
        }
    }

    // MARK: - CallKit Notification Handlers (Swift 6 compatible)
    // These handlers are called from closure-based observers with queue: .main
    // which ensures they run on main queue and avoid dispatch_assert_queue_fail crash

    @MainActor
    private func handleInboundCallAcceptedClosure() {
        print("Inbound call accepted from CallKit (closure handler)")

        // Mark call as answered (prevent missed call notification)
        wasCallAnswered = true

        // Already on main queue (queue: .main in observer), safe to update @Published properties
        handleIncomingCallAccepted()
        shouldShowActiveCallView = true

        // Post notification to show ActiveCallView (for legacy listeners)
        NotificationCenter.default.post(name: .incomingCallAcceptedV2, object: nil)
    }

    @MainActor
    private func handleOutboundCallStartedClosure() {
        print("Outbound call started from CallKit (closure handler)")

        // Already on main queue (queue: .main in observer), safe to access SDK and update @Published properties
        var phoneNumber = ""
        var isVideo = false

        // Access SDK directly
        let sipLib = OMISIPLib.sharedInstance()
        if let currentCall = sipLib.getCurrentCall() {
            phoneNumber = currentCall.numberToCall
            isVideo = currentCall.isVideo

            // Update CallManager with call info
            let callModel = OmiCallModelV2(from: currentCall)
            self.currentCall = callModel
            self.hasActiveCall = true
            self.shouldShowActiveCallView = true
        }

        // Post notification with call info (for legacy listeners)
        NotificationCenter.default.post(
            name: .outgoingCallStartedV2,
            object: nil,
            userInfo: ["phoneNumber": phoneNumber, "isVideo": isVideo]
        )
    }

    @MainActor
    private func handleInboundCallRejectedClosure() {
        print("Inbound call rejected from CallKit (closure handler)")

        // Already on main queue (queue: .main in observer), safe to update @Published properties
        hasIncomingCall = false
        hasActiveCall = false
        currentCall = nil

        // Post notification for UI to handle
        NotificationCenter.default.post(
            name: .callDidEndV2, object: nil,
            userInfo: ["message": "Call Rejected", "cause": 603])
    }

    // MARK: - Missed Call Notification

    private func getEndCauseMessage(_ cause: Int) -> String {
        switch cause {
        case 486: return "Busy"
        case 600, 503, 403: return "No Answer"
        case 480: return "Subscriber Busy (Timeout)"
        case 408: return "Request Timeout"
        case 404: return "Network Error"
        case 603: return "Declined"
        default: return "Call Ended"
        }
    }

    /// Show local notification for missed call (async version)
    private func showMissedCallNotification(
        callerNumber: String, callerName: String, callTime: Date
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "Missed Call"

        // Use caller name if available, otherwise use number
        let displayName = callerName.isEmpty ? callerNumber : callerName
        content.body = "You missed a call from \(displayName)"

        content.sound = .default
        content.badge = NSNumber(
            value: UIApplication.shared.applicationIconBadgeNumber + 1)

        // Store call info in userInfo for handling tap
        content.userInfo = [
            "type": "missed_call",
            "omisdkCallerNumber": callerNumber,
            "omisdkCallerName": callerName,
            "callTime": callTime.timeIntervalSince1970,
        ]

        // Create trigger (show immediately)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1, repeats: false)

        // Create request with unique identifier
        let identifier = "missed_call_\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier, content: content, trigger: trigger)

        // Add to notification center
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📱 Missed call notification shown for: \(displayName)")
        } catch {
            print("Error showing missed call notification: \(error)")
        }
    }

    // MARK: - Authentication (Async/Await)

    /// Initialize SIP connection with credentials
    /// - Parameters:
    ///   - username: SIP username
    ///   - password: SIP password
    ///   - realm: SIP realm
    /// - Returns: Whether login was successful
    /// - Throws: CallManagerError if login fails
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     let success = try await CallManagerV2.shared.login(
    ///         username: "user",
    ///         password: "password",
    ///         realm: "sip.example.com"
    ///     )
    ///     print("Login successful: \(success)")
    /// } catch {
    ///     print("Login failed: \(error)")
    /// }
    /// ```
    @discardableResult
    func login(username: String, password: String, realm: String) async throws -> Bool {
            OmiClient.initWithUsername(
                username,
                password: password,
                realm: realm, 
                proxy: "",
                isSkipDevices: true
            )
        

        // Configure decline call behavior
        OmiClient.configureDeclineCallBehavior(true)

        // Store login state
        isLoggedIn = true

        return true
    }

    /// Login with UUID and Phone number
    /// - Parameters:
    ///   - usrUuid: User UUID from OMI system
    ///   - fullName: Display name (optional)
    ///   - apiKey: API Key provided by OMI
    ///   - phone: Phone number associated with the account
    /// - Returns: true if login successful
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     let success = try await CallManagerV2.shared.loginWithUUID(
    ///         usrUuid: "user-uuid-123",
    ///         fullName: "John Doe",
    ///         apiKey: "your-api-key",
    ///         phone: "0123456789"
    ///     )
    /// } catch {
    ///     print("Login failed: \(error)")
    /// }
    /// ```
    @discardableResult
    func loginWithUUID(usrUuid: String, fullName: String?, apiKey: String, phone: String) async throws -> Bool {
        let success = OmiClient.initWithUUIDAndPhone(
            usrUuid,
            fullName: fullName,
            apiKey: apiKey,
            phone: phone
        )

        // Configure decline call behavior
        OmiClient.configureDeclineCallBehavior(true)

        // Store login state
        isLoggedIn = success

        if !success {
            throw CallManagerError.loginFailed
        }

        return success
    }

    /// Logout from SIP
    func logout() {
        OmiClient.logout()
        isLoggedIn = false
        currentCall = nil
        callState = .null
    }

    // MARK: - Call Operations (Async/Await)

    /// Start an outgoing call
    /// - Parameters:
    ///   - phoneNumber: Number to call
    ///   - isVideo: Whether this is a video call
    /// - Returns: Call start status
    /// - Throws: CallManagerError if call fails to start
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     let status = try await CallManagerV2.shared.startCall(to: "0123456789")
    ///     print("Call started with status: \(status)")
    /// } catch {
    ///     print("Failed to start call: \(error)")
    /// }
    /// ```
    @discardableResult
    nonisolated func startCall(to phoneNumber: String, isVideo: Bool = false) async throws -> OMIStartCallStatus {
        return try await withCheckedThrowingContinuation { continuation in
            // Call OmiClient directly - SDK handles its own threading internally
            OmiClient.startCall(phoneNumber, isVideo: isVideo) { status in
                // Resume continuation on main queue to avoid dispatch assertion failures
                DispatchQueue.main.async {
                    if status == .startCallSuccess {
                        continuation.resume(returning: status)
                    } else {
                        continuation.resume(throwing: CallManagerError.callStartFailed(status))
                    }
                }
            }
        }
    }

    /// End current call
    /// - Throws: CallManagerError if no active call or operation fails
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     try await CallManagerV2.shared.endCall()
    ///     print("Call ended successfully")
    /// } catch {
    ///     print("Failed to end call: \(error)")
    /// }
    /// ```
    nonisolated func endCall() async throws {
        // Access SDK directly to avoid actor isolation issues
        let sipLib = OMISIPLib.sharedInstance()
        guard let call = sipLib.getCurrentCall() else {
            throw CallManagerError.noActiveCall
        }

        guard call.callState != .disconnected else {
            return // Already disconnected
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sipLib.callManager.end(call) { error in
                if let error = error {
                    print("Error ending call: \(error)")
                    continuation.resume(throwing: CallManagerError.operationFailed(error.localizedDescription))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

        // Stop timer on main thread after call ends
        await MainActor.run {
            stopCallTimer()
        }
    }

    /// Toggle mute state
    /// - Returns: New mute state
    /// - Throws: CallManagerError if no active call or operation fails
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     let isMuted = try await CallManagerV2.shared.toggleMute()
    ///     print("Mute state: \(isMuted)")
    /// } catch {
    ///     print("Failed to toggle mute: \(error)")
    /// }
    /// ```
    @discardableResult
    nonisolated func toggleMute() async throws -> Bool {
        // Access SDK directly to avoid actor isolation issues
        let sipLib = OMISIPLib.sharedInstance()
        guard let call = sipLib.getCurrentCall() else {
            throw CallManagerError.noActiveCall
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sipLib.callManager.toggleMute(for: call) { error in
                if let error = error {
                    continuation.resume(throwing: CallManagerError.operationFailed(error.localizedDescription))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

        // Update state on main thread after operation completes
        return await MainActor.run {
            isMuted.toggle()
            return isMuted
        }
    }

    /// Toggle hold state
    /// - Returns: New hold state
    /// - Throws: CallManagerError if no active call or operation fails
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     let isOnHold = try await CallManagerV2.shared.toggleHold()
    ///     print("Hold state: \(isOnHold)")
    /// } catch {
    ///     print("Failed to toggle hold: \(error)")
    /// }
    /// ```
    @discardableResult
    nonisolated func toggleHold() async throws -> Bool {
        // Access SDK directly to avoid actor isolation issues
        let sipLib = OMISIPLib.sharedInstance()
        guard let call = sipLib.getCurrentCall() else {
            throw CallManagerError.noActiveCall
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sipLib.callManager.toggleHold(for: call) { error in
                if let error = error {
                    continuation.resume(throwing: CallManagerError.operationFailed(error.localizedDescription))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

        // Update state on main thread after operation completes
        return await MainActor.run {
            isOnHold.toggle()
            return isOnHold
        }
    }

    /// Toggle speaker
    /// - Returns: New speaker state
    ///
    /// Example:
    /// ```swift
    /// let isSpeakerOn = CallManagerV2.shared.toggleSpeaker()
    /// print("Speaker state: \(isSpeakerOn)")
    /// ```
    @discardableResult
    func toggleSpeaker() -> Bool {
        omiSIPLib.callManager.audioController.output =
            omiSIPLib.callManager.audioController.output == .speaker
            ? .other : .speaker

        isSpeakerOn.toggle()
        return isSpeakerOn
    }

    /// Send DTMF tone
    /// - Parameter digit: DTMF digit to send
    /// - Throws: CallManagerError if no active call or call not connected
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     try CallManagerV2.shared.sendDTMF("1")
    /// } catch {
    ///     print("Failed to send DTMF: \(error)")
    /// }
    /// ```
    func sendDTMF(_ digit: String) throws {
        guard let call = omiSIPLib.getCurrentCall() else {
            throw CallManagerError.noActiveCall
        }

        guard call.callState == .confirmed else {
            throw CallManagerError.callNotConnected
        }

        try call.sendDTMF(digit)
    }

    /// Transfer call to another number
    /// - Parameter phoneNumber: Number to transfer to
    /// - Throws: CallManagerError if no active call or transfer fails
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     try CallManagerV2.shared.transferCall(to: "0987654321")
    /// } catch {
    ///     print("Failed to transfer call: \(error)")
    /// }
    /// ```
    func transferCall(to phoneNumber: String) throws {
        guard let call = omiSIPLib.getCurrentCall() else {
            throw CallManagerError.noActiveCall
        }

        try call.blindTransferCall(withNumber: phoneNumber)
    }

    // MARK: - Call Timer

    func startCallTimer() {
        callDuration = 0
        callTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
            [weak self] _ in
            Task { @MainActor in
                self?.callDuration += 1
            }
        }
    }

    func stopCallTimer() {
        callTimer?.invalidate()
        callTimer = nil
    }

    // MARK: - Call State Management

    /// Handle incoming call accepted from CallKit
    func handleIncomingCallAccepted() {
        hasActiveCall = true
        hasIncomingCall = false
    }

    private func resetCallState() {
        isMuted = false
        isSpeakerOn = false
        isOnHold = false
        callDuration = 0
        hasActiveCall = false
        hasIncomingCall = false
        incomingCallerNumber = ""
        incomingCallerName = ""
        isIncomingVideoCall = false
        currentCall = nil
        shouldShowActiveCallView = false
    }

    // MARK: - Computed Properties (for UI)

    /// Get the phone number to display for the active call
    var activeCallPhoneNumber: String {
        if let call = currentCall {
            // For incoming calls, use callerNumber; for outgoing, use numberToCall
            if call.incoming {
                return call.callerNumber.isEmpty ? call.callerName : call.callerNumber
            } else {
                return call.numberToCall
            }
        }
        // Fallback to incoming caller info
        return incomingCallerNumber.isEmpty ? incomingCallerName : incomingCallerNumber
    }

    /// Check if the active call is a video call
    var activeCallIsVideo: Bool {
        if let call = currentCall {
            return call.isVideo
        }
        return isIncomingVideoCall
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

// MARK: - UNUserNotificationCenterDelegate
extension CallManagerV2: UNUserNotificationCenterDelegate {

    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (
            UNNotificationPresentationOptions
        ) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle user tap on notification (missed call notification)
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Check if this is a missed call notification
        if let type = userInfo["type"] as? String, type == "missed_call" {
            let callerNumber = userInfo["omisdkCallerNumber"] as? String ?? ""
            let callerName = userInfo["omisdkCallerName"] as? String ?? ""

            print("User tapped on missed call notification: \(callerNumber)")

            // Post notification to handle in UI (e.g., navigate to call history or dial screen)
            Task { @MainActor in
                NotificationCenter.default.post(
                    name: .missedCallTappedV2,
                    object: nil,
                    userInfo: [
                        "callerNumber": callerNumber,
                        "callerName": callerName,
                    ]
                )
            }
        }

        // Clear badge count
        Task { @MainActor in
            UIApplication.shared.applicationIconBadgeNumber = 0
        }

        completionHandler()
    }
}

// MARK: - OmiCallModelV2
struct OmiCallModelV2: Hashable {
    var callId: Int
    var incoming: Bool = false
    var callState: CallStateStatusV2 = .null
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
    var lastStatus: Int = 0
    var lastStatusText: String = ""
    


    
    init(from omiCall: OMICall) {
        self.callId = omiCall.callId
        self.incoming = omiCall.isIncoming
        self.callState =
            CallStateStatusV2(rawValue: omiCall.callState.rawValue) ?? .null
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
        self.lastStatus = omiCall.lastStatus
        self.lastStatusText = omiCall.lastStatusText ?? ""
  
    }

    // Simple initializer for outgoing calls
    init(phoneNumber: String, isVideo: Bool = false) {
        self.callId = 0
        self.incoming = false
        self.numberToCall = phoneNumber
        self.isVideo = isVideo
    }
}

// MARK: - CallStateStatusV2 Enum
enum CallStateStatusV2: Int {
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
enum CallDirectionV2 {
    case incoming
    case outgoing
}
