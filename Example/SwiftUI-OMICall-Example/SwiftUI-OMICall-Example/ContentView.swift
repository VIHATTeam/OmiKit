//
//  ContentView.swift
//  SwiftUI-OMICall-Example
//
//  Created by H-Solutions on 9/1/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var callManager: CallManagerV2

    var body: some View {
        // Main content - LoginView as root
        LoginView()
            .fullScreenCover(isPresented: $callManager.shouldShowActiveCallView) {
                ActiveCallView(
                    phoneNumber: callManager.activeCallPhoneNumber,
                    isVideo: callManager.activeCallIsVideo,
                    isPresented: $callManager.shouldShowActiveCallView
                )
            }
    }
}

#Preview {
    ContentView()
        .environmentObject(CallManagerV2.shared)
}
