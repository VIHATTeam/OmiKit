//
//  SwiftUI_OMICall_ExampleApp.swift
//  SwiftUI-OMICall-Example
//
//  Created by H-Solutions on 9/1/26.
//

import SwiftUI
import UIKit
import UserNotifications
@preconcurrency import OmiKit

// MARK: - App Delegate (Minimal - all logic handled by CallManagerV2)
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize OmiKit SDK using async/await (handles everything: CallKit, PushKit, observers, notifications)
        Task { @MainActor in
            await CallManagerV2.shared.initialize(application: application)
        }

        // Set notification delegate for missed call handling
        Task { @MainActor in
            UNUserNotificationCenter.current().delegate = CallManagerV2.shared
        }

        // Register observer for OMICallDealloc notification (in AppDelegate to ensure early registration)
        print("📡 [AppDelegate] Registering OMICallDealloc observer...")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCallDeallocNotification(_:)),
            name: NSNotification.Name.OMICallDealloc,
            object: nil
        )

        return true
    }

    // MARK: - OMICallDealloc Notification Handler

    @objc func handleCallDeallocNotification(_ notification: Notification) {
        print("🔔 [AppDelegate] ============================================")
        print("🔔 [AppDelegate] OMICallDealloc notification RECEIVED!")
        print("🔔 [AppDelegate] Notification name: \(notification.name.rawValue)")
        print("🔔 [AppDelegate] ============================================")

        guard let userInfo = notification.userInfo else {
            print("❌ [AppDelegate] No userInfo in notification")
            return
        }

        print("📞 [AppDelegate] userInfo: \(userInfo)")

        if let endCause = userInfo[OMINotificationEndCauseKey] as? Int {
            print("📞 [AppDelegate] Call ended with cause: \(endCause)")
        }

        // Forward to CallManagerV2 for processing
        Task { @MainActor in
            CallManagerV2.shared.handleCallEnded(notification)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Clean up SDK resources
        Task { @MainActor in
//            CallManagerV2.shared.cleanup()
        }
    }

    // MARK: - Remote Notifications (Optional - for APNS token logging)

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNS Token: \(token)")
    }
}

// MARK: - Main App
@main
struct SwiftUI_OMICall_ExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var callManager = CallManagerV2.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(callManager)
        }
    }
}
