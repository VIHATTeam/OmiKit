#
# Be sure to run `pod lib lint OmiKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name                  = 'OmiKit'
  s.version               = '1.8.25'
  s.summary               = "OmiKit iOS SDK for VoIP and Video Calling"
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.author                = { 'Hoang Quoc Viet' => 'viethq@vihat.vn' }

  s.description           = <<-DESC
OmiKit is a comprehensive iOS SDK for VoIP and video calling functionality.
It provides easy-to-use APIs for audio/video calls, SIP integration, and call management.
Omicall easy to make call/video call app2app, app2phone.
                          DESC

  s.homepage              = "https://omicall.com/"
  s.documentation_url     = "https://api.omicall.com/web-sdk/mobile-sdk"

  s.ios.deployment_target = '11.0'
  s.source                = { :git => 'https://github.com/VIHATTeam/OmiKit.git', :tag => s.version.to_s }

  s.source_files = 'OmiKit.xcframework/**/OmiKit.framework/Headers/*.h'
  s.public_header_files =  'OmiKit.xcframework/**/OmiKit.framework/Headers/*.h'

  s.libraries = 'stdc++', 'c++'
  
  s.vendored_frameworks = "OmiKit.xcframework"
  
  # Enhanced frameworks list to match source build requirements
  s.frameworks = [
    'Foundation',
    'UIKit', 
    'CoreFoundation',
    'AVFoundation',
    'AudioToolbox',
    'CallKit',
    'PushKit',
    'VideoToolbox',
    'CoreVideo',
    'CoreMedia',
    'CoreGraphics',
    'QuartzCore',
    'CFNetwork',
    'GLKit',
    'Metal',
    'MetalKit',
    'OpenGLES'
  ]
  
  # Build configurations for compatibility
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'CLANG_MODULES_AUTOLINK' => 'YES',
    'CLANG_ENABLE_MODULES' => 'YES',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
  }
  
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }

end