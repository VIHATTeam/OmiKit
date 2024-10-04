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

    /* Khởi tạo môi trường
#ifdef DEBUG
    * setEnviroment: set môi trường thực hiện của KH (Dev/Production) gồm các enum được OMI định sẵn: KEY_OMI_APP_ENVIROMENT_SANDBOX (dùng cho Dev), KEY_OMI_APP_ENVIROMENT_PRODUCTION (dùng cho production)
    * userNameKey: API Key mà OMI cung cấp
    * maxCall: cuộc gọi đồng thời tại 1 thời điểm. Hiện tại OMICALL chỉ hỗ trợ 1 cuộc gọi.
    * callKitImage: hình ảnh đại điện của DN KH trên UI CallKit của iOS
    * typePushVoip: giá trị mặc là background
    * representName: giá trị không bắt buộc (nếu không dùng, không truyền đối số này xuống). Dùng cho trường hợp KH muốn hiển thị tên đại diện Doanh Nghiệp mình cho tất cả cuộc gọi đến.
    */
#ifdef DEBUG
      [OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_SANDBOX userNameKey:@"full_name" maxCall:1 callKitImage:@"icYourApp" typePushVoip:@"background"];
#else
       [OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_PRODUCTION userNameKey:@"full_name" maxCall:1 callKitImage:@"icYourApp" typePushVoip:@"background"];
#endif


    /* Tiến hành cấu hình VOIP cuộc gọi
    */
    provider = [[CallKitProviderDelegate alloc] initWithCallManager: [OMISIPLib sharedInstance].callManager ];
    voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushkitManager = [[PushKitManager alloc] initWithVoipRegistry:voipRegistry];
    
    [self requestPushNotificationPermissions];

    /* Chúng tôi cung cấp 5 giá trị cho KH log thông tin cuộc gọi cần thiết với các giá trị sau
    *    1 - OMILogVerbose
    *    1 - OMILogDebug
    *    1 - OMILogInfo
    *    1 - OMILogWarning
    *    1 - OMILogError
    */
    [OmiClient setLogLevel:5];
    
    return YES;
}

  /* Tiến hành xin quyền thông báo của thiết bị. Nếu từ chối, OMICall sẽ không push cuộc gọi được đến cho bạn
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

/* Nhận device Token và chuyển nó sang mã hex để lưu trữ token cho Push Call
*/
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

/* Func này quan trọng vì nó sẽ đóng tất cả các cuộc gọi đang diễn ra khi user kill app với hệ thống OMI.
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
   + Func này được dùng cho mục đích: Nhân viên gọi ra cho số viễn thông khác, số nội bộ, số bên ngoài.
   + Các giá trị MY_USERNAME, MY_PASSWORD, MY_REALM, PROXY được lấy thông qua API của OMICall
```Swift
[OmiClient initWithUsername:MY_USERNAME password:MY_PASSWORD realm:MY_REALM, proxy:PROXY];

```
1. Init with Apikey ( For get APIKey please contact sale admin/ customer services)
   + Func được dùng cho trường hợp, khách hành muốn user gọi lên số tổng đài của mình, tương tác với số tổng đài (Khi dùng func này, user sẽ không gọi ra các số viễn thông, số nội bộ khác)
   + Các tham số: 
     + YOUR_ID, YOUR_NAME là các giá trị bất kì bạn đặt cho User của bạn với YOUR_ID dùng để định danh khách hàng. 
     + OMI_API_KEY là gì trị mà OMI cung cấp
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
   + Được dùng cho trường hợp bạn định danh mỗi khách hàng với UUID trước đó và giờ thực hiện gọi đến theo ID đó 
 ```Swift
    [OmiClient startCallWithUuid:(NSString * _Nonnull) toUuid isVideo: (BOOL) isVideo result: (void (^)(OMIStartCallStatus status)) completion {
            // check status here
    }];

```


# Notification callback

## Call notification:

### 1. To listen event of Call we setting notification:
+ Dùng để lắng nghe cuộc gọi trong suốt quá trình gọi hoặc gọi có cuộc gọi đến
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
+ Flow và giá trị của OMICallState
  * `Incoming call` state lifecycle: incoming -> connecting -> confirmed -> disconnected
  * `Outgoing call` state lifecycle: calling -> early -> connecting -> confirmed -> disconnected 

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


### 2. Dùng đề lắng nghe khi cuộc gọi bị kết thúc
+ Dùng để lắng nghe sự kiện khi cuộc gọi bị kết thúc
  
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
            // Thực hiện các thao tác liên quan đến UI hoặc logic khi cuộc gọi kết thúc
        });
    }
}
```

+ các giá trị EndCause
  
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


Ngoài ra còn các event khác như:
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
