# OMICALL SDK FOR iOS

The OmiKit pod exposes the <a href="http://www.omicall.com/">OMICALL</a> library as Cocoapod.

The most important part of the framework is :
- Help to easy integrate with Omicall.
- Easy custom Call UI/UX.
- Support call Audio and Videos call.
- By default they are included for all iOS architectures
- Optimize codec voip for you
- Full inteface to interactive with core function like sound/ringtone/codec.

## Status
Currently active maintained

### Usage:

## Running
Install via CocoaPods:

```ruby
platform :ios, '13.0'
pod 'OmiKit'
```

Install via Github:

```ruby
platform :ios, '13.0'
pod 'OmiKit', :git => 'https://github.com/VIHATTeam/OmiKit.git'
```

## Swift 6 Compatibility

**OmiKit now supports Swift 6!** Starting from version **1.10.8**, the podspec includes configurations to prevent `dispatch_assert_queue_fail` crashes when using Swift 6.

### What's included:

The podspec automatically configures:
- `SWIFT_STRICT_CONCURRENCY = minimal` - Disables strict concurrency checking for the Objective-C framework
- This allows apps using Swift 6 Language Mode to work seamlessly with OmiKit

### For app developers:

**No additional configuration needed!** When you install OmiKit via CocoaPods:
1. You can use Swift Language Version 6 in your app
2. OmiKit will automatically use minimal concurrency checking
3. Your app code can use `@preconcurrency import OmiKit` for best results

Example in your Swift 6 code:
```swift
import Foundation
@preconcurrency import OmiKit  // Recommended for Swift 6

class CallManager {
    // Your async/await code here
}
```

### Migration from older versions:

If you were previously using Swift 5 to avoid crashes:
1. Update OmiKit to version >= 1.10.8
2. Run `pod update OmiKit`
3. Change Swift Language Version back to 6 in Build Settings
4. Add `@preconcurrency` to your OmiKit imports

## 📱 Example Project

For a complete SwiftUI implementation example, see the [SwiftUI Example Project README](Example/SwiftUI-OMICall-Example/README.md).

The example project includes:
- **Two implementation patterns**:
  - `CallManager` - Traditional callback-based approach (Swift 5 compatible)
  - `CallManagerV2` - Modern async/await approach (Swift 6 optimized)
- **Complete call flow diagrams** for incoming and outgoing calls
- **Step-by-step integration guide** with best practices
- **API reference** and migration guide
- Working example app demonstrating all OmiKit features

📖 **[View complete example documentation →](Example/SwiftUI-OMICall-Example/README.md)**

# Use

## Setting up
### Step 1:  Setting Push notification:
- To setting up details please check here  <a href="https://api.omicall.com/web-sdk/mobile-sdk/ios-sdk/cau-hinh-push-notification">Guide Push notification config Android/IOS</a>.

### Step 2: Setting AppDelegate

    - Setting Enviroment : it will effect key push notification setting in web base at step 1
    - Inject Callkit Provider Delegate
    - Inject Voip Push notification listener interace
    - Setting Push notification APNS for normal push notification ( we using it in case call cancel from another party)  
Sample Code:
```swift
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    /* Initialize environment
#ifdef DEBUG
    * setEnviroment: Sets the execution environment of the client (Dev/Production) which includes predefined enums by OMI: KEY_OMI_APP_ENVIRONMENT_SANDBOX (for Dev), KEY_OMI_APP_ENVIRONMENT_PRODUCTION (for Production)
    * userNameKey: API Key provided by OMI
    * maxCall: The number of simultaneous calls at one time. Currently, OMICALL only supports 1 call at a time.
    * callKitImage: The representative image of the client displayed in the iOS CallKit UI
    * typePushVoip: The default value is "background"
    * representName: This value is optional (if not used, do not pass this argument). It is used when the client wants to display their business's representative name for all incoming calls.
    */
#ifdef DEBUG
      [OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_SANDBOX userNameKey:@"full_name" maxCall:1 callKitImage:@"icYourApp" typePushVoip:@"background"];
#else
       [OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_PRODUCTION userNameKey:@"full_name" maxCall:1 callKitImage:@"icYourApp" typePushVoip:@"background"];
#endif

   /*
    * This function is important because we need to clearly know your PROJECT_ID to push the call
    */
    [OmiClient setFcmProjectId:@YOUR_FIREBASE_PROJECT_ID];


    /* Proceed with configuring VOIP call
    */​
    provider = [[CallKitProviderDelegate alloc] initWithCallManager: [OMISIPLib sharedInstance].callManager ];
    voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushkitManager = [[PushKitManager alloc] initWithVoipRegistry:voipRegistry];
    
    [self requestPushNotificationPermissions];

    /* We provide 5 levels for clients to log necessary call information with the following values:
    *    1 - OMILogVerbose
    *    1 - OMILogDebug
    *    1 - OMILogInfo
    *    1 - OMILogWarning
    *    1 - OMILogError
    */
    [OmiClient setLogLevel:5];
    
    return YES;
}

  /* Proceed to request device notification permissions. If denied, OMICall will not be able to push calls to you
    */
- (void)requestPushNotificationPermissions
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;  
    
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        switch (settings.authorizationStatus)
        {
            case UNAuthorizationStatusNotDetermined:
            case UNAuthorizationStatusAuthorized:
            {
                
                [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge)
                                      completionHandler:^(BOOL granted, NSError * _Nullable error) {
                    if (granted) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[UIApplication sharedApplication] registerForRemoteNotifications];
                        });
                    } else {
                        if (error) {
                            NSLog(@"Error requesting notification authorization: %@", error.localizedDescription);
                        }
                        
                    }
                }];
                break;
            }
            default:
                break;
        }
    }];
}

/* Receive the device Token and convert it to hex format to store the token for Push Call
*/​
- (void)application:(UIApplication*)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)devToken
{
    // parse token bytes to string
    const char *data = [devToken bytes];
    NSMutableString *token = [NSMutableString string];
    for (NSUInteger i = 0; i < [devToken length]; i++)
    {
        [token appendFormat:@"%02.2hhX", data[i]];
    }
    [OmiClient setUserPushNotificationToken:[token copy]];
}

/* This function is important because it will terminate all ongoing calls when the user kills the app with the OMI system.
*/
- (void)applicationWillTerminate:(UIApplication *)application {
    [OmiClient OMICloseCall];
}

```

### Step 3 Setting up Application

Include the library

```Swift
#import <OmiKit/OmiKit-umbrella.h>
```

Currently we provide 2 way for init user extension for call
1. Init with username/password/real info:
 + This function is used for the purpose of: Employees making outgoing calls to other telecom numbers, internal numbers, and external numbers.
+ The values MY_USERNAME, MY_PASSWORD, MY_REALM, and PROXY are obtained through the OMICall API.
```Swift
[OmiClient initWithUsername:MY_USERNAME password:MY_PASSWORD realm:MY_REALM, proxy:PROXY];

```
1. Init with Apikey ( For get APIKey please contact sale admin/ customer services)
  + This function is used when the client wants the user to call their call center number and interact with the call center number (When using this function, the user will not be able to call other telecom numbers or internal numbers).
+ Parameters: 
   + YOUR_ID, YOUR_NAME are arbitrary values you assign to your user, with YOUR_ID used to identify the customer.
   + OMI_API_KEY is the value provided by OMI.
```Swift
 [OmiClient initWithUUID:YOUR_ID fullName:YOUR_NAME apiKey:OMI_API_KEY];

```

To make call to Number (Phone or Agent number)
We provide 2 way to make call
1. Start call to real number or Extension:
    + Used to initiate a call to any number.
    + isVideo: Boolean to determine whether it’s a regular call or a video call.
    + result: A callback function that returns the value of OMIStartCallStatus after attempting the call.

| Value   | Mean  |
|------------|------------|
| OMIInvalidUuid | UUID not found when starting a call with UUID. |
| OMIInvalidPhoneNumber | The phone number for the outgoing call is empty. |
| OMISamePhoneNumber | The outgoing phone number is the same as the logged-in user’s number |
| OMIMaxRetry | Exceeded the maximum number of registration attempts with the server |
| OMIPermissionDenied | Microphone permissions have not been granted. |
| OMICouldNotFindEndpoint | Unable to find the endpoint; possible account registration error. |
| OMIAccountRegisterFailed | Failed to register the session with the server. |
| OMIStartCallFailed | Failed to initiate the call.  |
| OMIStartCallSuccess | The call was successfully initiated. |
| OMIHaveAnotherCall | Another ongoing call has not ended. |
| OMIAccountTurnOffNumberInternal | The account is disabled by the business owner. |



 ```Swift
BOOL result = [OmiClient startCall:PHONE_NUMBER isVideo:FALSE result:^(OMIStartCallStatus status){
        // check status here
    }];

```

1. Start call with uuid of user and apikey
+ Used in cases where you have previously identified each customer with a UUID and now make a call based on that ID.
 ```Swift
    [OmiClient startCallWithUuid:(NSString * _Nonnull) toUuid isVideo: (BOOL) isVideo result: (void (^)(OMIStartCallStatus status)) completion {
            // check status here
    }];

```


# Notification callback

## Call notification:

### 1. To listen event of Call we setting notification:
+ Used to listen for calls throughout the calling process or when there is an incoming call.
 ```Swift
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callStateChanged:) name:OMICallStateChangedNotification object:nil];

```


Declare function Listen event Call State to know when call confirm or invite state:
Notification key: OMICallStateChangedNotification

Example: 
 ```Swift
- (void)callStateChanged: (NSNotification *)notification {
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak  OMICall *call = [[notification userInfo] objectForKey:OMINotificationUserInfoCallKey];
        switch(call.callState)
        {
            case OMICallStateEarly:
                OMILogDebug(@"callStateChanged OMICallStateEarly : %@", call.uuid.UUIDString);
                break;
            case OMICallStateCalling:
                OMILogDebug(@"callStateChanged OMICallStateCalling : %@", call.uuid.UUIDString);
                break;
            case OMICallStateIncoming:{
                OMILogDebug(@"callStateChanged OMICallStateIncoming : %@", call.uuid.UUIDString);
                break;
            }
            case OMICallStateConnecting:
                OMILogDebug(@"callStateChanged OMICallStateConnecting : %@", call.uuid.UUIDString);
                break;
            case OMICallStateConfirmed:{
                OMILogDebug(@"callStateChanged OMICallStateConfirmed : %@", call.uuid.UUIDString);
                break;
            }
            case OMICallStateDisconnected:
                OMILogDebug(@"callStateChanged OMICallStateDisconnected : %@", call.uuid.UUIDString);
                break;
        }
    });
}
```
+ Flow and values of OMICallState
  * `Incoming call` state lifecycle: incoming -> connecting -> confirmed -> disconnected
  * `Outgoing call` state lifecycle: calling -> early -> connecting -> confirmed -> disconnected​⬤

| Value   | Mean  |
|------------|------------|
| OMICallStateNull | Before INVITE is sent or received |
| OMICallStateCalling | After INVITE is sent |
| OMICallStateIncoming | After INVITE is received |
| OMICallStateEarly | After response with To tag. |
| OMICallStateConnecting | After 2xx is sent/received. |
| OMICallStateConfirmed | After ACK is sent/received. |
| OMICallStateDisconnected | Session is terminated. |
| OMICallStateHold | User toggle hold |
| OMICallStateDisconnecting |Call being request disconnect |


### 2. Used to listen for when a call is terminated.
+ Used to listen for the event when a call is terminated.​
  
 ```Swift
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callDealloc:) name:OMICallDealloc object:nil];

```


Example: 
 ```Swift
- (void)callDealloc:(NSNotification *)notification {
    OMIEndCause *endCause = (OMIEndCause *)[[notification userInfo] valueForKey:OMINotificationEndCauseKey];
    
    OMICall *call = [OMISIPLib.sharedInstance getCurrentConfirmCall];
    if (call != nil && [call.uuid isEqual:self.callId]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Perform actions related to UI or logic when the call is terminated.
        });
    }
}
```

+ EndCause values:
  
| EndCause   | Mean  |
|------------|------------|
| `600, 503, 480`  | These are the codes of the network operator or the user who did not answer the call  |
| `408`   | Call request timeout (Each call usually has a waiting time of 30 seconds. If the 30 seconds expire, it will time out) |
| `403`           | Your service plan only allows calls to dialed numbers. Please upgrade your service pack|
| `404`           | The current number is not allowed to make calls to the carrier|
| `603`           | The call was rejected. Please check your account limit or call barring configuration! |
| `850`           | Simultaneous call limit exceeded, please try again later |
| `486`           | The listener refuses the call and does not answer |
| `601`           | Call ended by the customer |
| `602`           | Call ended by the other employee |
| `603`           | The call was rejected. Please check your account limit or call barring configuration |
| `850`           | Simultaneous call limit exceeded, please try again later |
| `851`           | Call duration limit exceeded, please try again later |
| `852`           | Service package not assigned, please contact the provider |
| `853`           | Internal number has been disabled |
| `854`           | Subscriber is in the DNC list |
| `855`           | Exceeded the allowed number of calls for the trial package |
| `856`           | Exceeded the allowed minutes for the trial package |
| `857`           | Subscriber has been blocked in the configuration |
| `858`           | Unidentified or unconfigured number |
| `859`           | No available numbers for Viettel direction, please contact the provider |
| `860`           | No available numbers for VinaPhone direction, please contact the provider |
| `861`           | No available numbers for Mobifone direction, please contact the provider |
| `862`           | Temporary block on Viettel direction, please try again |
| `863`           | Temporary block on VinaPhone direction, please try again |
| `864`           | Temporary block on Mobifone direction, please try again |
| `865`           | he advertising number is currently outside the permitted calling hours, please try again later |


### 3. Listen event Media event:
Notification key: OMICallMediaStateChangedNotification
Example:
```Swift
- (void)callMediaStateChanged: (NSNotification *)notification {
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        OMICallMediaState mediaState = (OMICallMediaState)[[notification userInfo] objectForKey:OMINotificationUserInfoCallMediaStateKey];
        switch(mediaState)
        {
            case OMICallStateMuted:
                OMILogDebug(@"OMICallMediaState OMICallStateMuted");
                break;
            case OMICallStateToggleSpeaker:
                OMILogDebug(@"OMICallMediaState OMICallStateToggleSpeaker");
                break;
            case OMICallStatePermissionCameraDenied:
                OMILogDebug(@"OMICallMediaState OMICallStateToggleSpeaker");
                break;
            case OMICallStatePermissionMicrophoneDenied:
                OMILogDebug(@"OMICallMediaState OMICallStateToggleSpeaker");
                break;
            
        }
    });
}
```


## Additionally, there are other events such as:
  - `NSNotification.Name.OMICallMediaStateChangedNotification`: Audio changed.
  - `NSNotification.Name.OMICallMediaStateChangedNotification`: Audio changed.
  - `NSNotification.Name.OMICallInComingNotification`: When have new incomming call.
  - `NSNotification.Name.OMICallSwitchBoardAnswerNotification`: Switchboard sip is listening.
  - `NSNotification.Name.OMICallNetworkQuality`: The calling quality.
  

### 4. Listen event call misscall:
```Swift
[Omiclient setMissedCallBlock:^(OMICall * _Nonnull __weak call) {
        <#code#>
}];
```

### 5. Listen the Video call state
when event come we need to re-render video screen
Detail sample project can view here: https://github.com/VIHATTeam/IOS-Objective-VideoCall-Example

    ### Listen: 
```Swift
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoNotification:) name:OMICallVideoInfoNotification object:nil];
 ```
    ### Process: 
```Swift
    -(void) videoNotification:(NSNotification *) noti {
        NSDictionary *dic = [noti userInfo];
        NSNumber * state = [dic valueForKey:OMIVideoInfoState];
        switch([state intValue]){
            case OMIVideoRemoteReady:{
                [self startPreview];
                break;
            }
        }
    }
```
    ### Show Video Preview:
```Swift    
    - (void)startPreview {
        __weak typeof(self) weakSelf = self;
        if(!_remoteVideoRenderView || !_localVideoRenderView) return;
        
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.remoteVideoRenderView.contentMode = UIViewContentModeScaleAspectFill;
                [weakSelf.remoteVideoRenderView setView:[self.videoManager createViewForVideoRemote:weakSelf.remoteVideoRenderView.frame]];
                weakSelf.localVideoRenderView.contentMode = UIViewContentModeScaleAspectFill;
                [weakSelf.localVideoRenderView setView:[self.videoManager createViewForVideoLocal:weakSelf.localVideoRenderView.frame]];
            });
    }

```

### 6. Listen the network health for update UI instruction for user 
The information we calculator on MOS score and device 3 level bellow
```Swift
    Listen: 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNetworkHealth:) name:OMICallNetworkQualityNotification object:nil];
    
    Process: 
    
    -(void) updateNetworkHealth:(NSNotification *) noti {
        NSDictionary *dic = [noti userInfo];
        NSNumber * state = [dic valueForKey:OMINotificationNetworkStatusKey];
        switch([state intValue]){
            case OMINetworkGood:{
                [self.networkStatus setImage: [UIImage imageNamed: @"network_best"]];
                break;
            }
            case OMINetworkMedium:{
                [self.networkStatus setImage: [UIImage imageNamed: @"network_medium"]];
                break;
            }
            case OMINetworkBad:{
                [self.networkStatus setImage: [UIImage imageNamed: @"network_bad"]];
                break;
            }
        }
    }


```


Using noise cancel( Perfomance slow when lower phone)

 ```Swift
[OmiClient setNoiseSuppression:true];

```


## Get in touch with a developer


We will be happy to answer your other questions at {developer@vihatgroup.com}

## License

OmiKit is Right reversed by VIHATGROUP.
