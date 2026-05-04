# OmiKit — iOS SDK

[![CocoaPods](https://img.shields.io/cocoapods/v/OmiKit.svg)](https://cocoapods.org/pods/OmiKit)
[![Platform](https://img.shields.io/cocoapods/p/OmiKit.svg)](https://cocoapods.org/pods/OmiKit)
[![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Official iOS SDK for [OMICall](https://omicall.com/) — embed audio/video VoIP calling into your iOS app with minimal setup.

---

## Requirements

| | Minimum |
|---|---|
| iOS | 13.0 |
| Xcode | 14.0 |
| Swift | 5.7 / 6.0 |
| Objective-C | Fully supported |

---

## Installation

### CocoaPods (recommended)

```ruby
platform :ios, '13.0'

pod 'OmiKit'
```

Then run:

```bash
pod install
```

**Specific version:**

```ruby
pod 'OmiKit', '~> 1.11'
```

**From GitHub directly (latest commit):**

```ruby
pod 'OmiKit', :git => 'https://github.com/VIHATTeam/OmiKit.git'
```

### Swift Package Manager

In Xcode → **File → Add Package Dependencies**, paste:

```
https://github.com/VIHATTeam/OmiKit.git
```

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/VIHATTeam/OmiKit.git", from: "1.11.14")
]
```

---

## Quick Start

### Step 1 — Configure Push Notifications

Follow the [Push Notification Setup Guide](https://api.omicall.com/web-sdk/mobile-sdk/ios-sdk/cau-hinh-push-notification) to configure APNs and VoIP push certificates in the OMICall dashboard.

### Step 2 — Configure AppDelegate

```objc
#import <OmiKit/OmiKit-umbrella.h>

@implementation AppDelegate

CallKitProviderDelegate *provider;
PKPushRegistry *voipRegistry;
PushKitManager *pushkitManager;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Set environment (Sandbox for Debug, Production for Release)
#ifdef DEBUG
    [OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_SANDBOX
                userNameKey:@"full_name"
                    maxCall:1
               callKitImage:@"icYourApp"
               typePushVoip:@"background"];
#else
    [OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_PRODUCTION
                userNameKey:@"full_name"
                    maxCall:1
               callKitImage:@"icYourApp"
               typePushVoip:@"background"];
#endif

    // Required: set your Firebase project ID for push delivery
    [OmiClient setFcmProjectId:@"YOUR_FIREBASE_PROJECT_ID"];

    // Set up CallKit and VoIP push
    provider = [[CallKitProviderDelegate alloc] initWithCallManager:[OMISIPLib sharedInstance].callManager];
    voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushkitManager = [[PushKitManager alloc] initWithVoipRegistry:voipRegistry];

    [self requestPushNotificationPermissions];

    // Log level: 1=Verbose, 2=Debug, 3=Info, 4=Warning, 5=Error
    [OmiClient setLogLevel:3];

    return YES;
}

- (void)requestPushNotificationPermissions {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge)
                          completionHandler:^(BOOL granted, NSError *error) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            });
        }
    }];
}

// Forward APNs token to SDK (used for missed-call / cancel push)
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    const char *data = [devToken bytes];
    NSMutableString *token = [NSMutableString string];
    for (NSUInteger i = 0; i < devToken.length; i++) {
        [token appendFormat:@"%02.2hhX", data[i]];
    }
    [OmiClient setUserPushNotificationToken:[token copy]];
}

// Terminate all calls when app is killed
- (void)applicationWillTerminate:(UIApplication *)application {
    [OmiClient OMICloseCall];
}

@end
```

### Step 3 — Initialize User / Extension

**Option A — Username/Password** (for agents making outbound calls to any number):

```objc
[OmiClient initWithUsername:MY_USERNAME
                   password:MY_PASSWORD
                      realm:MY_REALM
                      proxy:PROXY];
```

**Option B — API Key** (for customer-facing call flows, calls routed through call-center only):

```objc
[OmiClient initWithUUID:YOUR_CUSTOMER_ID
               fullName:YOUR_DISPLAY_NAME
                 apiKey:OMI_API_KEY];
```

---

## Making Calls

### Outbound call to a phone number or extension

```objc
[OmiClient startCall:PHONE_NUMBER
             isVideo:NO
              result:^(OMIStartCallStatus status) {
    switch (status) {
        case OMIStartCallSuccess:
            // Call initiated
            break;
        case OMINoNetwork:
            // Show no-network error
            break;
        default:
            break;
    }
}];
```

### Outbound call by customer UUID (API Key mode)

```objc
[OmiClient startCallWithUuid:CUSTOMER_UUID
                     isVideo:NO
                      result:^(OMIStartCallStatus status) {
    // handle status
}];
```

### `OMIStartCallStatus` values

| Value | Description |
|---|---|
| `OMIStartCallSuccess` | Call initiated successfully |
| `OMINoNetwork` | No WiFi or cellular connection |
| `OMIPermissionDenied` | Microphone permission not granted |
| `OMIAccountRegisterFailed` | SIP registration failed |
| `OMICouldNotFindEndpoint` | Endpoint not available |
| `OMIHaveAnotherCall` | Another call is already active |
| `OMIInvalidPhoneNumber` | Phone number is empty |
| `OMIInvalidUuid` | UUID not found |
| `OMISamePhoneNumber` | Calling your own number |
| `OMIMaxRetry` | Max registration attempts exceeded |
| `OMIAccountTurnOffNumberInternal` | Account disabled by admin |
| `OMIStartCallFailed` | Generic call initiation failure |

---

## Call Flow Diagrams

### Incoming Call

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Remote  │   │OMI Server│   │   APNs   │   │  OmiKit  │   │ CallKit  │   │   App    │
└────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘
     │  1. INVITE   │              │              │              │              │
     │─────────────>│  2. VoIP Push│              │              │              │
     │              │─────────────>│  3. Payload  │              │              │
     │              │              │─────────────>│ 4. handle()  │              │
     │              │              │              │─────────────>│ 5. Show UI   │
     │              │              │              │ State: incoming (2)         │
     │              │              │              │─────────────────────────────>
     │              │              │              │         User accepts        │
     │              │              │              │ 6. InboundCallAccepted      │
     │  7. 200 OK   │              │              │<─────────────────────────────
     │<─────────────────────────────────────────────────────────────────────────
     │              │              │              │ State: connecting (4)       │
     │              │              │              │ State: confirmed (5) ✅     │
     │              │              │         ═══ CALL IN PROGRESS ═══          │
     │  8. BYE      │              │              │ State: disconnected (6)     │
     │─────────────>│              │              │─────────────────────────────>
     │              │              │              │ OMICallDealloc (602)        │
```

### Outgoing Call

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│   App    │   │ CallKit  │   │  OmiKit  │   │OMI Server│   │  Remote  │
└────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘
     │ 1. startCall()│              │              │              │
     │─────────────────────────────>│              │              │
     │              │ 2. Report outgoing           │              │
     │              │<─────────────│ State: calling (1)          │
     │<─────────────────────────────              │              │
     │              │              │  3. INVITE   │─────────────>│
     │              │              │              │  4. Ringing  │
     │              │              │ State: early (3)            │
     │              │              │              │  5. 200 OK   │
     │              │              │ State: connecting (4)       │
     │              │              │ State: confirmed (5) ✅     │
     │              │         ═══ CALL IN PROGRESS ═══          │
     │ 6. end()     │              │              │              │
     │─────────────────────────────>│  6. BYE     │─────────────>│
     │              │              │ State: disconnected (6)     │
     │              │              │ OMICallDealloc (601)        │
```

---

## Listening to Call Events

### Call state changes

```objc
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(callStateChanged:)
                                             name:OMICallStateChangedNotification
                                           object:nil];

- (void)callStateChanged:(NSNotification *)notification {
    OMICall *call = [[notification userInfo] objectForKey:OMINotificationUserInfoCallKey];
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (call.callState) {
            case OMICallStateCalling:     // Outgoing — INVITE sent
            case OMICallStateIncoming:    // Incoming — INVITE received
            case OMICallStateEarly:       // Ringing (1xx with To-tag)
            case OMICallStateConnecting:  // 2xx sent/received
            case OMICallStateConfirmed:   // ACK sent/received, call active
            case OMICallStateHold:        // Call on hold
            case OMICallStateDisconnecting:
            case OMICallStateDisconnected:
                break;
        }
    });
}
```

**State lifecycles:**
- Incoming: `Incoming → Connecting → Confirmed → Disconnected`
- Outgoing: `Calling → Early → Connecting → Confirmed → Disconnected`

### Call state reference

| State | Code | Description |
|---|---|---|
| `OMICallStateNull` | 0 | No call |
| `OMICallStateCalling` | 1 | Outgoing INVITE sent |
| `OMICallStateIncoming` | 2 | Incoming INVITE received |
| `OMICallStateEarly` | 3 | Ringing (1xx with To-tag) |
| `OMICallStateConnecting` | 4 | 2xx sent/received |
| `OMICallStateConfirmed` | 5 | ACK sent/received — call active |
| `OMICallStateDisconnected` | 6 | Session terminated |
| `OMICallStateHold` | 7 | Call on hold |
| `OMICallStateDisconnecting` | — | Disconnect in progress |

### Call ended / dealloc

```objc
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(callDealloc:)
                                             name:OMICallDealloc
                                           object:nil];

- (void)callDealloc:(NSNotification *)notification {
    OMIEndCause *endCause = [[notification userInfo] valueForKey:OMINotificationEndCauseKey];
    // use endCause.statusCode to determine reason
}
```

### End cause codes

| Code | Description |
|---|---|
| `601` | Call ended by the customer |
| `602` | Call ended by agent |
| `603` | Call rejected / call barring |
| `408` | Call timeout (30s no answer) |
| `403` | Plan does not allow this destination |
| `404` | Number not allowed on carrier |
| `486` | Called party busy |
| `480`, `503`, `600` | Unavailable / carrier error |
| `850` | Simultaneous call limit exceeded |
| `851` | Call duration limit exceeded |
| `852` | No service package assigned |
| `853` | Internal number disabled |
| `854` | Number in DNC list |
| `855` | Trial call count limit exceeded |
| `856` | Trial minute limit exceeded |
| `857` | Number blocked in configuration |
| `858` | Unidentified/unconfigured number |
| `859–864` | Carrier direction blocked (Viettel/Vinaphone/Mobifone) |
| `865` | Advertising number outside permitted hours |

### Missed call

```objc
[OmiClient setMissedCallBlock:^(OMICall *call) {
    // update missed call UI
}];
```

### Media state changes

```objc
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(callMediaStateChanged:)
                                             name:OMICallMediaStateChangedNotification
                                           object:nil];

- (void)callMediaStateChanged:(NSNotification *)notification {
    OMICallMediaState state = [[[notification userInfo]
        objectForKey:OMINotificationUserInfoCallMediaStateKey] intValue];
    switch (state) {
        case OMICallStateMuted:               break;
        case OMICallStateToggleSpeaker:       break;
        case OMICallStatePermissionCameraDenied:     break;
        case OMICallStatePermissionMicrophoneDenied: break;
    }
}
```

### Network quality (MOS-based)

```objc
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(updateNetworkHealth:)
                                             name:OMICallNetworkQualityNotification
                                           object:nil];

- (void)updateNetworkHealth:(NSNotification *)notification {
    NSNumber *state = [[notification userInfo] valueForKey:OMINotificationNetworkStatusKey];
    switch ([state intValue]) {
        case OMINetworkGood:   // MOS good — show full bars
        case OMINetworkMedium: // MOS medium — show warning
        case OMINetworkBad:    // MOS poor — show alert
            break;
    }
}
```

### All notification keys

| Notification | Trigger |
|---|---|
| `OMICallStateChangedNotification` | Any call state transition |
| `OMICallDealloc` | Call object deallocated (call fully ended) |
| `OMICallMediaStateChangedNotification` | Mute / speaker / permission change |
| `OMICallInComingNotification` | New incoming call |
| `OMICallSwitchBoardAnswerNotification` | Switchboard SIP answered |
| `OMICallNetworkQualityNotification` | Network quality update |
| `OMICallVideoInfoNotification` | Video stream state change |

---

## Video Calls

### Listen for video ready event

```objc
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(videoNotification:)
                                             name:OMICallVideoInfoNotification
                                           object:nil];

- (void)videoNotification:(NSNotification *)notification {
    NSNumber *state = [[notification userInfo] valueForKey:OMIVideoInfoState];
    if ([state intValue] == OMIVideoRemoteReady) {
        [self startVideoPreview];
    }
}
```

### Render local and remote video

```objc
- (void)startVideoPreview {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.remoteVideoView.contentMode = UIViewContentModeScaleAspectFill;
        [self.remoteVideoView setView:[self.videoManager createViewForVideoRemote:self.remoteVideoView.frame]];

        self.localVideoView.contentMode = UIViewContentModeScaleAspectFill;
        [self.localVideoView setView:[self.videoManager createViewForVideoLocal:self.localVideoView.frame]];
    });
}
```

Full Objective-C video call example: [IOS-Objective-VideoCall-Example](https://github.com/VIHATTeam/IOS-Objective-VideoCall-Example)

---

## Audio Settings

### Noise suppression (CPU-intensive on older devices)

```objc
[OmiClient setNoiseSuppression:YES];
```

---

## Swift 6 Compatibility

OmiKit supports Swift 6 from version **1.10.8+**. The podspec and SPM package automatically configure `SWIFT_STRICT_CONCURRENCY = minimal` so no manual build setting changes are required.

**Recommended import in Swift 6:**

```swift
@preconcurrency import OmiKit
```

**Migrating from Swift 5:**
1. Update OmiKit: `pod update OmiKit`
2. Set Swift Language Version → **6** in Build Settings
3. Add `@preconcurrency` to all OmiKit imports

---

## Example Project

A complete SwiftUI example is included under [Example/SwiftUI-OMICall-Example](Example/SwiftUI-OMICall-Example/README.md), demonstrating:

- `CallManager` — traditional callback-based pattern (Swift 5 compatible)
- `CallManagerV2` — modern async/await pattern (Swift 6 optimized)
- Complete incoming/outgoing call flow diagrams
- Full API reference and migration guide

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full release history.

**Latest: v1.11.14** — crash fixes for `OMISIP_timer_init_session`, `NSRangeException` in multi-call, and unmute audio restoration bug.

---

## Support

- Documentation: [api.omicall.com/web-sdk/mobile-sdk](https://api.omicall.com/web-sdk/mobile-sdk)
- Email: developer@vihatgroup.com
- Issues: [github.com/VIHATTeam/OmiKit/issues](https://github.com/VIHATTeam/OmiKit/issues)

---

## License

OmiKit is copyright © VIHAT Group. Released under the [MIT License](LICENSE).
