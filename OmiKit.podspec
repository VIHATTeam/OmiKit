#
# Be sure to run `pod lib lint OmiKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OmiKit'
  s.version          = '1.10.15'
  s.homepage         = "https://omicall.com/"
  s.summary          = "Omicall Framework"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Hoang Quoc Viet' => 'viethq@vihat.vn' }

  s.description      = "Omicall easy to make call/video call app2app, app2phone"
  s.documentation_url = "https://api.omicall.com/web-sdk/mobile-sdk"

  # Xcode 26+ requires minimum iOS 12.0, OmiSIP binary requires iOS 13.0+
  s.ios.deployment_target = '13.0'
  s.source           = { :git => 'https://github.com/VIHATTeam/OmiKit.git', :tag => s.version.to_s }

  # Configure XCFramework properly
  s.vendored_frameworks = "OmiKit.xcframework"

  # Ensure headers are accessible with proper import paths
  s.preserve_paths = 'OmiKit.xcframework'

  # Add module map configuration to ensure proper module resolution
  s.module_map = 'OmiKit.xcframework/ios-arm64/OmiKit.framework/Modules/module.modulemap'

  s.libraries = 'stdc++'
  s.frameworks = 'CoreFoundation', 'VideoToolbox', 'AudioToolbox', 'AVFoundation', 'GLKit', 'CFNetwork', 'CoreMedia'

  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC',
    # Exclude x86_64 simulator - xcframework only has arm64 simulator slice
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'x86_64',
    # Ensure framework headers are found correctly
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/OmiKit',
    'HEADER_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/OmiKit/OmiKit.xcframework/ios-arm64/OmiKit.framework/Headers',
    # Skip missing header files during compilation to avoid PJSIP dependency issues
    'GCC_WARN_ABOUT_MISSING_PROTOTYPES' => 'NO',
    'CLANG_WARN_STRICT_PROTOTYPES' => 'NO',
    # Swift 6 compatibility: Disable strict concurrency checking for OmiKit (Objective-C framework)
    # This prevents dispatch_assert_queue_fail crashes when using Swift 6
    'SWIFT_STRICT_CONCURRENCY' => 'minimal',
    'OTHER_SWIFT_FLAGS' => '$(inherited) -Xfrontend -disable-availability-checking'
  }
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'x86_64',
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/OmiKit',
    'HEADER_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/OmiKit/OmiKit.xcframework/ios-arm64/OmiKit.framework/Headers',
    'GCC_WARN_ABOUT_MISSING_PROTOTYPES' => 'NO',
    'CLANG_WARN_STRICT_PROTOTYPES' => 'NO',
    # Swift 6 compatibility for apps using OmiKit
    'SWIFT_STRICT_CONCURRENCY' => 'minimal'
  }

end
