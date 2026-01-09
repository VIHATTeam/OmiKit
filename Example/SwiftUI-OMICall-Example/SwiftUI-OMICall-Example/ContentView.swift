//
//  ContentView.swift
//  SwiftUI-OMICall-Example
//
//  Created by H-Solutions on 9/1/26.
//

import OmiKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var callManager: CallManager
    @State private var showActiveCall: Bool = false
    @State private var outgoingPhoneNumber: String = ""
    @State private var isOutgoingVideoCall: Bool = false

    var body: some View {
        ZStack {
            // Main content - LoginView as root
            LoginView()

            // ActiveCallView overlay when there's an active call
        }
        .fullScreenCover(isPresented: $showActiveCall) {
            ActiveCallView(
                phoneNumber: activeCallPhoneNumber,
                isVideo: activeCallIsVideo,
                isPresented: $showActiveCall
            )
        }
        // Listen for incoming call accepted from CallKit
        .onReceive(NotificationCenter.default.publisher(for: .incomingCallAccepted)) { _ in
            print("ContentView: Incoming call accepted - showing ActiveCallView")
            showActiveCall = true
        }
        // Listen for outgoing call started from CallKit
        .onReceive(NotificationCenter.default.publisher(for: .outgoingCallStarted)) { notification in
            print("ContentView: Outgoing call started - showing ActiveCallView")

            // Get call info from notification userInfo
            if let userInfo = notification.userInfo {
                if let phoneNumber = userInfo["phoneNumber"] as? String, !phoneNumber.isEmpty {
                    outgoingPhoneNumber = phoneNumber
                }
                if let isVideo = userInfo["isVideo"] as? Bool {
                    isOutgoingVideoCall = isVideo
                }
            }

            // Fallback: Get outgoing call info from CallManager
            if outgoingPhoneNumber.isEmpty, let call = callManager.currentCall {
                outgoingPhoneNumber = call.numberToCall
                isOutgoingVideoCall = call.isVideo
            }

            showActiveCall = true
        }
        // Listen for call state changes
        .onChange(of: callManager.hasActiveCall) { hasActive in
            if hasActive && !showActiveCall {
                // Show active call view when call becomes active
                showActiveCall = true
            } else if !hasActive && showActiveCall {
                // Hide when call ends
                showActiveCall = false
            }
        }
        // Listen for call ended
        .onReceive(NotificationCenter.default.publisher(for: .callDidEnd)) { _ in
            showActiveCall = false
            // Reset outgoing call info
            outgoingPhoneNumber = ""
            isOutgoingVideoCall = false
        }
    }

    // MARK: - Computed Properties

    private var activeCallPhoneNumber: String {
        // Priority: currentCall > outgoingPhoneNumber > incomingCallerNumber
        if let call = callManager.currentCall {
            // For incoming calls, use callerNumber; for outgoing, use numberToCall
            if call.incoming {
                return call.callerNumber.isEmpty ? call.callerName : call.callerNumber
            } else {
                return call.numberToCall
            }
        }

        // Fallback for outgoing calls
        if !outgoingPhoneNumber.isEmpty {
            return outgoingPhoneNumber
        }

        // Fallback to incoming caller info
        return callManager.incomingCallerNumber.isEmpty
            ? callManager.incomingCallerName
            : callManager.incomingCallerNumber
    }

    private var activeCallIsVideo: Bool {
        // Priority: currentCall > isOutgoingVideoCall > isIncomingVideoCall
        if let call = callManager.currentCall {
            return call.isVideo
        }

        // Fallback for outgoing calls
        if isOutgoingVideoCall {
            return true
        }

        // Fallback to incoming video flag
        return callManager.isIncomingVideoCall
    }
}

#Preview {
    ContentView()
        .environmentObject(CallManager.shared)
}
