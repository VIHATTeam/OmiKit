// //
// //  CallManager.swift
// //  SwiftUI-OMICall-Example
// //
// //  Created by H-Solutions on 9/1/26.
// //

// import AVFoundation
// import Combine
// import Foundation
// import OmiKit
// import PushKit
// import SwiftUI
// import UIKit
// import UserNotifications

// // MARK: - Notification Names Extension
// extension Notification.Name {
//     static let callStateDidChange = Notification.Name("callStateDidChange")
//     static let callDidEnd = Notification.Name("callDidEnd")
//     static let incomingCallReceived = Notification.Name("incomingCallReceived")
//     static let incomingCallAccepted = Notification.Name("incomingCallAccepted")
//     static let outgoingCallStarted = Notification.Name("outgoingCallStarted")
//     static let missedCallTapped = Notification.Name("missedCallTapped")
// }

// // MARK: - Call Manager Singleton
// /// Central manager for OmiKit SDK - handles all call operations, notifications, and state management.
// /// Users only need to call `CallManager.shared.initialize()` in AppDelegate.
// class CallManager: NSObject, ObservableObject {

//     static let shared = CallManager()

//     // MARK: - Published Properties (for SwiftUI)
//     @Published var currentCall: OmiCallModel?
//     @Published var callState: CallStateStatus = .null
//     @Published var isLoggedIn: Bool = false
//     @Published var isMuted: Bool = false
//     @Published var isSpeakerOn: Bool = false
//     @Published var isOnHold: Bool = false
//     @Published var callDuration: Int = 0

//     // MARK: - Incoming Call Properties
//     @Published var hasIncomingCall: Bool = false
//     @Published var hasActiveCall: Bool = false
//     @Published var incomingCallerNumber: String = ""
//     @Published var incomingCallerName: String = ""
//     @Published var isIncomingVideoCall: Bool = false

//     // MARK: - UI Navigation State (for SwiftUI)
//     @Published var shouldShowActiveCallView: Bool = false

//     // MARK: - OmiKit References
//     var omiSIPLib: OMISIPLib {
//         return OMISIPLib.sharedInstance()
//     }

//     // MARK: - Internal Components
//     private(set) var callKitProviderDelegate: CallKitProviderDelegate?
//     private(set) var pushKitManager: PushKitManager?
//     private var voipRegistry: PKPushRegistry?

//     // MARK: - Timer
//     private var callTimer: Timer?

//     // MARK: - Missed Call Tracking
//     private var lastIncomingCallerNumber: String = ""
//     private var lastIncomingCallerName: String = ""
//     private var lastIncomingCallTime: Date?
//     private var wasCallAnswered: Bool = false

//     // MARK: - Initialization

//     private override init() {
//         super.init()
//     }

//     // MARK: - SDK Initialization (Call this from AppDelegate)

//     /// Initialize OmiKit SDK with all required components.
//     /// Call this method once in `application(_:didFinishLaunchingWithOptions:)`.
//     ///
//     /// Example:
//     /// ```swift
//     /// func application(_ application: UIApplication,
//     ///                  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//     ///     CallManager.shared.initialize(application: application)
//     ///     return true
//     /// }
//     /// ```
//     func initialize(application: UIApplication, logLevel: Int = 2) {
//         // 1. Configure SDK log level and environment
//         setLogLevel(logLevel)
//         configureSDK()

//         // 2. Setup CallKit provider delegate
//         callKitProviderDelegate = CallKitProviderDelegate(
//             callManager: omiSIPLib.callManager
//         )

//         // 3. Setup PushKit for VoIP notifications
//         voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
//         pushKitManager = PushKitManager(voipRegistry: voipRegistry!)

//         // 4. Setup observers for SDK notifications
//         setupObservers()

//         // 5. Request notification permissions for missed calls
//         requestNotificationPermissions(application)
//     }

//     /// Clean up resources when app terminates.
//     /// Call this in `applicationWillTerminate(_:)`.
//     func cleanup() {
//         closeCallOnAppTerminate()
//         removeObservers()
//     }

//     // MARK: - SDK Configuration

//     /// Set log level for SDK (1-5)
//     /// 1 - OMILogVerbose, 2 - OMILogDebug, 3 - OMILogInfo, 4 - OMILogWarning, 5 - OMILogError
//     func setLogLevel(_ level: Int = 2) {
//         OmiClient.setLogLevel(Int32(level))
//     }

//     /// Configure SDK environment
//     func configureSDK() {
// #if DEBUG
//         OmiClient.setEnviroment(
//             KEY_OMI_APP_ENVIROMENT_SANDBOX,
//             userNameKey: "full_name",
//             maxCall: 1,
//             callKitImage: "call_image",
//             typePushVoip: TYPE_PUSH_CALLKIT_DEFAULT
//         )
// #else
//         OmiClient.setEnviroment(
//             KEY_OMI_APP_ENVIROMENT_PRODUCTION,
//             userNameKey: "full_name",
//             maxCall: 1,
//             callKitImage: "call_image",
//             typePushVoip: TYPE_PUSH_CALLKIT_DEFAULT
//         )
// #endif
//     }

//     // MARK: - Notification Permissions

//     private func requestNotificationPermissions(_ application: UIApplication) {
//         UNUserNotificationCenter.current().requestAuthorization(
//             options: [.alert, .badge, .sound]
//         ) { granted, error in
//             if granted {
//                 DispatchQueue.main.async {
//                     application.registerForRemoteNotifications()
//                 }
//             }
//         }
//     }

//     // MARK: - Observers Setup

//     private func setupObservers() {
//         // Listen for call state changes
//         NotificationCenter.default.addObserver(
//             self,
//             selector: #selector(handleCallStateChanged),
//             name: NSNotification.Name.OMICallStateChanged,
//             object: nil
//         )

//         // Listen for call dealloc (end reasons)
//         NotificationCenter.default.addObserver(
//             self,
//             selector: #selector(handleCallDealloc),
//             name: NSNotification.Name.OMICallDealloc,
//             object: nil
//         )

//         // Listen for CallKit inbound call accepted
//         NotificationCenter.default.addObserver(
//             self,
//             selector: #selector(handleInboundCallAccepted),
//             name: NSNotification.Name.CallKitProviderDelegateInboundCallAccepted,
//             object: nil
//         )

//         // Listen for CallKit outbound call started
//         NotificationCenter.default.addObserver(
//             self,
//             selector: #selector(handleOutboundCallStarted),
//             name: NSNotification.Name.CallKitProviderDelegateOutboundCallStarted,
//             object: nil
//         )

//         // Listen for CallKit inbound call rejected
//         NotificationCenter.default.addObserver(
//             self,
//             selector: #selector(handleInboundCallRejected),
//             name: NSNotification.Name.CallKitProviderDelegateInboundCallRejected,
//             object: nil
//         )
//     }

//     private func removeObservers() {
//         NotificationCenter.default.removeObserver(self)
//     }

//     // MARK: - Notification Handlers

//     @objc private func handleCallStateChanged(_ notification: Notification) {
//         // Process call state
//         processCallStateChanged(notification)

//         // Track incoming call info for missed call notification
//         if let userInfo = notification.userInfo,
//            let stateRaw = userInfo[OMINotificationUserInfoCallStateKey] as? Int,
//            let omiCall = userInfo[OMINotificationUserInfoCallKey] as? OMICall {

//             switch stateRaw {
//             case 2:  // incoming
//                 // Store incoming call info
//                 if omiCall.isIncoming {
//                     lastIncomingCallerNumber = omiCall.callerNumber ?? ""
//                     lastIncomingCallerName = omiCall.callerName ?? ""
//                     lastIncomingCallTime = Date()
//                     wasCallAnswered = false
//                     print("📞 Incoming call from: \(lastIncomingCallerNumber)")
//                 }
//             case 5:  // confirmed
//                 // Call was answered
//                 wasCallAnswered = true
//                 print("📞 Call answered")
//             default:
//                 break
//             }
//         }

//         // Post custom notification for SwiftUI views
//         DispatchQueue.main.async {
//             NotificationCenter.default.post(
//                 name: .callStateDidChange,
//                 object: nil,
//                 userInfo: notification.userInfo
//             )
//         }
//     }

//     @objc private func handleCallDealloc(_ notification: Notification) {
//         guard let userInfo = notification.userInfo,
//               let endCause = userInfo[OMINotificationEndCauseKey] as? Int
//         else {
//             return
//         }

//         print("Call ended with cause: \(endCause)")

//         // Check if this was a missed call (incoming call that was not answered)
//         if !wasCallAnswered && !lastIncomingCallerNumber.isEmpty
//             && lastIncomingCallTime != nil
//         {
//             // Show missed call notification
//             showMissedCallNotification(
//                 callerNumber: lastIncomingCallerNumber,
//                 callerName: lastIncomingCallerName,
//                 callTime: lastIncomingCallTime!
//             )

//             // Reset tracking
//             lastIncomingCallerNumber = ""
//             lastIncomingCallerName = ""
//             lastIncomingCallTime = nil
//         }

//         // Reset answered flag
//         wasCallAnswered = false

//         // Post notification with end cause message
//         let message = getEndCauseMessage(endCause)
//         NotificationCenter.default.post(
//             name: .callDidEnd,
//             object: nil,
//             userInfo: ["message": message, "cause": endCause]
//         )
//     }

//     @objc private func handleInboundCallAccepted(_ notification: Notification) {
//         print("Inbound call accepted from CallKit")

//         // Mark call as answered (prevent missed call notification)
//         wasCallAnswered = true

//         // Update CallManager state
//         handleIncomingCallAccepted()

//         // Show ActiveCallView
//         DispatchQueue.main.async {
//             self.shouldShowActiveCallView = true
//         }

//         // Post notification to show ActiveCallView (for legacy listeners)
//         NotificationCenter.default.post(name: .incomingCallAccepted, object: nil)
//     }

//     @objc private func handleOutboundCallStarted(_ notification: Notification) {
//         print("Outbound call started from CallKit")

//         // Get current call info from SDK
//         var phoneNumber = ""
//         var isVideo = false

//         if let currentCall = omiSIPLib.getCurrentCall() {
//             phoneNumber = currentCall.numberToCall ?? ""
//             isVideo = currentCall.isVideo

//             // Update CallManager with call info
//             let callModel = OmiCallModel(from: currentCall)
//             DispatchQueue.main.async {
//                 self.currentCall = callModel
//                 self.hasActiveCall = true
//                 self.shouldShowActiveCallView = true
//             }
//         }

//         // Post notification with call info (for legacy listeners)
//         DispatchQueue.main.async {
//             NotificationCenter.default.post(
//                 name: .outgoingCallStarted,
//                 object: nil,
//                 userInfo: ["phoneNumber": phoneNumber, "isVideo": isVideo]
//             )
//         }
//     }

//     @objc private func handleInboundCallRejected(_ notification: Notification) {
//         print("Inbound call rejected from CallKit")

//         // Reset call state when call is rejected
//         DispatchQueue.main.async {
//             self.hasIncomingCall = false
//             self.hasActiveCall = false
//             self.currentCall = nil

//             // Post notification for UI to handle
//             NotificationCenter.default.post(
//                 name: .callDidEnd, object: nil,
//                 userInfo: ["message": "Call Rejected", "cause": 603])
//         }
//     }

//     // MARK: - Missed Call Notification

//     private func getEndCauseMessage(_ cause: Int) -> String {
//         switch cause {
//         case 486: return "Busy"
//         case 600, 503, 403: return "No Answer"
//         case 480: return "Subscriber Busy (Timeout)"
//         case 408: return "Request Timeout"
//         case 404: return "Network Error"
//         case 603: return "Declined"
//         default: return "Call Ended"
//         }
//     }

//     /// Show local notification for missed call
//     private func showMissedCallNotification(
//         callerNumber: String, callerName: String, callTime: Date
//     ) {
//         let content = UNMutableNotificationContent()
//         content.title = "Missed Call"

//         // Use caller name if available, otherwise use number
//         let displayName = callerName.isEmpty ? callerNumber : callerName
//         content.body = "You missed a call from \(displayName)"

//         content.sound = .default
//         content.badge = NSNumber(
//             value: UIApplication.shared.applicationIconBadgeNumber + 1)

//         // Store call info in userInfo for handling tap
//         content.userInfo = [
//             "type": "missed_call",
//             "omisdkCallerNumber": callerNumber,
//             "omisdkCallerName": callerName,
//             "callTime": callTime.timeIntervalSince1970,
//         ]

//         // Create trigger (show immediately)
//         let trigger = UNTimeIntervalNotificationTrigger(
//             timeInterval: 1, repeats: false)

//         // Create request with unique identifier
//         let identifier = "missed_call_\(UUID().uuidString)"
//         let request = UNNotificationRequest(
//             identifier: identifier, content: content, trigger: trigger)

//         // Add to notification center
//         UNUserNotificationCenter.current().add(request) { error in
//             if let error = error {
//                 print("Error showing missed call notification: \(error)")
//             } else {
//                 print("📱 Missed call notification shown for: \(displayName)")
//             }
//         }
//     }

//     // MARK: - Authentication

//     /// Initialize SIP connection with credentials
//     func login(
//         username: String, password: String, realm: String,
//         completion: @escaping (Bool) -> Void
//     ) {
//
//

//         OmiClient.initWithUsername(
//             username,
//             password: password,
//             realm: realm,
//             proxy: ""
//         )

//         // Configure decline call behavior
//         OmiClient.configureDeclineCallBehavior(true)

//         // Store login state
//         DispatchQueue.main.async {
//             self.isLoggedIn = true
//         }

//         completion(true)
//     }

//     /// Logout from SIP
//     func logout() {
//         OmiClient.logout()
//         DispatchQueue.main.async {
//             self.isLoggedIn = false
//             self.currentCall = nil
//             self.callState = .null
//         }
//     }

//     // MARK: - Call Operations

//     /// Start an outgoing call
//     func startCall(
//         to phoneNumber: String, isVideo: Bool = false,
//         completion: @escaping (OMIStartCallStatus) -> Void
//     ) {
//         OmiClient.startCall(phoneNumber, isVideo: isVideo) { status in
//             DispatchQueue.main.async {
//                 switch status {
//                 case .startCallSuccess:
//                     // Call started successfully
//                     break
//                 default:
//                     break
//                 }
//                 completion(status)
//             }
//         }
//     }

//     /// End current call
//     func endCall(completion: @escaping (Bool) -> Void) {
//         guard let call = omiSIPLib.getCurrentCall() else {
//             completion(false)
//             return
//         }

//         if call.callState != .disconnected {
//             omiSIPLib.callManager.end(call) { error in
//                 DispatchQueue.main.async {
//                     if error != nil {
//                         print("Error ending call: \(error!)")
//                         completion(false)
//                     } else {
//                         self.stopCallTimer()
//                         completion(true)
//                     }
//                 }
//             }
//         } else {
//             completion(true)
//         }
//     }

//     /// Toggle mute
//     func toggleMute(completion: @escaping (Bool) -> Void) {
//         guard let call = omiSIPLib.getCurrentCall() else {
//             completion(false)
//             return
//         }

//         omiSIPLib.callManager.toggleMute(for: call) { error in
//             DispatchQueue.main.async {
//                 if error == nil {
//                     self.isMuted.toggle()
//                     completion(true)
//                 } else {
//                     completion(false)
//                 }
//             }
//         }
//     }

//     /// Toggle hold
//     func toggleHold(completion: @escaping (Bool) -> Void) {
//         guard let call = omiSIPLib.getCurrentCall() else {
//             completion(false)
//             return
//         }

//         omiSIPLib.callManager.toggleHold(for: call) { error in
//             DispatchQueue.main.async {
//                 if error == nil {
//                     self.isOnHold.toggle()
//                     completion(true)
//                 } else {
//                     completion(false)
//                 }
//             }
//         }
//     }

//     /// Toggle speaker
//     func toggleSpeaker() {
//         omiSIPLib.callManager.audioController.output =
//             omiSIPLib.callManager.audioController.output == .speaker
//             ? .other : .speaker

//         // Ensure UI update on main thread
//         if Thread.isMainThread {
//             self.isSpeakerOn.toggle()
//         } else {
//             DispatchQueue.main.async {
//                 self.isSpeakerOn.toggle()
//             }
//         }
//     }

//     /// Send DTMF tone
//     func sendDTMF(_ digit: String) {
//         guard let call = omiSIPLib.getCurrentCall(),
//               call.callState == .confirmed
//         else {
//             return
//         }

//         do {
//             try call.sendDTMF(digit)
//         } catch {
//             print("Error sending DTMF: \(error)")
//         }
//     }

//     /// Transfer call
//     func transferCall(to phoneNumber: String) {
//         guard let call = omiSIPLib.getCurrentCall() else {
//             return
//         }

//         do {
//             try call.blindTransferCall(withNumber: phoneNumber)
//         } catch {
//             print("Error transferring call: \(error)")
//         }
//     }

//     // MARK: - Call Timer

//     func startCallTimer() {
//         // Ensure we're on main thread for timer scheduling
//         if !Thread.isMainThread {
//             DispatchQueue.main.async { [weak self] in
//                 self?.startCallTimer()
//             }
//             return
//         }

//         callDuration = 0
//         callTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
//             [weak self] _ in
//             self?.callDuration += 1
//         }
//     }

//     func stopCallTimer() {
//         // Ensure we're on main thread for timer invalidation
//         if !Thread.isMainThread {
//             DispatchQueue.main.async { [weak self] in
//                 self?.stopCallTimer()
//             }
//             return
//         }

//         callTimer?.invalidate()
//         callTimer = nil
//     }

//     // MARK: - Call State Processing

//     func processCallStateChanged(_ notification: Notification) {
//         guard let userInfo = notification.userInfo,
//               let callStateRaw = userInfo[OMINotificationUserInfoCallStateKey]
//                   as? Int,
//               let newState = CallStateStatus(rawValue: callStateRaw)
//         else {
//             return
//         }

//         // Extract call info before dispatching to main thread
//         var callModel: OmiCallModel?
//         var isIncoming = false
//         var callerNumber = ""
//         var callerName = ""
//         var isVideo = false

//         if let omiCall = userInfo[OMINotificationUserInfoCallKey] as? OMICall {
//             callModel = OmiCallModel(from: omiCall)
//             isIncoming = omiCall.isIncoming
//             callerNumber = omiCall.callerNumber ?? ""
//             callerName = omiCall.callerName ?? ""
//             isVideo = omiCall.isVideo
//         }

//         // All UI updates on main thread
//         DispatchQueue.main.async { [weak self] in
//             guard let self = self else { return }

//             // Update call model
//             if let model = callModel {
//                 self.currentCall = model

//                 // Update incoming call info
//                 if isIncoming {
//                     self.incomingCallerNumber = callerNumber
//                     self.incomingCallerName = callerName
//                     self.isIncomingVideoCall = isVideo
//                 }
//             }

//             // Update call state
//             self.callState = newState

//             switch newState {
//             case .incoming:
//                 // Incoming call - set flag (CallKit will handle UI)
//                 self.hasIncomingCall = true
//                 self.hasActiveCall = false
//             case .confirmed:
//                 // Call connected - start timer and set active
//                 self.hasActiveCall = true
//                 self.hasIncomingCall = false
//                 self.startCallTimer()
//             case .disconnected:
//                 // Call ended - stop timer and reset
//                 self.stopCallTimer()
//                 self.resetCallState()
//             case .calling, .early, .connecting:
//                 // Outgoing call in progress
//                 self.hasActiveCall = true
//                 self.hasIncomingCall = false
//             default:
//                 break
//             }
//         }
//     }

//     /// Handle incoming call accepted from CallKit
//     func handleIncomingCallAccepted() {
//         DispatchQueue.main.async {
//             self.hasActiveCall = true
//             self.hasIncomingCall = false
//         }
//     }

//     private func resetCallState() {
//         // Ensure all @Published updates happen on main thread
//         let reset = {
//             self.isMuted = false
//             self.isSpeakerOn = false
//             self.isOnHold = false
//             self.callDuration = 0
//             self.hasActiveCall = false
//             self.hasIncomingCall = false
//             self.incomingCallerNumber = ""
//             self.incomingCallerName = ""
//             self.isIncomingVideoCall = false
//             self.currentCall = nil
//             self.shouldShowActiveCallView = false
//         }

//         if Thread.isMainThread {
//             reset()
//         } else {
//             DispatchQueue.main.async {
//                 reset()
//             }
//         }
//     }

//     // MARK: - Computed Properties (for UI)

//     /// Get the phone number to display for the active call
//     var activeCallPhoneNumber: String {
//         if let call = currentCall {
//             // For incoming calls, use callerNumber; for outgoing, use numberToCall
//             if call.incoming {
//                 return call.callerNumber.isEmpty ? call.callerName : call.callerNumber
//             } else {
//                 return call.numberToCall
//             }
//         }
//         // Fallback to incoming caller info
//         return incomingCallerNumber.isEmpty ? incomingCallerName : incomingCallerNumber
//     }

//     /// Check if the active call is a video call
//     var activeCallIsVideo: Bool {
//         if let call = currentCall {
//             return call.isVideo
//         }
//         return isIncomingVideoCall
//     }

//     // MARK: - Utilities

//     func formatDuration(_ seconds: Int) -> String {
//         let minutes = seconds / 60
//         let remainingSeconds = seconds % 60
//         return String(format: "%02d:%02d", minutes, remainingSeconds)
//     }

//     /// Get audio output devices
//     func getAudioOutputs() -> [[String: String]] {
//         return OmiClient.getAudioInDevices()
//     }

//     /// Set audio output
//     func setAudioOutput(_ portType: String) {
//         OmiClient.setAudioOutputs(portType)
//     }

//     /// Close call when app is killed
//     func closeCallOnAppTerminate() {
//         OmiClient.omiCloseCall()
//     }

//     /// Set push notification token
//     func setPushToken(_ token: String) {
//         OmiClient.setUserPushNotificationToken(token)
//     }
// }

// // MARK: - UNUserNotificationCenterDelegate
// extension CallManager: UNUserNotificationCenterDelegate {

//     /// Handle notification when app is in foreground
//     func userNotificationCenter(
//         _ center: UNUserNotificationCenter,
//         willPresent notification: UNNotification,
//         withCompletionHandler completionHandler: @escaping (
//             UNNotificationPresentationOptions
//         ) -> Void
//     ) {
//         // Show notification even when app is in foreground
//         completionHandler([.banner, .sound, .badge])
//     }

//     /// Handle user tap on notification (missed call notification)
//     func userNotificationCenter(
//         _ center: UNUserNotificationCenter,
//         didReceive response: UNNotificationResponse,
//         withCompletionHandler completionHandler: @escaping () -> Void
//     ) {
//         let userInfo = response.notification.request.content.userInfo

//         // Check if this is a missed call notification
//         if let type = userInfo["type"] as? String, type == "missed_call" {
//             let callerNumber = userInfo["omisdkCallerNumber"] as? String ?? ""
//             let callerName = userInfo["omisdkCallerName"] as? String ?? ""

//             print("User tapped on missed call notification: \(callerNumber)")

//             // Post notification to handle in UI (e.g., navigate to call history or dial screen)
//             DispatchQueue.main.async {
//                 NotificationCenter.default.post(
//                     name: .missedCallTapped,
//                     object: nil,
//                     userInfo: [
//                         "callerNumber": callerNumber,
//                         "callerName": callerName,
//                     ]
//                 )
//             }
//         }

//         // Clear badge count
//         DispatchQueue.main.async {
//             UIApplication.shared.applicationIconBadgeNumber = 0
//         }

//         completionHandler()
//     }
// }

// // MARK: - OmiCallModel
// struct OmiCallModel: Hashable {
//     var callId: Int
//     var incoming: Bool = false
//     var callState: CallStateStatus = .null
//     var callerNumber: String = ""
//     var isVideo: Bool = false
//     var omiId: String = ""
//     var uuid: String = UUID().uuidString
//     var callerName: String = ""
//     var muted: Bool = false
//     var speaker: Bool = false
//     var onHold: Bool = false
//     var numberToCall: String = ""
//     var connected: Bool = false

//     init(from omiCall: OMICall) {
//         self.callId = omiCall.callId
//         self.incoming = omiCall.isIncoming
//         self.callState =
//             CallStateStatus(rawValue: omiCall.callState.rawValue) ?? .null
//         if let callNumber = omiCall.callerNumber, !callNumber.isEmpty {
//             self.callerNumber = callNumber
//         }
//         self.isVideo = omiCall.isVideo
//         self.omiId = omiCall.omiId ?? ""
//         self.uuid = omiCall.uuid.uuidString
//         self.callerName = omiCall.callerName ?? ""
//         self.muted = omiCall.muted
//         self.speaker = omiCall.speaker
//         self.onHold = omiCall.onHold
//         self.numberToCall = omiCall.numberToCall ?? ""
//         self.connected = omiCall.connected
//     }

//     // Simple initializer for outgoing calls
//     init(phoneNumber: String, isVideo: Bool = false) {
//         self.callId = 0
//         self.incoming = false
//         self.numberToCall = phoneNumber
//         self.isVideo = isVideo
//     }
// }

// // MARK: - CallStateStatus Enum
// enum CallStateStatus: Int {
//     case null = 0
//     case calling = 1
//     case incoming = 2
//     case early = 3
//     case connecting = 4
//     case confirmed = 5
//     case disconnected = 6
//     case hold = 7
//     case disconnecting = 12

//     var displayText: String {
//         switch self {
//         case .null: return "Idle"
//         case .calling: return "Calling..."
//         case .incoming: return "Incoming..."
//         case .early: return "Ringing..."
//         case .connecting: return "Connecting..."
//         case .confirmed: return "Connected"
//         case .disconnected: return "Disconnected"
//         case .hold: return "On Hold"
//         case .disconnecting: return "Ending..."
//         }
//     }
// }

// // MARK: - Call Direction
// enum CallDirection {
//     case incoming
//     case outgoing
// }
