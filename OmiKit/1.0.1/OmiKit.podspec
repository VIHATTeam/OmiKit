#
# Be sure to run `pod lib lint OmiKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name                  = 'OmiKit'
  s.version               = '1.0.1'
  s.homepage           = "https://omicall.com/"
  s.summary            = "Omicall Framework"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Hoang Quoc Viet' => 'viethq@vihat.vn' }

  s.description        = "Omicall easy to make call/video call app2app, app2phone "
  s.homepage           = "https://omicall.com/"
  s.documentation_url  = "https://api.omicall.com/web-sdk/mobile-sdk"

  s.ios.deployment_target = '13.0'
  s.source           = { :git => 'https://github.com/VIHATTeam/OmiKit.git', :tag => s.version.to_s }


  s.libraries = 'stdc++'
  s.pod_target_xcconfig = {'OTHER_LDFLAGS' => '-ObjC'}

  s.vendored_frameworks = "OmiKit.xcframework"
  s.frameworks = 'CoreFoundation', 'VideoToolbox', 'AudioToolbox', 'AVFoundation', 'GLKit', 'CFNetwork',  'CoreMedia'
  
end