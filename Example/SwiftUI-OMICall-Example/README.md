# SwiftUI OmiKit Example

A complete SwiftUI example app demonstrating how to integrate the OmiKit iOS SDK for VoIP calling functionality.

## Features

- SIP authentication (login/logout)
- Outgoing audio/video calls
- Incoming call handling via CallKit
- VoIP push notifications via PushKit
- Call controls (mute, hold, speaker, DTMF)
- Call transfer
- Network quality indicator
- Missed call notifications

## Requirements

- iOS 13.0+
- Xcode 13.0+
- CocoaPods
- OmiKit SDK

## Installation

1. Navigate to the Example directory:
```bash
cd Example/SwiftUI-OMICall-Example
```

2. Install dependencies:
```bash
pod install
```

3. Open the workspace:
```bash
open SwiftUI-OMICall-Example.xcworkspace
```

4. Configure your Apple Developer account and enable:
   - Push Notifications capability
   - Background Modes: Audio, VoIP, Background fetch, Remote notifications
   - App Groups (if needed)

## Project Structure

```
SwiftUI-OMICall-Example/
├── SwiftUI_OMICall_ExampleApp.swift  # App entry point & AppDelegate
├── ContentView.swift                  # Root view with call navigation
├── Core/
│   ├── CallManager.swift             # OmiKit SDK wrapper singleton
│   ├── CallKitProviderDelegate.swift # CallKit integration
│   └── PushKitManager.swift          # VoIP push handling
├── Views/
│   ├── LoginView.swift               # SIP login screen
│   ├── CallingView.swift             # Dialpad & call initiation
│   └── ActiveCallView.swift          # Active call UI & controls
└── Info.plist                        # App configuration
```

## SDK Integration Guide

### 1. SDK Configuration

Configure the SDK in `AppDelegate.didFinishLaunchingWithOptions`:

```swift
import OmiKit

// Set log level (1-5: Verbose, Debug, Info, Warning, Error)
OmiClient.setLogLevel(2)

// Configure environment
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
```

**Parameters:**
- `environment`: `KEY_OMI_APP_ENVIROMENT_SANDBOX` or `KEY_OMI_APP_ENVIROMENT_PRODUCTION`
- `userNameKey`: Key to extract caller name from push payload (e.g., "full_name", "EXTENSION")
- `maxCall`: Maximum concurrent calls (usually 1)
- `callKitImage`: Image name for CallKit UI
- `typePushVoip`: Push type (`TYPE_PUSH_CALLKIT_DEFAULT`, `TYPE_PUSH_CALLKIT_CUSTOM`, etc.)

### 2. Authentication

#### Login with SIP Credentials

```swift
OmiClient.initWithUsername(
    "extension_number",    // e.g., "100"
    password: "password",
    realm: "your_realm",   // e.g., "company.omicall.com"
    proxy: "your_realm:5222"
)

// Configure decline call behavior
OmiClient.configureDeclineCallBehavior(true)
```

#### Logout

```swift
OmiClient.logout()
```

### 3. Making Calls

#### Start Outgoing Call

```swift
OmiClient.startCall("phone_number", isVideo: false) { status in
    switch status {
    case .startCallSuccess:
        print("Call started successfully")
    case .invalidPhoneNumber:
        print("Invalid phone number")
    case .samePhoneNumber:
        print("Cannot call your own number")
    case .permissionDenied:
        print("Microphone permission denied")
    case .couldNotFindEndpoint:
        print("Connection error")
    case .accountRegisterFailed:
        print("Account not registered")
    case .haveAnotherCall:
        print("Another call in progress")
    case .maxRetry:
        print("Max retry reached")
    default:
        print("Unknown error")
    }
}
```

#### End Call

```swift
let sipLib = OMISIPLib.sharedInstance()
if let call = sipLib.getCurrentCall() {
    sipLib.callManager.end(call) { error in
        if let error = error {
            print("Error ending call: \(error)")
        }
    }
}
```

### 4. Call Controls

#### Toggle Mute

```swift
let sipLib = OMISIPLib.sharedInstance()
if let call = sipLib.getCurrentCall() {
    sipLib.callManager.toggleMute(for: call) { error in
        // Handle result
    }
}
```

#### Toggle Hold

```swift
let sipLib = OMISIPLib.sharedInstance()
if let call = sipLib.getCurrentCall() {
    sipLib.callManager.toggleHold(for: call) { error in
        // Handle result
    }
}
```

#### Toggle Speaker

```swift
let sipLib = OMISIPLib.sharedInstance()
let audioController = sipLib.callManager.audioController

// Toggle between speaker and receiver
audioController.output = audioController.output == .speaker ? .other : .speaker
```

#### Send DTMF Tone

```swift
if let call = OMISIPLib.sharedInstance().getCurrentCall(),
   call.callState == .confirmed {
    try? call.sendDTMF("1")  // Send digit 1
}
```

#### Transfer Call (Blind Transfer)

```swift
if let call = OMISIPLib.sharedInstance().getCurrentCall() {
    try? call.blindTransferCall(withNumber: "destination_number")
}
```

### 5. CallKit Integration

Setup CallKit provider delegate:

```swift
import OmiKit

class AppDelegate: NSObject, UIApplicationDelegate {
    var callKitProviderDelegate: CallKitProviderDelegate?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions...) -> Bool {
        // Setup CallKit
        callKitProviderDelegate = CallKitProviderDelegate(
            callManager: OMISIPLib.sharedInstance().callManager
        )
        return true
    }
}
```

### 6. PushKit Integration (VoIP Push)

Setup PushKit for receiving incoming calls when app is in background:

```swift
import PushKit

class PushKitManager: NSObject, PKPushRegistryDelegate {
    init(voipRegistry: PKPushRegistry) {
        super.init()
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
    }

    func pushRegistry(_ registry: PKPushRegistry,
                      didUpdate pushCredentials: PKPushCredentials,
                      for type: PKPushType) {
        let token = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        print("VoIP Token: \(token)")

        // Send token to OmiKit
        OmiClient.setUserPushNotificationToken(token)
    }

    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      completion: @escaping () -> Void) {
        // Handle incoming VoIP push
        OmiClient.receiveIncomingPush(payload.dictionaryPayload)
        completion()
    }
}
```

### 7. Handling Call State Changes

Listen for call state notifications:

```swift
// In AppDelegate or your view
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleCallStateChanged),
    name: NSNotification.Name.OMICallStateChanged,
    object: nil
)

@objc func handleCallStateChanged(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let stateRaw = userInfo[OMINotificationUserInfoCallStateKey] as? Int else {
        return
    }

    // Call states:
    // 0 - null
    // 1 - calling (outgoing)
    // 2 - incoming
    // 3 - early (ringing)
    // 4 - connecting
    // 5 - confirmed (connected)
    // 6 - disconnected
    // 7 - hold
    // 12 - disconnecting

    // Get OMICall object for more info
    if let call = userInfo[OMINotificationUserInfoCallKey] as? OMICall {
        print("Call ID: \(call.callId)")
        print("Is Incoming: \(call.isIncoming)")
        print("Is Video: \(call.isVideo)")
        print("Caller: \(call.callerNumber ?? "")")
    }
}
```

### 8. Handling Call End Reasons

```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleCallDealloc),
    name: NSNotification.Name.OMICallDealloc,
    object: nil
)

@objc func handleCallDealloc(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let endCause = userInfo[OMINotificationEndCauseKey] as? Int else {
        return
    }

    // End cause codes:
    // 486 - Busy
    // 600, 503, 403 - No Answer
    // 480 - Subscriber Busy (Timeout)
    // 408 - Request Timeout
    // 404 - Network Error
    // 603 - Declined
}
```

### 9. Network Quality Monitoring

```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleNetworkQuality),
    name: NSNotification.Name.OMICallNetworkQuality,
    object: nil
)

@objc func handleNetworkQuality(_ notification: Notification) {
    guard let userInfo = notification.userInfo as? [String: Any] else { return }

    // MOS (Mean Opinion Score) - 1.0 (poor) to 5.0 (excellent)
    if let mos = userInfo[OMINotificationMOSKey] as? Float {
        print("Network Quality (MOS): \(mos)")
    }

    // Additional metrics
    if let jitter = userInfo[OMINotificationJitterKey] as? Float {
        print("Jitter: \(jitter)ms")
    }
    if let latency = userInfo[OMINotificationLatencyKey] as? Float {
        print("Latency: \(latency)ms")
    }
    if let packetLoss = userInfo[OMINotificationPPLKey] as? Float {
        print("Packet Loss: \(packetLoss)%")
    }
}
```

### 10. Audio Route Changes

```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleAudioRouteChange),
    name: NSNotification.Name.OMICallAudioRouteChange,
    object: nil
)

@objc func handleAudioRouteChange(_ notification: Notification) {
    guard let userInfo = notification.userInfo as? [String: Any],
          let audioRoute = userInfo["type"] as? String else { return }

    // Audio routes: "Speaker", "Receiver", "Bluetooth", "Headphones"
    print("Audio route: \(audioRoute)")
}
```

### 11. Video Call Info (for Video Calls)

```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleVideoInfo),
    name: NSNotification.Name.OMICallVideoInfo,
    object: nil
)

@objc func handleVideoInfo(_ notification: Notification) {
    if let userInfo = notification.userInfo as? [String: Any] {
        print("Video info: \(userInfo)")
    }
}
```

### 12. Missed Call Notifications

Handle user tapping on missed call notification:

```swift
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions...) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Check for OmiKit missed call notification
        if let _ = userInfo["omisdkCallerNumber"] {
            OmikitNotification.didRecieve(userInfo)
        }

        completionHandler()
    }
}
```

### 13. Get Audio Devices

```swift
// Get available audio input devices
let audioDevices = OmiClient.getAudioInDevices()
// Returns: [[String: String]] with device info

// Set audio output
OmiClient.setAudioOutputs("Speaker")  // or "Receiver", "Bluetooth", etc.
```

### 14. App Lifecycle

Handle app termination:

```swift
func applicationWillTerminate(_ application: UIApplication) {
    OmiClient.omiCloseCall()  // Close any active calls
}
```

## Required Info.plist Keys

```xml
<!-- Background Modes -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>fetch</string>
    <string>processing</string>
    <string>remote-notification</string>
    <string>voip</string>
</array>

<!-- Permissions -->
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to make and receive voice calls.</string>

<key>NSCameraUsageDescription</key>
<string>This app requires camera access to make and receive video calls.</string>
```

## Notification Names Reference

| Notification | Description |
|-------------|-------------|
| `OMICallStateChanged` | Call state changed (calling, ringing, connected, etc.) |
| `OMICallDealloc` | Call ended with reason code |
| `OMICallNetworkQuality` | Network quality metrics (MOS, jitter, latency) |
| `OMICallAudioRouteChange` | Audio output changed |
| `OMICallVideoInfo` | Video call info updated |
| `CallKitProviderDelegateInboundCallAccepted` | Incoming call accepted via CallKit |
| `CallKitProviderDelegateOutboundCallStarted` | Outgoing call started via CallKit |

## Call State Enum

| Value | State | Description |
|-------|-------|-------------|
| 0 | null | No call |
| 1 | calling | Outgoing call initiated |
| 2 | incoming | Incoming call received |
| 3 | early | Call ringing |
| 4 | connecting | Call connecting |
| 5 | confirmed | Call connected |
| 6 | disconnected | Call ended |
| 7 | hold | Call on hold |
| 12 | disconnecting | Call ending |

## Troubleshooting

### VoIP Push Not Working
1. Ensure Push Notifications capability is enabled
2. Verify VoIP background mode is enabled
3. Check that VoIP token is sent to server correctly
4. Verify push certificate is valid and matches bundle ID

### CallKit Not Showing
1. Ensure CallKitProviderDelegate is initialized
2. Check that PushKit is receiving push correctly
3. Verify `OmiClient.receiveIncomingPush()` is called

### Audio Issues
1. Request microphone permission before making calls
2. Check audio session configuration
3. Verify speaker/receiver toggle logic

### Login Failed
1. Verify SIP credentials (username, password, realm)
2. Check network connectivity
3. Ensure proxy format is correct: `realm:5222`

## License

This example is provided as part of the OmiKit SDK. Please refer to the SDK license for usage terms.
