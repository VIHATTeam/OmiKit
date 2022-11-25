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
platform :ios, '9.0'
pod 'OmiKit'
```

Install via Github:

```ruby
platform :ios, '9.0'
pod 'OmiKit', :git => 'https://github.com/VIHATTeam/OmiKit.git'
```





### Use

Include the library

```ruby
#import <OmiKit/OmiKit.h>
```

Init use
```ruby
[OmiClient initWithUsername:MY_PHONE_NUMBER password:MY_PHONE_PASSWORD realm:MY_REALM];

```

To make call to Number (Phone or Agent number)
 ```ruby
[OmiClient startCall:phoneNumber];

```

To make VideoCall to Number (Phone or Agent number)
 ```ruby
[OmiClient startVideoCall:phoneNumber];

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
            case OMICallStateCalling:
                break;
            case OMICallStateIncoming:
                break;
            case OMICallStateConnecting:
                break;
            case OMICallStateConfirmed:
                break;
            case OMICallStateDisconnected:
                break;

        }
    });
}

```


## Get in touch with a developer


We will be happy to answer your other questions at {developer@vihatgroup.com}

## License

OmiKit is Right reversed by VIHATGROUP.
