//
//  SwiftUI_OMICall_ExampleApp.swift
//  SwiftUI-OMICall-Example
//
//  Created by H-Solutions on 9/1/26.
//

import SwiftUI
import UIKit
import UserNotifications

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

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Clean up SDK resources
        Task { @MainActor in
            CallManagerV2.shared.cleanup()
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
