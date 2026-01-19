# SwiftUI OmiKit Example

A complete SwiftUI example app demonstrating how to integrate the OmiKit iOS SDK for VoIP calling functionality.

## 📊 Call Flow Diagram

### 📱 Incoming Call Flow

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Remote  │   │OMI Server│   │   APNS   │   │  OmiKit  │   │ CallKit  │   │   App    │
└────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘
     │              │              │              │              │              │
     │  1. INVITE   │              │              │              │              │
     │─────────────>│              │              │              │              │
     │              │  2. VoIP Push│              │              │              │
     │              │─────────────>│              │              │              │
     │              │              │  3. Push payload            │              │
     │              │              │─────────────────────────────>              │
     │              │              │              │  4. VoIPPushHandler.handle()│
     │              │              │              │<─────────────────────────────
     │              │              │              │  5. Report incoming call    │
     │              │              │              │─────────────>│              │
     │              │              │              │              │ 6. Show CallKit UI
     │              │              │              │              │─────────────>│
     │              │              │              │  7. State: incoming (2)     │
     │              │              │              │─────────────────────────────>
     │              │              │              │              │              │
     │              │              │              │  User accepts call          │
     │              │              │              │              │<─────────────│
     │              │              │              │  8. InboundCallAccepted     │
     │              │              │              │<──────────────              │
     │              │              │              │  9. Answer call             │
     │              │  10. 200 OK  │              │<─────────────────────────────
     │<──────────────────────────────────────────│              │              │
     │              │              │              │  11. State: connecting (4)  │
     │              │              │              │─────────────────────────────>
     │              │              │              │  12. State: confirmed (5) ✅│
     │              │              │              │─────────────────────────────>
     │              │              │              │              │  13. Navigate to ActiveCallView
     │              │              │              │              │              │ Start timer, Audio ON
     │              │              │              │              │              │
     │              │    ═══════════ CALL IN PROGRESS ═══════════              │
     │              │              │              │              │              │
     │  14. BYE     │              │              │              │              │
     │─────────────>│              │              │              │              │
     │              │              │              │  15. State: disconnected (6)│
     │              │              │              │─────────────────────────────>
     │              │              │              │  16. OMICallDealloc (602)   │
     │              │              │              │─────────────────────────────>
     │              │              │              │              │  17. Hide call UI
     │              │              │              │              │              │ Stop timer
```

### 📞 Outgoing Call Flow

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│   App    │   │ CallKit  │   │  OmiKit  │   │OMI Server│   │  Remote  │
└────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘
     │              │              │              │              │
     │  1. User taps "Call" button │              │              │
     │  OmiClient.startCall("phone")              │              │
     │─────────────────────────────>              │              │
     │              │  2. Report outgoing call    │              │
     │              │<─────────────│              │              │
     │              │              │              │              │
     │  3. OutboundCallStarted     │              │              │
     │<──────────────              │              │              │
     │              │              │  4. State: calling (1)      │
     │<─────────────────────────────              │              │
     │  Show calling UI            │              │              │
     │              │              │  5. INVITE   │              │
     │              │              │─────────────>│              │
     │              │              │              │─────────────>│
     │              │              │              │  6. Ringing  │
     │              │              │              │<─────────────│
     │              │              │  7. State: early (3)        │
     │<─────────────────────────────              │              │
     │  Show "Ringing..."          │              │              │
     │              │              │              │  8. 200 OK   │
     │              │              │              │<─────────────│
     │              │              │  9. State: connecting (4)   │
     │<─────────────────────────────              │              │
     │              │              │  10. State: confirmed (5) ✅│
     │<─────────────────────────────              │              │
     │  Start timer, Audio ON      │              │              │
     │              │              │              │              │
     │              │    ═══════════ CALL IN PROGRESS ═══════════│
     │              │              │              │              │
     │  11. User ends call         │              │              │
     │  sipLib.callManager.end()   │              │              │
     │─────────────────────────────>              │              │
     │              │              │  12. BYE     │              │
     │              │              │─────────────>│              │
     │              │              │              │─────────────>│
     │              │              │  13. State: disconnected (6)│
     │<─────────────────────────────              │              │
     │              │              │  14. OMICallDealloc (601)   │
     │<─────────────────────────────              │              │
     │  Hide call UI, Stop timer   │              │              │
```

### Key Notifications

| Notification | When | Use For |
|--------------|------|---------|
| **OMICallStateChanged** | Every state transition | Update UI, show/hide call screen, update timer |
| **OMICallDealloc** | When call ends | Show end reason, trigger missed call notification |
| **CallKitProviderDelegateOutboundCallStarted** | User starts call via CallKit | Navigate to ActiveCallView |
| **CallKitProviderDelegateInboundCallAccepted** | User accepts incoming call | Navigate to ActiveCallView, mark as answered |
| **OMICallNetworkQuality** | Periodic during call | Show network quality indicator (MOS score) |

### Call States

| State | Code | Description |
|-------|------|-------------|
| `null` | 0 | No call |
| `calling` | 1 | Outgoing call initiated |
| `incoming` | 2 | Incoming call received |
| `early` | 3 | Call ringing |
| `connecting` | 4 | Call connecting |
| `confirmed` | 5 | Call connected ✅ |
| `disconnected` | 6 | Call ended |
| `hold` | 7 | Call on hold |

## ✨ Features

- SIP authentication (login/logout)
- Outgoing audio/video calls
- Incoming call handling via CallKit
- VoIP push notifications via PushKit
- Call controls (mute, hold, speaker, DTMF)
- Call transfer
- Network quality indicator
- Missed call notifications
- **Two implementation patterns:** Callback-based (CallManager) and Async/Await (CallManagerV2)

## 📋 Requirements

- iOS 13.0+
- Xcode 13.0+ (Xcode 15+ recommended for Swift 6)
- CocoaPods
- OmiKit SDK >= 1.10.8 (for Swift 6 support)

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

## 🏗️ Project Structure

```
SwiftUI-OMICall-Example/
├── SwiftUI_OMICall_ExampleApp.swift  # App entry point & AppDelegate
├── ContentView.swift                  # Root view with call navigation
├── Core/
│   ├── CallManager.swift             # 📌 OmiKit wrapper (CALLBACK-BASED for Swift 5)
│   ├── CallManagerV2.swift           # ⚡ OmiKit wrapper (ASYNC/AWAIT for Swift 6)
│   ├── CallKitProviderDelegate.swift # CallKit integration
│   └── PushKitManager.swift          # VoIP push handling
├── Views/
│   ├── LoginView.swift               # SIP login screen
│   ├── CallingView.swift             # Dialpad & call initiation
│   └── ActiveCallView.swift          # Active call UI & controls
├── docs/
│   
└── Info.plist                        # App configuration
```

## 🔀 Which CallManager Should You Use?

This example provides **two implementations** of the CallManager:

### 📌 CallManager (Callback-Based) - `Core/CallManager.swift`

**Use this if:**
- You're using Swift 5 or earlier
- Your project doesn't use async/await
- You prefer traditional completion handlers
- Maximum compatibility with older iOS versions

**Pattern:**
```swift
// Callback-based pattern
CallManager.shared.startCall(to: "123456789") { status in
    print("Call status: \(status)")
}

// NotificationCenter observers with @objc selectors
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleCallStateChanged),
    name: .OMICallStateChanged,
    object: nil
)
```

**Pros:**
- Works on all Swift versions (5.0+)
- Familiar pattern for Objective-C developers
- Well-tested, production-ready

**Cons:**
- Callback hell for complex flows
- Manual thread management
- More boilerplate code

---

### ⚡ CallManagerV2 (Async/Await) - `Core/CallManagerV2.swift`

**Use this if:**
- You're using Swift 6 Language Mode
- Your project uses modern Swift concurrency (async/await)
- You want cleaner, more maintainable code
- **Requires OmiKit >= 1.10.8**

**Pattern:**
```swift
// Modern async/await pattern
let status = try await CallManagerV2.shared.startCall(to: "123456789")
print("Call status: \(status)")

// Closure-based observers with queue: .main
callStateObserver = NotificationCenter.default.addObserver(
    forName: .OMICallStateChanged,
    object: nil,
    queue: .main
) { [weak self] notification in
    // Extract data BEFORE MainActor context
    guard let userInfo = notification.userInfo,
          let state = userInfo[OMINotificationUserInfoCallStateKey] as? Int
    else { return }

    // Now safely update @Published properties
    MainActor.assumeIsolated {
        self?.callState = state
    }
}
```

**Pros:**
- ✅ **Zero Swift 6 concurrency warnings**
- ✅ Cleaner code with async/await
- ✅ Better error handling with try/catch
- ✅ Automatic thread safety with `@MainActor`
- ✅ No data race risks

**Cons:**
- Requires Swift 6 and OmiKit >= 1.10.8
- Breaking changes if migrating from CallManager

**Swift 6 Optimizations in CallManagerV2:**
1. Uses `@preconcurrency import OmiKit` for smooth interop
2. All NotificationCenter observers use `queue: .main` to force main queue execution
3. Extracts all data from `notification.userInfo` BEFORE entering `MainActor.assumeIsolated` block
4. Posts notifications outside MainActor context to avoid Sendable warnings
5. Fully compliant with Swift 6 strict concurrency checking

---

### 📊 Feature Comparison

| Feature | CallManager | CallManagerV2 |
|---------|-------------|---------------|
| Swift Version | 5.0+ | 6.0+ |
| OmiKit Version Required | Any | Any |
| Pattern | Callbacks | Async/Await |
| Concurrency Warnings | May have warnings on Swift 6 | Zero warnings ✅ |
| Thread Safety | Manual `DispatchQueue.main.async` | Automatic `@MainActor` |
| Error Handling | Completion handlers | `try await` |
| Code Readability | More verbose | Clean & concise |
| Production Ready | ✅ Yes | ✅ Yes |

---

### 🔄 Migration Guide: CallManager → CallManagerV2

If you're upgrading to Swift 6 and want to migrate:

**Before (CallManager):**
```swift
CallManager.shared.login(
    username: "user",
    password: "pass",
    realm: "realm"
) { success in
    if success {
        print("Logged in")
    }
}
```

**After (CallManagerV2):**
```swift
do {
    let success = try await CallManagerV2.shared.login(
        username: "user",
        password: "pass",
        realm: "realm"
    )
    print("Logged in")
} catch {
    print("Login failed: \(error)")
}
```

**Key Changes:**
1. Replace `CallManager` with `CallManagerV2`
2. Add `await` to all async methods
3. Wrap in `do-catch` for error handling
4. Remove completion handler parameters
5. Update Podfile to use OmiKit >= 1.10.8

## 🚀 Quick Start Guide

### Swift 6 Setup (Recommended for New Projects)

**Good news!** OmiKit >= 1.10.8 automatically configures Swift 6 compatibility via the podspec. You only need:

**1. Update your Podfile:**

```ruby
platform :ios, '13.0'

target 'YourApp' do
  use_frameworks!
  pod 'OmiKit', '~> 1.10.8'  # Swift 6 compatible version
end
```

**That's it!** No `post_install` hook needed - OmiKit.podspec handles all Swift 6 configuration automatically.

**2. Set Swift Language Version in Xcode:**
- Select your target → Build Settings
- Search for "Swift Language Version"
- Set to "Swift 6"

**3. In your code, use `@preconcurrency` import:**

```swift
import Foundation
@preconcurrency import OmiKit  // Required for Swift 6

@MainActor
class CallManagerV2: ObservableObject {
    // Your code here
}
```

**What OmiKit.podspec configures automatically:**
- `SWIFT_STRICT_CONCURRENCY = 'minimal'` for OmiKit framework
- `OTHER_SWIFT_FLAGS` with `-Xfrontend -disable-availability-checking`
- Prevents `dispatch_assert_queue_fail` crashes
- Allows your app code to use `SWIFT_STRICT_CONCURRENCY = 'complete'`

---

## Quick Start (Minimal Integration)

### Option 1: CallManagerV2 (Swift 6 - Async/Await)

Use `CallManagerV2` for modern Swift 6 projects. You only need **2 lines of code** in your AppDelegate:

```swift
import SwiftUI
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize OmiKit SDK with async/await pattern
        Task { @MainActor in
            await CallManagerV2.shared.initialize(application: application)
        }

        // Set notification delegate for missed call handling
        UNUserNotificationCenter.current().delegate = CallManagerV2.shared

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        CallManagerV2.shared.cleanup()
    }
}

@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var callManager = CallManagerV2.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(callManager)
        }
    }
}
```

**Using in SwiftUI Views:**

```swift
struct LoginView: View {
    @EnvironmentObject var callManager: CallManagerV2

    var body: some View {
        Button("Login") {
            Task {
                do {
                    let success = try await callManager.login(
                        username: "extension",
                        password: "password",
                        realm: "realm"
                    )
                    print("Login success: \(success)")
                } catch {
                    print("Login error: \(error)")
                }
            }
        }
    }
}

struct CallingView: View {
    @EnvironmentObject var callManager: CallManagerV2

    var body: some View {
        Button("Call") {
            Task {
                do {
                    let status = try await callManager.startCall(to: "0123456789")
                    print("Call status: \(status)")
                } catch {
                    print("Call error: \(error)")
                }
            }
        }
    }
}
```

---

### Option 2: CallManager (Swift 5 - Callback-Based)

The SDK provides a simplified integration through `CallManager`. You only need **2 lines of code** in your AppDelegate:

### AppDelegate Setup

```swift
import SwiftUI
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize OmiKit SDK (handles everything: CallKit, PushKit, observers, notifications)
        CallManager.shared.initialize(application: application)

        // Set notification delegate for missed call handling
        UNUserNotificationCenter.current().delegate = CallManager.shared

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Clean up SDK resources
        CallManager.shared.cleanup()
    }
}

@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var callManager = CallManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(callManager)
        }
    }
}
```

### What `CallManager.shared.initialize()` Does Automatically

- Configures SDK environment (sandbox/production)
- Sets up CallKit provider delegate
- Initializes PushKit for VoIP notifications
- Sets up all notification observers (call state, call end, CallKit events)
- Requests notification permissions
- Handles missed call notifications
- **Manages UI navigation state** (`shouldShowActiveCallView`)

### ContentView with Automatic Call Navigation

The simplest way to handle call UI navigation - just bind to `shouldShowActiveCallView`:

```swift
struct ContentView: View {
    @EnvironmentObject var callManager: CallManager

    var body: some View {
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
```

**That's it!** CallManager automatically:
- Shows `ActiveCallView` when incoming call is accepted
- Shows `ActiveCallView` when outgoing call starts
- Hides `ActiveCallView` when call ends

### Using CallManager Properties in Views

```swift
struct CallingView: View {
    @EnvironmentObject var callManager: CallManager

    var body: some View {
        VStack {
            // Check login status
            if callManager.isLoggedIn {
                Text("Logged in")
            }

            // Check call state
            if callManager.hasActiveCall {
                Text("On call: \(callManager.callState.displayText)")
                Text("Duration: \(callManager.formatDuration(callManager.callDuration))")
            }

            // Make a call
            Button("Call") {
                callManager.startCall(to: "1234567890") { status in
                    print("Call status: \(status)")
                }
            }
        }
    }
}
```

---

## Advanced SDK Integration Guide

### 1. SDK Configuration (Manual)

If you need more control, configure the SDK manually in `AppDelegate.didFinishLaunchingWithOptions`:

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
- `userNameKey`: Key to extract caller name from push payload (e.g., "full_name", "extension")
- `maxCall`: Maximum concurrent calls (usually 1)
- `callKitImage`: Image name for CallKit UI
- `typePushVoip`: Push type (`TYPE_PUSH_CALLKIT_DEFAULT`, `TYPE_PUSH_CALLKIT_CUSTOM`, etc.)

### 2. Authentication

#### Login with SIP Credentials

```swift
// Connect with Sale or Developer for get account testing
OmiClient.initWithUsername(
    "extension_number",    // e.g., "100"
    password: "password", // e.g,. "pKaxGXvzQa8"
    realm: "your_realm",   // e.g., "omicall"
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
    case .invalidUUID:
        print("Invalid UUID - cannot find on my page")
    case .invalidPhoneNumber:
        print("Invalid phone number")
    case .samePhoneNumber:
        print("Cannot call your own number")
    case .maxRetry:
        print("Call timeout exceeded, please try again later")
    case .permissionDenied:
        print("Microphone permission denied")
    case .couldNotFindEndpoint:
        print("Please login before making your call")
    case .accountRegisterFailed:
        print("Can't log in to OMI (maybe wrong login information)")
    case .startCallFail:
        print("Call failed, please try again")
    case .haveAnotherCall:
        print("Another call in progress")
    case .extensionNumberIsOff:
        print("Extension number is off - User has turned off")
    default:
        print("Unknown error")
    }
}
```

#### Start Call Status Reference

| Status | Code | Description |
|--------|------|-------------|
| `INVALID_UUID` | 0 | UUID is invalid (cannot find on my page) |
| `INVALID_PHONE_NUMBER` | 1 | SIP user is invalid |
| `SAME_PHONE_NUMBER_WITH_PHONE_REGISTER` | 2 | Cannot call same phone number |
| `MAX_RETRY` | 3 | Call timeout exceeded, please try again later |
| `PERMISSION_DENIED` | 4 | The user has not granted MIC or audio permissions |
| `COULD_NOT_FIND_END_POINT` | 5 | Please login before making your call |
| `REGISTER_ACCOUNT_FAIL` | 6 | Can't log in to OMI (maybe wrong login information) |
| `START_CALL_FAIL` | 7 | Call failed, please try again |
| `START_CALL_SUCCESS` | 8 | Start call successfully |
| `HAVE_ANOTHER_CALL` | 9 | There is another call in progress; please wait for that call to end |
| `EXTENSION_NUMBER_IS_OFF` | 10 | Extension number off - User has turned off |

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
import OmiKit

class PushKitManager: NSObject, PKPushRegistryDelegate {
    private var voipRegistry: PKPushRegistry

    init(voipRegistry: PKPushRegistry) {
        self.voipRegistry = voipRegistry
        super.init()
        self.voipRegistry.delegate = self
        self.voipRegistry.desiredPushTypes = [.voIP]
    }

    func pushRegistry(_ registry: PKPushRegistry,
                      didUpdate pushCredentials: PKPushCredentials,
                      for type: PKPushType) {
        guard type == .voIP else { return }
        let token = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        print("VoIP Token: \(token)")

        // Send token to OmiKit
        OmiClient.setUserPushNotificationToken(token)
    }

    func pushRegistry(_ registry: PKPushRegistry,
                      didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }
        print("VoIP push token invalidated")
    }

    // CRITICAL: Must report to CallKit immediately or iOS will terminate the app!
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      completion: @escaping () -> Void) {
        guard type == .voIP else {
            completion()
            return
        }

        print("Received VoIP push: \(payload.dictionaryPayload)")

        // IMPORTANT: Use VoIPPushHandler.handle() - NOT OmiClient.receiveIncomingPush()
        // The SDK will report to CallKit internally
        VoIPPushHandler.handle(payload) {
            completion()
        }
    }
}
```

**⚠️ IMPORTANT:** You MUST call `VoIPPushHandler.handle(payload)` when receiving VoIP push.
If you don't report to CallKit immediately, iOS will terminate your app with error:
`"Killing app because it never posted an incoming call to the system after receiving a PushKit VoIP push"`

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

    // Handle end cause - see Call End Cause Reference table below
    print("Call ended with cause: \(endCause)")
}
```

#### Call End Cause Reference

| Code | Description |
|------|-------------|
| **Network & General** |
| 600, 503 | Network operator error or user did not answer the call |
| 408 | Call request timeout (30 seconds waiting time expired) |
| 403 | Service plan only allows calls to dialed numbers. Please upgrade service pack |
| 404 | Current number is not allowed to make calls to the carrier |
| 480 | Number has an error, please contact support |
| **Call Rejection** |
| 486 | The listener refuses the call and does not answer |
| 601 | Call ended by the customer |
| 602 | Call ended by the other employee |
| 603 | Call was rejected. Check account limit or call barring configuration |
| **Limit Exceeded** |
| 850 | Simultaneous call limit exceeded, please try again later |
| 851 | Call duration limit exceeded, please try again later |
| **Account & Service Issues** |
| 852 | Service package not assigned, please contact the provider |
| 853 | Internal number has been disabled |
| 854 | Subscriber is in the DNC (Do Not Call) list |
| 855 | Exceeded allowed number of calls for trial package |
| 856 | Exceeded allowed minutes for trial package |
| 857 | Subscriber has been blocked in the configuration |
| 858 | Unidentified or unconfigured number |
| **Carrier Direction Issues** |
| 859 | No available numbers for Viettel direction, please contact the provider |
| 860 | No available numbers for VinaPhone direction, please contact the provider |
| 861 | No available numbers for Mobifone direction, please contact the provider |
| 862 | Temporary block on Viettel direction, please try again |
| 863 | Temporary block on VinaPhone direction, please try again |
| 864 | Temporary block on Mobifone direction, please try again |
| **Advertising Restrictions** |
| 865 | Advertising number is outside permitted calling hours, please try again later |

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

#### Show Local Notification for Missed Calls

```swift
// Track incoming call info
private var lastIncomingCallerNumber: String = ""
private var wasCallAnswered: Bool = false

// In handleCallStateChanged - track incoming call
if stateRaw == 2 && omiCall.isIncoming { // incoming state
    lastIncomingCallerNumber = omiCall.callerNumber ?? ""
    wasCallAnswered = false
}

if stateRaw == 5 { // confirmed state
    wasCallAnswered = true
}

// In handleCallDealloc - show missed call notification
if !wasCallAnswered && !lastIncomingCallerNumber.isEmpty {
    showMissedCallNotification(callerNumber: lastIncomingCallerNumber)
}

// Show local notification
func showMissedCallNotification(callerNumber: String, callerName: String, callTime: Date) {
    let content = UNMutableNotificationContent()
    content.title = "Missed Call"
    content.body = "You missed a call from \(callerNumber)"
    content.sound = .default
    content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
    content.userInfo = [
        "type": "missed_call",
        "omisdkCallerNumber": callerNumber,
        "omisdkCallerName": callerName
    ]

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(
        identifier: "missed_call_\(UUID().uuidString)",
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request)
}
```

#### Handle User Tap on Notification

```swift
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions...) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Show notification in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle tap on notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if let type = userInfo["type"] as? String, type == "missed_call" {
            let callerNumber = userInfo["omisdkCallerNumber"] as? String ?? ""
            // Handle missed call tap - e.g., navigate to dial screen or call back
            print("User tapped missed call from: \(callerNumber)")
        }

        // Clear badge
        UIApplication.shared.applicationIconBadgeNumber = 0
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

## 📞 Call State Lifecycle

### Incoming Call Lifecycle

```
┌──────────┐    ┌────────────┐    ┌───────────┐    ┌──────────────┐
│ incoming │ -> │ connecting │ -> │ confirmed │ -> │ disconnected │
└──────────┘    └────────────┘    └───────────┘    └──────────────┘
     │                                                     │
     │ (User declines or timeout)                          │
     └─────────────────────────────────────────────────────┘
```

**Flow:**
1. `incoming` (2) - Incoming call received, CallKit UI displayed
2. `connecting` (4) - User accepted, call connecting
3. `confirmed` (5) - Call connected, audio established
4. `disconnected` (6) - Call ended

### Outgoing Call Lifecycle

```
┌─────────┐    ┌───────┐    ┌────────────┐    ┌───────────┐    ┌──────────────┐
│ calling │ -> │ early │ -> │ connecting │ -> │ confirmed │ -> │ disconnected │
└─────────┘    └───────┘    └────────────┘    └───────────┘    └──────────────┘
     │                                                                │
     │ (Call failed, busy, no answer, etc.)                           │
     └────────────────────────────────────────────────────────────────┘
```

**Flow:**
1. `calling` (1) - Outgoing call initiated
2. `early` (3) - Remote party ringing
3. `connecting` (4) - Remote party answered, connecting
4. `confirmed` (5) - Call connected, audio established
5. `disconnected` (6) - Call ended

### Hold/Resume Flow

```
┌───────────┐    ┌──────┐    ┌───────────┐
│ confirmed │ -> │ hold │ -> │ confirmed │
└───────────┘    └──────┘    └───────────┘
```

**Note:** During a call, you can toggle between `confirmed` (5) and `hold` (7) states

## Push Notification Configuration

For detailed push notification setup instructions including:
- Creating VoIP Push Certificate in Apple Developer Portal
- Uploading certificate to OMI system
- Xcode project configuration
- Testing push notifications

Please refer to the official guide:

📖 [Push Notification Configuration Guide](https://omicrm.com/post/detail/mobile-sdk-post89?lng=vi&p=BrwVVWCLGM)

## Troubleshooting

### VoIP Push Not Working
1. Ensure Push Notifications capability is enabled
2. Verify VoIP background mode is enabled
3. Check that VoIP token is sent to server correctly
4. Verify push certificate is valid and matches bundle ID

### CallKit Not Showing
1. Ensure CallKitProviderDelegate is initialized
2. Check that PushKit is receiving push correctly
3. Verify `VoIPPushHandler.handle(payload)` is called in PushKit delegate
4. Check that completion handler is called after `VoIPPushHandler.handle()`

### Audio Issues
1. Request microphone permission before making calls
2. Check audio session configuration
3. Verify speaker/receiver toggle logic

### Login Failed
1. Verify SIP credentials (username, password, realm)
2. Check network connectivity
3. Ensure proxy format is correct: `realm:5222`

## 📚 API Reference

### CallManager (Callback-Based) - Swift 5

#### Initialization

| Method | Description |
|--------|-------------|
| `initialize(application:logLevel:)` | Initialize SDK with all components |
| `cleanup()` | Clean up resources on app termination |

#### Authentication

| Method | Pattern | Description |
|--------|---------|-------------|
| `login(username:password:realm:completion:)` | Callback | Login with SIP credentials |
| `logout()` | Sync | Logout from SIP |

**Example:**
```swift
CallManager.shared.login(
    username: "100",
    password: "password",
    realm: "omicall"
) { success in
    print("Login: \(success)")
}
```

#### Call Operations

| Method | Pattern | Description |
|--------|---------|-------------|
| `startCall(to:isVideo:completion:)` | Callback | Start outgoing call |
| `endCall(completion:)` | Callback | End current call |
| `toggleMute(completion:)` | Callback | Toggle mute state |
| `toggleHold(completion:)` | Callback | Toggle hold state |
| `toggleSpeaker()` | Sync | Toggle speaker |
| `sendDTMF(_:)` | Sync | Send DTMF tone |
| `transferCall(to:)` | Sync | Transfer call |

---

### CallManagerV2 (Async/Await) - Swift 6

#### Initialization

| Method | Pattern | Description |
|--------|---------|-------------|
| `initialize(application:logLevel:)` | `async` | Initialize SDK with all components |
| `cleanup()` | Sync | Clean up resources on app termination |

**Example:**
```swift
Task { @MainActor in
    await CallManagerV2.shared.initialize(application: application)
}
```

#### Authentication

| Method | Pattern | Return Type | Description |
|--------|---------|-------------|-------------|
| `login(username:password:realm:)` | `async throws` | `Bool` | Login with SIP credentials |
| `logout()` | `async` | `Void` | Logout from SIP |

**Example:**
```swift
do {
    let success = try await CallManagerV2.shared.login(
        username: "100",
        password: "password",
        realm: "omicall"
    )
    print("Login success: \(success)")
} catch {
    print("Login error: \(error)")
}
```

#### Call Operations

| Method | Pattern | Return Type | Description |
|--------|---------|-------------|-------------|
| `startCall(to:isVideo:)` | `async throws` | `OMIStartCallStatus` | Start outgoing call |
| `endCall()` | `async throws` | `Void` | End current call |
| `toggleMute()` | `async throws` | `Void` | Toggle mute state |
| `toggleHold()` | `async throws` | `Void` | Toggle hold state |
| `toggleSpeaker()` | Sync | `Void` | Toggle speaker |
| `sendDTMF(_:)` | `async throws` | `Void` | Send DTMF tone |
| `transferCall(to:)` | `async throws` | `Void` | Transfer call |

**Example:**
```swift
// Start call
do {
    let status = try await CallManagerV2.shared.startCall(to: "0123456789")
    if status == .startCallSuccess {
        print("Call started")
    }
} catch {
    print("Call error: \(error)")
}

// Toggle mute
try await CallManagerV2.shared.toggleMute()

// End call
try await CallManagerV2.shared.endCall()
```

---

### Published Properties (Both Versions)

Both `CallManager` and `CallManagerV2` expose the same `@Published` properties for SwiftUI:

| Property | Type | Description |
|----------|------|-------------|
| `isLoggedIn` | `Bool` | SIP login status |
| `hasActiveCall` | `Bool` | Active call status |
| `hasIncomingCall` | `Bool` | Incoming call flag |
| `callState` | `CallStateStatus` / `CallStateStatusV2` | Current call state |
| `callDuration` | `Int` | Call duration in seconds |
| `isMuted` | `Bool` | Mute state |
| `isSpeakerOn` | `Bool` | Speaker state |
| `isOnHold` | `Bool` | Hold state |
| `currentCall` | `OmiCallModel?` / `OmiCallModelV2?` | Current call info |
| `incomingCallerNumber` | `String` | Incoming caller number |
| `incomingCallerName` | `String` | Incoming caller name |
| `shouldShowActiveCallView` | `Bool` | **UI navigation state** - bind to fullScreenCover |

**Usage in SwiftUI:**
```swift
struct CallingView: View {
    // Use either CallManager or CallManagerV2
    @EnvironmentObject var callManager: CallManagerV2

    var body: some View {
        VStack {
            if callManager.isLoggedIn {
                Text("Logged In ✅")
            }

            if callManager.hasActiveCall {
                Text("Call State: \(callManager.callState.displayText)")
                Text("Duration: \(callManager.formatDuration(callManager.callDuration))")
            }

            Text("Muted: \(callManager.isMuted ? "Yes" : "No")")
            Text("Speaker: \(callManager.isSpeakerOn ? "On" : "Off")")
        }
    }
}
```

---

### Computed Properties (Both Versions)

| Property | Type | Description |
|----------|------|-------------|
| `activeCallPhoneNumber` | `String` | Phone number to display for active call |
| `activeCallIsVideo` | `Bool` | Whether active call is video call |

---

### Utilities (Both Versions)

| Method | Description |
|--------|-------------|
| `formatDuration(_:)` | Format seconds to "MM:SS" |
| `getAudioOutputs()` | Get available audio devices |
| `setAudioOutput(_:)` | Set audio output device |

## 📖 Summary: When to Use Each Implementation

### Use CallManager (Callback-Based) If:
- ✅ You're using Swift 5 or cannot upgrade to Swift 6
- ✅ Your codebase uses traditional completion handlers
- ✅ You need maximum compatibility with older projects
- ✅ You're migrating from Objective-C
- 📁 **Reference:** `Core/CallManager.swift`

### Use CallManagerV2 (Async/Await) If:
- ✅ You're starting a new project with Swift 6
- ✅ You want modern async/await syntax
- ✅ You want zero Swift 6 concurrency warnings
- ✅ You prefer cleaner, more maintainable code
- ✅ You have OmiKit >= 1.10.8
- 📁 **Reference:** `Core/CallManagerV2.swift`

### Migration Path:
```
Old Project (Swift 5)     New Project (Swift 6)
     ↓                            ↓
CallManager              CallManagerV2
(Callbacks)              (Async/Await)
     ↓                            ↓
Both work identically for:
- Login/logout
- Make/end calls
- Call controls (mute, hold, speaker, DTMF, transfer)
- @Published properties for SwiftUI
- Missed call notifications
- Network quality monitoring
```

### Quick Decision Matrix:

| Criteria | CallManager | CallManagerV2 |
|----------|-------------|---------------|
| Swift Version | 5.0+ | 6.0+ |
| Learning Curve | Easy (traditional) | Easy (modern) |
| Concurrency Warnings | May appear on Swift 6 | Zero ✅ |
| Code Verbosity | More verbose | Clean & concise |
| Error Handling | Completion handlers | try/catch |
| Thread Safety | Manual | Automatic |
| **Recommendation** | Legacy projects | **New projects** ⭐ |

## 🎯 Getting Started Checklist

- [ ] Install OmiKit via CocoaPods (`pod install`)
- [ ] Choose implementation: CallManager (Swift 5) or CallManagerV2 (Swift 6)
- [ ] If using Swift 6, configure Podfile with `post_install` hook
- [ ] Add `@preconcurrency import OmiKit` in Swift 6 projects
- [ ] Initialize SDK in AppDelegate (`initialize(application:)`)
- [ ] Configure Push Notifications and VoIP capabilities
- [ ] Review the [Call Flow Diagram](docs/call-flow-diagram.svg)
- [ ] Test login with SIP credentials
- [ ] Test outgoing call
- [ ] Test incoming call via VoIP push
- [ ] Implement missed call notifications
- [ ] Test call controls (mute, hold, speaker, DTMF)

## 📞 Support

For technical questions or issues:
- 📧 Email: developer@vihatgroup.com
- 📚 Documentation: [https://api.omicall.com/web-sdk/mobile-sdk](https://api.omicall.com/web-sdk/mobile-sdk)
- 🐛 Report bugs: [GitHub Issues](https://github.com/VIHATTeam/OmiKit/issues)

## License

This example is provided as part of the OmiKit SDK. Please refer to the SDK license for usage terms.

---

**Made with ❤️ by VIHAT Team** | [OmiCall](https://omicall.com) | [API Documentation](https://api.omicall.com)
