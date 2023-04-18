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
Push notification:
- To setting up details please check here  <a href="https://api.omicall.com/web-sdk/mobile-sdk/ios-sdk/cau-hinh-push-notification">Guide Push notification config Android/IOS</a>.



## Setting up Application

Include the library

```ruby
#import <OmiKit/OmiKit-umbrella.h>
```

Currently we provide 2 way for init user extension for call
1. Init with username/password/real info
```ruby
[OmiClient initWithUsername:MY_USERNAME password:MY_PASSWORD realm:MY_REALM];

```
2. Init witl Apikey
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


To listen event of Call we setting notification:
 ```ruby
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callStateChanged:) name:OMICallStateChangedNotification object:nil];

```

Declare function to get notification:
 ```ruby

- (void)callStateChanged: (NSNotification *)notification {
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak OMICall *call = [[notification userInfo] objectForKey:OMINotificationUserInfoCallKey];
        switch(call.callState)
        {
            case OMICallStateEarly:
                break;
            ....
        }
    });
}

     
```

Listen event Call State to know when call confirm or invite state:
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
Listen event Media event:
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




Using noise cancel( Perfomance slow when lower phone)

 ```ruby
[OmiClient setNoiseSuppression:true];

```


## Get in touch with a developer


We will be happy to answer your other questions at {developer@vihatgroup.com}

## License

OmiKit is Right reversed by VIHATGROUP.
