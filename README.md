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

Init use
```ruby
[OmiClient initWithUsername:MY_PHONE_NUMBER password:MY_PHONE_PASSWORD realm:MY_REALM];

```

To make call to Number (Phone or Agent number)
 ```ruby
[OmiClient startCall:self.callPhoneNumberTextField.text];

```


## Get in touch with a developer


We will be happy to answer your other questions at {developer@vihatgroup.com}

## License

OmiKit is Right reversed by VIHATGROUP.
