# OMICALL SDK FOR iOS

The OmiKit pod exposes the <a href="http://www.omicall.com/">OMICALL</a> library as Cocoapod.

The most important part of the framework is :
- Help to easy integrate with Omicall.
- Easy custom Call UI/UX.
- By default they are included for all iOS architectures.
- Optimize codec voip for u.
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





### Use

## Setting up
### Step 1:  Setting Push notification:
- To setting up details please check here  <a href="https://api.omicall.com/web-sdk/mobile-sdk/ios-sdk/cau-hinh-push-notification">Guide Push notification config Android/IOS</a>.

### Step 2: Setting AppDelegate

    - Setting Enviroment : it will effect key push notification setting in web base at step 1
    - Inject Callkit Provider Delegate
    - Inject Voip Push notification listener interace
    - Setting Push notification APNS for normal push notification ( we using it in case call cancel from another party)  
Sample Code:
```ruby
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#ifdef DEBUG
    [OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_SANDBOX];
#else
    [OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_PRODUCTION];
#endif

    provider = [[CallKitProviderDelegate alloc] initWithCallManager: [OMISIPLib sharedInstance].callManager ];
    voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushkitManager = [[PushKitManager alloc] initWithVoipRegistry:voipRegistry];
    
    [self requestPushNotificationPermissions];
    [OmiClient setLogLevel:5];
    
    
    return YES;
}

- (void)requestPushNotificationPermissions
{
    // iOS 10+
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        switch (settings.authorizationStatus)
        {
            // User hasn't accepted or rejected permissions yet. This block shows the allow/deny dialog
            case UNAuthorizationStatusNotDetermined:
            {
                center.delegate = self;
                [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error)
                 {
                     if(granted)
                     {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [[UIApplication sharedApplication] registerForRemoteNotifications];
                         });
                     }
                 }];
                break;
            }
            case UNAuthorizationStatusAuthorized:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] registerForRemoteNotifications];
                });
                break;
            }
            default:
                break;
        }
    }];
}

When get notification token, we need update setup client:
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


    
```
### Step 3: Setting the App state
We can listen event app go to background/forground from appdelegate or UIScene or Swift, after that we use this function of library for setting State:

```ruby
[OmiClient setAppplicationState:OMIAppStateForeground];

we have 2 state need to set:
- OMIAppStateForeground
- OMIAppStateBackground
```


###Step 4 Setting up Application

Include the library

```ruby
#import <OmiKit/OmiKit-umbrella.h>
```

Currently we provide 2 way for init user extension for call
1. Init with username/password/real info
```ruby
[OmiClient initWithUsername:MY_USERNAME password:MY_PASSWORD realm:MY_REALM];

```
2. Init with Apikey ( For get APIKey please contact sale admin/ customer services)
```ruby
[OmiClient initWithUUID:(NSString * _Nonnull) fullName:<#(NSString * _Nullable)#> apiKey:<#(NSString * _Nonnull)#>]

```

To make call to Number (Phone or Agent number)
We provide 2 way to make call
1. Start call to real number or Extension
 ```ruby
BOOL result = [OmiClient startCall:(NSString * _Nonnull) isVideo:<#(BOOL)#>];

```

2. Start call with uuid of user and apikey
 ```ruby
    [OmiClient startCallWithUuid:(NSString * _Nonnull) isVideo:<#(BOOL)#>];

```

# Notification callback

## Call notification:

### 1. To listen event of Call we setting notification:
 ```ruby
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callStateChanged:) name:OMICallStateChangedNotification object:nil];

```


Declare function Listen event Call State to know when call confirm or invite state:
Notification key: OMICallStateChangedNotification
Example 
 ```ruby
- (void)callStateChanged: (NSNotification *)notification {
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak  OMICall *call = [[notification userInfo] objectForKey:OMINotificationUserInfoCallKey];
        switch(call.callState)
        {
            case OMICallStateEarly:
                OMILogDebug(@"callStateChanged OMICallStateEarly : %@",call.uuid.UUIDString);
                break;
            case OMICallStateCalling:
                OMILogDebug(@"callStateChanged OMICallStateCalling : %@",call.uuid.UUIDString);
                break;
            case OMICallStateIncoming:{
                OMILogDebug(@"callStateChanged OMICallStateIncoming : %@",call.uuid.UUIDString);
                break;
            }
            case OMICallStateConnecting:
                OMILogDebug(@"callStateChanged OMICallStateConnecting : %@",call.uuid.UUIDString);
                break;
            case OMICallStateConfirmed:{
                OMILogDebug(@"callStateChanged OMICallStateConfirmed : %@",call.uuid.UUIDString);
               
                break;
            }
            case OMICallStateDisconnected:
                OMILogDebug(@"callStateChanged OMICallStateDisconnected : %@",call.uuid.UUIDString);
                break;
        }
    });
}
```

### 2. Listen event Media event:
Notification key: OMICallMediaStateChangedNotification
Example:
```ruby
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

### 3. Listen event call misscall:
```ruby
[Omiclient setMissedCallBlock:^(OMICall * _Nonnull __weak call) {
        <#code#>
}];
```

### 4. Listen the Video call state
when event come we need to re-render video screen

    ### Listen: 
```ruby
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoNotification:) name:OMICallVideoInfoNotification object:nil];
    ```
    ### Process: 
```ruby
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
```ruby    
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

### 5. Listen the network health for update UI instruction for user 
The information we calculator on MOS score and device 3 level bellow
```ruby
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

 ```ruby
[OmiClient setNoiseSuppression:true];

```


## Get in touch with a developer


We will be happy to answer your other questions at {developer@vihatgroup.com}

## License

OmiKit is Right reversed by VIHATGROUP.
