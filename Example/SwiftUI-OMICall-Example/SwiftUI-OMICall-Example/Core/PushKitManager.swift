//
//  PushKitManager.swift
//  SwiftUI-OMICall-Example
//
//  Created by H-Solutions on 9/1/26.
//

import Foundation
import OmiKit
import PushKit

/// Manages VoIP push notifications via PushKit
class PushKitManager: NSObject, PKPushRegistryDelegate {

    private var voipRegistry: PKPushRegistry

    init(voipRegistry: PKPushRegistry) {
        self.voipRegistry = voipRegistry
        super.init()

        // Set delegate and register for VoIP pushes
        self.voipRegistry.delegate = self
        self.voipRegistry.desiredPushTypes = [.voIP]
    }

    // MARK: - PKPushRegistryDelegate

    /// Called when VoIP push token is updated
    func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    ) {
        guard type == .voIP else { return }

        // Convert token to hex string
        let token = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        print("VoIP token: \(token)")

        // Send VoIP token to OmiKit SDK
        OmiClient.setUserPushNotificationToken(token)
    }

    /// Called when VoIP push token becomes invalid
    func pushRegistry(
        _ registry: PKPushRegistry,
        didInvalidatePushTokenFor type: PKPushType
    ) {
        guard type == .voIP else { return }
        print("VoIP push token invalidated")
    }

    /// Called when VoIP push notification is received
    /// IMPORTANT: This MUST report to CallKit IMMEDIATELY or iOS will terminate the app
    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        guard type == .voIP else {
            completion()
            return
        }

        print("Received VoIP push: \(payload.dictionaryPayload)")

        // CRITICAL: Let OmiKit SDK handle the incoming push via VoIPPushHandler
        // The SDK will report to CallKit internally - THIS MUST BE CALLED
        // or iOS will terminate the app with error:
        // "Killing app because it never posted an incoming call to the system"
        VoIPPushHandler.handle(payload) {
            // Push handling complete
            completion()
        }
    }
}
