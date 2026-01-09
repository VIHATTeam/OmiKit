//
//  SwiftUI_OMICall_ExampleApp.swift
//  SwiftUI-OMICall-Example
//
//  Created by H-Solutions on 9/1/26.
//

import AVFoundation
import Foundation
import OmiKit
import PushKit
import SwiftUI
import UIKit
import UserNotifications

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var callKitProviderDelegate: CallKitProviderDelegate?
    var pushKitManager: PushKitManager?
    var voipRegistry: PKPushRegistry = PKPushRegistry(queue: DispatchQueue.main)

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure OmiKit SDK
        CallManager.shared.setLogLevel(2)  // Debug level
        CallManager.shared.configureSDK()

        // Setup CallKit provider delegate
        callKitProviderDelegate = CallKitProviderDelegate(
            callManager: CallManager.shared.omiSIPLib.callManager
        )

        // Setup PushKit for VoIP notifications
        voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        pushKitManager = PushKitManager(voipRegistry: voipRegistry)

        // Setup observers for call state changes
        setupObservers()

        // Request notification permissions and set delegate
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermissions(application)

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Close any active calls when app is terminated
        CallManager.shared.closeCallOnAppTerminate()
        removeObservers()
    }

    // MARK: - Notification Permissions

    private func requestNotificationPermissions(_ application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }

    // MARK: - Remote Notifications

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNS Token: \(token)")
        // Store token if needed
    }

    // MARK: - Observers

    private func setupObservers() {
        // Listen for call state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCallStateChanged),
            name: NSNotification.Name.OMICallStateChanged,
            object: nil
        )

        // Listen for call dealloc (end reasons)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCallDealloc),
            name: NSNotification.Name.OMICallDealloc,
            object: nil
        )

        // Listen for CallKit inbound call accepted
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInboundCallAccepted),
            name: NSNotification.Name.CallKitProviderDelegateInboundCallAccepted,
            object: nil
        )

        // Listen for CallKit outbound call started
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOutboundCallStarted),
            name: NSNotification.Name.CallKitProviderDelegateOutboundCallStarted,
            object: nil
        )
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleCallStateChanged(_ notification: Notification) {
        CallManager.shared.processCallStateChanged(notification)

        DispatchQueue.main.async {
            // Post custom notification for SwiftUI views
            NotificationCenter.default.post(
                name: .callStateDidChange,
                object: nil,
                userInfo: notification.userInfo
            )
        }
    }

    @objc private func handleCallDealloc(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let endCause = userInfo[OMINotificationEndCauseKey] as? Int else {
            return
        }

        print("Call ended with cause: \(endCause)")

        // Post notification with end cause message
        let message = getEndCauseMessage(endCause)
        NotificationCenter.default.post(
            name: .callDidEnd,
            object: nil,
            userInfo: ["message": message, "cause": endCause]
        )
    }

    @objc private func handleInboundCallAccepted(_ notification: Notification) {
        print("Inbound call accepted from CallKit")

        // Update CallManager state
        CallManager.shared.handleIncomingCallAccepted()

        // Post notification to show ActiveCallView
        NotificationCenter.default.post(name: .incomingCallAccepted, object: nil)
    }

    @objc private func handleOutboundCallStarted(_ notification: Notification) {
        print("Outbound call started from CallKit")

        // Get current call info from SDK
        var phoneNumber = ""
        var isVideo = false

        if let currentCall = CallManager.shared.omiSIPLib.getCurrentCall() {
            phoneNumber = currentCall.numberToCall ?? ""
            isVideo = currentCall.isVideo

            // Update CallManager with call info
            let callModel = OmiCallModel(from: currentCall)
            DispatchQueue.main.async {
                CallManager.shared.currentCall = callModel
                CallManager.shared.hasActiveCall = true
            }
        }

        // Post notification with call info to show ActiveCallView
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .outgoingCallStarted,
                object: nil,
                userInfo: ["phoneNumber": phoneNumber, "isVideo": isVideo]
            )
        }
    }

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

    // MARK: - UNUserNotificationCenterDelegate

    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle user tap on notification (missed call notification)
//    func userNotificationCenter(
//        _ center: UNUserNotificationCenter,
//        didReceive response: UNNotificationResponse,
//        withCompletionHandler completionHandler: @escaping () -> Void
//    ) {
//        let userInfo = response.notification.request.content.userInfo
//
//        // Check if this is an OmiKit missed call notification
//        if let _ = userInfo["omisdkCallerNumber"] {
//            print("User tapped on missed call notification: \(userInfo)")
//            OmikitNotification.didRecieve(userInfo)
//        }
//
//        completionHandler()
//    }
}

// MARK: - Notification Names Extension
extension Notification.Name {
    static let callStateDidChange = Notification.Name("callStateDidChange")
    static let callDidEnd = Notification.Name("callDidEnd")
    static let incomingCallReceived = Notification.Name("incomingCallReceived")
    static let incomingCallAccepted = Notification.Name("incomingCallAccepted")
    static let outgoingCallStarted = Notification.Name("outgoingCallStarted")
}

// MARK: - Main App
@main
struct SwiftUI_OMICall_ExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var callManager = CallManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(callManager)
            // Note: CallKit notifications are handled by AppDelegate observers
            // No need to duplicate listeners here
        }
    }
}
