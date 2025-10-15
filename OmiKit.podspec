#
# Be sure to run `pod lib lint OmiKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name                  = 'OmiKit'
  s.version               = '1.8.51'
  s.homepage           = "https://micall.com/"
  s.summary            = "Omicall Framework"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Hoang Quoc Viet' => 'viethq@vihat.vn' }

  s.description        = "Omicall easy to make call/video call app2app, app2phone "
  s.homepage           = "https://omicall.com/"
  s.documentation_url  = "https://api.omicall.com/web-sdk/mobile-sdk"

  s.ios.deployment_target = '11.0'
  s.source           = { :git => 'https://github.com/VIHATTeam/OmiKit.git', :tag => s.version.to_s }

  # Configure XCFramework properly
  s.vendored_frameworks = "OmiKit.xcframework"
  
  # Ensure headers are accessible with proper import paths
  s.preserve_paths = 'OmiKit.xcframework'
  
  # Add module map configuration to ensure proper module resolution
  s.module_map = 'OmiKit.xcframework/ios-arm64/OmiKit.framework/Modules/module.modulemap'

  s.libraries = 'stdc++'
  s.frameworks = 'CoreFoundation', 'VideoToolbox', 'AudioToolbox', 'AVFoundation', 'GLKit', 'CFNetwork',  'CoreMedia'
  
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    # Ensure framework headers are found correctly
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/OmiKit',
    'HEADER_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/OmiKit/OmiKit.xcframework/ios-arm64/OmiKit.framework/Headers',
    # Skip missing header files during compilation to avoid PJSIP dependency issues
    'GCC_WARN_ABOUT_MISSING_PROTOTYPES' => 'NO',
    'CLANG_WARN_STRICT_PROTOTYPES' => 'NO'
  }
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/OmiKit',
    'HEADER_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/OmiKit/OmiKit.xcframework/ios-arm64/OmiKit.framework/Headers',
    'GCC_WARN_ABOUT_MISSING_PROTOTYPES' => 'NO',
    'CLANG_WARN_STRICT_PROTOTYPES' => 'NO'
  }

end