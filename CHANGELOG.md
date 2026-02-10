# Changelog

All notable changes to this project will be documented in this file.


## [1.10.24](https://github.com/VIHATTeam/OmiKit.git) (10/02/2026)

### Security
- **Disabled sensitive API body logging** in `sendAgentCustomerRequest` (OmiClient.m) and `HttpRequest.m` to prevent credential exposure in logs

### Fixed
- **Critical: NSRangeException crash in lookupAccount** - Fixed thread safety issue where PJSIP thread reads `accounts` array while main thread deallocates via `removeAccount:`. Applied atomic property + NSLock + copy-inside-lock pattern (OMIEndpoint.m)
- **Critical: NSRangeException crash in callWithCallId** - Fixed same thread safety pattern in OMICallManager for `calls` array during concurrent access from PJSIP and main threads (OMICallManager.m)
- **Critical: pjmedia_codec_mgr_enum_codecs crash** - Fixed race condition when enumerating codecs before PJSIP codec manager fully initialized. Added 300ms delay, retry logic with exponential backoff, and NULL checks (OMIEndpoint.m)
- **Critical: PushKit NSInternalInconsistencyException** - Fixed app termination due to unhandled exceptions in VoIP push handler. Wrapped async SIP/Audio setup in @try-@catch-@finally to prevent PushKit 20s timeout kill (VoIPPushHandler.m)
- **Property update order in OMICall.updateCallInfo** - Reordered property updates to set `callState` LAST, preventing notification observers from receiving stale `lastStatus`/`lastStatusText` values (OMICall.m)
- **OMICall dealloc notification timing** - Fixed strong reference cycles preventing timely deallocation. Use `__weak self` in dispatch_after blocks and cleanup `disconnectedSoundPlayer` before removeCall (OMICall.m)
- **refreshMiddlewareRegistration validation** - Added proper validation to only call API when user is logged in with Agent/Customer flow. Fixed stale session data causing API errors on app startup (OmiClient.m)
- **UUID validation in refreshMiddlewareRegistration** - Made UUID optional (not required for refresh API) to fix false-positive validation failures

### Changed
- Added `lastStatusText` to OMICallDeallocNotification userInfo dictionary for better call end status tracking
- Added comprehensive logging for call state changes and dealloc events in ViewController for debugging
- Improved error logging with status code descriptions (Busy, Declined, etc.)

## [1.10.23](https://github.com/VIHATTeam/OmiKit.git) (06/02/2026)
- Remove Log


## [1.10.22](https://github.com/VIHATTeam/OmiKit.git) (06/02/2026)
- Update func for user
- Add field isSkipDevices for func register 

## [1.10.15, 1.10.16, 1.10.17, 1.10.18, 1.10.19](https://github.com/VIHATTeam/OmiKit.git) (04/02/2026)
- add log debug call video

## [1.10.14](https://github.com/VIHATTeam/OmiKit.git) (04/02/2026)
- Fix, call video and crash pj_atomic


## [1.10.12](https://github.com/VIHATTeam/OmiKit.git) (03/02/2026)
- Rebuild SDK, optimizes call video


## [1.10.11](https://github.com/VIHATTeam/OmiKit.git) (29/01/2026)
- Remove key BGTaskSchedulerPermittedIdentifiers at example 


## [1.10.9](https://github.com/VIHATTeam/OmiKit.git) (26/01/2026)
- Add Turn/Sturn/ICE when calling 
- Remove character "text" in switchboard SDP 

## [1.10.8](https://github.com/VIHATTeam/OmiKit.git) (16/01/2026)

### 🎉 Swift 6 Full Support

**BREAKING CHANGE:** Now requires iOS 13.0+ (up from 11.0)

This release brings complete Swift 6 compatibility with zero concurrency warnings!

### Core SDK Changes

- ✅ Fixed `dispatch_assert_queue_fail` crashes when using Swift 6 strict concurrency
- ✅ Added `SWIFT_STRICT_CONCURRENCY = minimal` configuration to podspec
- ✅ Added `OTHER_SWIFT_FLAGS` with `-Xfrontend -disable-availability-checking`
- ✅ Automatically configures projects to use Swift 6 with proper concurrency settings
- ✅ OmiKit (Objective-C) uses minimal concurrency checking
- ✅ App code can use complete Swift 6 concurrency checking
- ✅ No code changes required for apps using CocoaPods
- ✅ Seamless integration with Swift 6 Language Mode

### Example Project - CallManagerV2 (New)

Added **CallManagerV2** - Modern async/await implementation with zero Swift 6 warnings:

**File:** `Example/SwiftUI-OMICall-Example/Core/CallManagerV2.swift`

**Features:**
- ✅ Full async/await API (login, startCall, endCall, toggleMute, etc.)
- ✅ Zero Swift 6 concurrency warnings
- ✅ Zero data race risks
- ✅ `@MainActor` isolation for thread safety
- ✅ `@preconcurrency import OmiKit` for smooth interop
- ✅ All NotificationCenter observers use `queue: .main`
- ✅ Extract userInfo BEFORE MainActor.assumeIsolated to avoid Sendable warnings
- ✅ Post notifications outside MainActor context
- ✅ 137 lines removed (11% reduction from 1236 to 1099 lines)
- ✅ Optimized notification handling with inline processing

**Swift 6 Pattern Improvements:**
```swift
// OLD (caused warnings):
) { [weak self] notification in
    MainActor.assumeIsolated {
        let userInfo = notification.userInfo  // ❌ Sendable warning
    }
}

// NEW (zero warnings):
) { [weak self] notification in
    // Extract data BEFORE MainActor context
    guard let userInfo = notification.userInfo,
          let value = userInfo[key] as? Type
    else { return }

    // Now safely update @Published properties
    MainActor.assumeIsolated {
        self?.property = value
    }
}
```

**API Comparison:**

| CallManager (Swift 5) | CallManagerV2 (Swift 6) |
|----------------------|-------------------------|
| `startCall(to:completion:)` | `try await startCall(to:)` |
| `login(username:completion:)` | `try await login(username:)` |
| Callbacks | Async/Await |
| Manual DispatchQueue | Automatic @MainActor |
| May have warnings | Zero warnings ✅ |

### Example Project - CallManager (Updated)

**File:** `Example/SwiftUI-OMICall-Example/Core/CallManager.swift`

Remains available for Swift 5 compatibility:
- Traditional callback-based pattern
- Works on Swift 5.0+
- Fully compatible with legacy codebases

### Documentation

**New Files:**
- ✅ `Example/SwiftUI-OMICall-Example/SWIFT6_SETUP.md` - Setup guide
- ✅ `Example/SwiftUI-OMICall-Example/SWIFT6_FIX_SUMMARY.md` - Technical details
- ✅ `Example/SwiftUI-OMICall-Example/CALLMANAGERV2_OPTIMIZATION.md` - Optimization summary
- ✅ `Example/SwiftUI-OMICall-Example/docs/call-flow-diagram.svg` - Visual call flow diagram

**Updated Files:**
- ✅ `README.md` - Added Swift 6 compatibility section
- ✅ `Example/SwiftUI-OMICall-Example/README.md` - Comprehensive guide with:
  - Call flow diagram (incoming/outgoing)
  - CallManager vs CallManagerV2 comparison
  - Migration guide Swift 5 → Swift 6
  - Quick start for both versions
  - API reference for both versions
  - Decision matrix for choosing implementation

### Migration Guide

**From Swift 5 → Swift 6:**

1. Update Podfile to OmiKit >= 1.10.8
2. Add post_install hook for Swift 6 configuration
3. Choose implementation:
   - Keep using `CallManager` (works on Swift 6)
   - Migrate to `CallManagerV2` for async/await benefits

**CallManager → CallManagerV2 Migration:**

```swift
// Before (CallManager)
CallManager.shared.login(username: "user", password: "pass", realm: "realm") { success in
    print("Login: \(success)")
}

// After (CallManagerV2)
do {
    let success = try await CallManagerV2.shared.login(
        username: "user",
        password: "pass",
        realm: "realm"
    )
    print("Login: \(success)")
} catch {
    print("Error: \(error)")
}
```

### Configuration

**Podfile setup for Swift 6:**

```ruby
platform :ios, '13.0'

target 'YourApp' do
  use_frameworks!
  pod 'OmiKit', '~> 1.10.8'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '6.0'

      if target.name == 'OmiKit'
        config.build_settings['SWIFT_STRICT_CONCURRENCY'] = 'minimal'
      else
        config.build_settings['SWIFT_STRICT_CONCURRENCY'] = 'complete'
      end
    end
  end
end
```

### Testing

All Swift 6 features tested on:
- ✅ Xcode 15.0+
- ✅ iOS 13.0 - 17.0
- ✅ Swift Language Mode: 6.0
- ✅ SWIFT_STRICT_CONCURRENCY: complete
- ✅ Zero compiler warnings
- ✅ Zero runtime crashes
- ✅ All call flows (incoming, outgoing, transfer, hold)

### Known Issues

None. This release is production-ready for Swift 6.

### Upgrade Instructions

```bash
# Update Podfile
pod 'OmiKit', '~> 1.10.8'

# Install
pod install

# Clean build
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## [1.10.7](https://github.com/VIHATTeam/OmiKit.git) (14/01/2026)
- Fix force GPU Call Video

## [1.10.1, 1.10.3, 1.10.4, 1.10.5](https://github.com/VIHATTeam/OmiKit.git) (13/01/2026)
- Fix force GPU Call Video


## [1.9.44, 1.9.45, 1.9.46, 1.9.47, 1.9.49](https://github.com/VIHATTeam/OmiKit.git) (13/01/2026)
- Fix force GPU Call Video

## [1.9.42, 1.9.43](https://github.com/VIHATTeam/OmiKit.git) (12/01/2026)
- Fix force GPU Call Video

## [1.9.41](https://github.com/VIHATTeam/OmiKit.git) (12/01/2026)
- Fix GPU Call Video


## [1.9.35, 1.9.36, 1.9.37](https://github.com/VIHATTeam/OmiKit.git) (09/01/2026)
- Fix GPU SDK Call video

## [1.9.31, 1.9.32, 1.9.33, 1.9.34](https://github.com/VIHATTeam/OmiKit.git) (08/01/2026)
- Fix GPU SDK Call video

## [1.9.29](https://github.com/VIHATTeam/OmiKit.git) (08/01/2026)
- Giảm chất lượng video

## [1.9.28](https://github.com/VIHATTeam/OmiKit.git) (08/01/2026)
- Fix call video

## [1.9.26, 1.9.27](https://github.com/VIHATTeam/OmiKit.git) (08/01/2026)
- Fix call video


## [1.9.25](https://github.com/VIHATTeam/OmiKit.git) (08/01/2026)
- Tăng thời gian delay


## [1.9.24](https://github.com/VIHATTeam/OmiKit.git) (08/01/2026)
- Chặn điều chỉnh Opus khi cuộc gọi chưa nghe
- Fix đứng màn hình remote call trên call video



## [1.9.22, 1.9.23](https://github.com/VIHATTeam/OmiKit.git) (05/01/2026)
- Tăng delay video call


## [1.9.21](https://github.com/VIHATTeam/OmiKit.git) (30/12/2025)
- Fix answer call at background off call video 

## [1.9.18, 1.9.19](https://github.com/VIHATTeam/OmiKit.git) (29/12/2025)
- Improve call video


## [1.9.16, 1.9.17](https://github.com/VIHATTeam/OmiKit.git) (26/12/2025)
- Improve call video



## [1.9.14, 1.9.15](https://github.com/VIHATTeam/OmiKit.git) (25/12/2025)
- Fix scale và zoom video 


## [1.9.13](https://github.com/VIHATTeam/OmiKit.git) (24/12/2025)
- Fix reload video chậm 

## [1.9.12](https://github.com/VIHATTeam/OmiKit.git) (21/12/2025)
- Fix bản tin re-invite vẫn gửi khi disconect call 

## [1.9.9, 1.9.11](https://github.com/VIHATTeam/OmiKit.git) (20/12/2025)
- Fix reload video chậm

## [1.9.7, 1.9.8](https://github.com/VIHATTeam/OmiKit.git) (19/12/2025)
- Tối ưu code flow nhận call
- Tối ưu render Metal cho call video


## [1.9.6](https://github.com/VIHATTeam/OmiKit.git) (18/12/2025)
- Re-build Sip 2.16
- Optimize call video

## [1.9.5](https://github.com/VIHATTeam/OmiKit.git) (18/12/2025)
- Update Sip 2.16
- Optimize call video

## [1.9.4](https://github.com/VIHATTeam/OmiKit.git) (08/12/2025)
- Fix open call video from background 

## [1.9.3](https://github.com/VIHATTeam/OmiKit.git) (05/12/2025)
- Fix crash call video

## [1.9.2](https://github.com/VIHATTeam/OmiKit.git) (04/12/2025)
- Fix crash call video


## [1.9.1](https://github.com/VIHATTeam/OmiKit.git) (04/12/2025)
- Build new version OMISIP 2.16
- Fix call video

## [1.8.61](https://github.com/VIHATTeam/OmiKit.git) (28/11/2025)
- Fix crash call video 


## [1.8.58, 1.8.59](https://github.com/VIHATTeam/OmiKit.git) (25/11/2025)
- Fix call video 

## [1.8.56](https://github.com/VIHATTeam/OmiKit.git) (19/10/2025)
- Fix crash when end call
- Optimize call video

## [1.8.54](https://github.com/VIHATTeam/OmiKit.git) (12/10/2025)
- Fix ice, turn and fix re-invite switch board
  

## [1.8.52](https://github.com/VIHATTeam/OmiKit.git) (16/10/2025)
- Update API remove devices info

## [1.8.51](https://github.com/VIHATTeam/OmiKit.git) (15/10/2025)
- Fix 4g network mobifone not send register to switch board

## [1.8.48](https://github.com/VIHATTeam/OmiKit.git) (14/10/2025)
- RollBack fix call 4g ios 

## [1.8.47](https://github.com/VIHATTeam/OmiKit.git) (07/10/2025)
- Hot fix crash incoming call at background 

## [1.8.46](https://github.com/VIHATTeam/OmiKit.git) (06/10/2025)
- Hot fix crash Thread SDK 

## [1.8.45](https://github.com/VIHATTeam/OmiKit.git) (10/09/2025)
- Fix lỗi crash khi nhận incomming call
- Fix lỗi không wake up app khi có incomming call ở thiết bị yếu

## [1.8.44](https://github.com/VIHATTeam/OmiKit.git) (22/07/2025)
- Add API update action when accept, hangup, transfer call and func check show missed call 

## [1.8.43](https://github.com/VIHATTeam/OmiKit.git) (16/07/2025)
- Add API update action when accept, hangup, transfer call 

## [1.8.42](https://github.com/VIHATTeam/OmiKit.git) (02/07/2025)
- Hot fix missed omiId ở state early khi out going call 

## [1.8.41](https://github.com/VIHATTeam/OmiKit.git) (27/06/2025)
- Add mã check chặn show thông báo cuộc gọi nhỡ

## [1.8.38, 1.8.40](https://github.com/VIHATTeam/OmiKit.git) (23/06/2025)
- Fix crash khi mở từ background lên foreground  

## [1.8.37](https://github.com/VIHATTeam/OmiKit.git) (11/06/2025)
- Thêm func declineWithBusy 

## [1.8.36](https://github.com/VIHATTeam/OmiKit.git) (11/06/2025)
- Fix lỗi không kill cuộc gọi ở background 

## [1.8.35](https://github.com/VIHATTeam/OmiKit.git) (10/06/2025)
- Add cấu hình từ chối cuộc gọi 486-603. Mặc định 603
- Add func DropCall vào OMIClient 

## [1.8.34](https://github.com/VIHATTeam/OmiKit.git) (06/06/2025)
- Add infor into user-agent for flow incoming call. 
- Add func DropCall 

## [1.8.33](https://github.com/VIHATTeam/OmiKit.git) (02/06/2025)
- Fix kịch bản tiêu chí

## [1.8.27, 1.8.28, 1.8.31, 1.8.32](https://github.com/VIHATTeam/OmiKit.git) (02/06/2025)
- Add func check show cuộc gọi nhỡ 
  

## [1.8.17](https://github.com/VIHATTeam/OmiKit.git) (12/05/2025)
- Cập nhật func tính MOS cho cả OPUS
- Thêm func reset giá trị OPUS mỗi khi end call 


## [1.8.16](https://github.com/VIHATTeam/OmiKit.git) (25/03/2025)



#### Changed
- Re-build for 1.8.15

## [1.8.15](https://github.com/VIHATTeam/OmiKit.git) (25/03/2025)

#### Changed
- Clean code and fix missed Call Name from partner 

## [1.8.14](https://github.com/VIHATTeam/OmiKit.git) (21/03/2025)

#### Changed
- Update name caller when missed call from flow call ZCC
  

## [1.8.12](https://github.com/VIHATTeam/OmiKit.git) (19/03/2025)

#### Changed
- Try with update name caller when missed call from flow call ZCC
  
### ------------------------------

## [1.8.11](https://github.com/VIHATTeam/OmiKit.git) (18/03/2025)

#### Changed
- Change STUN address
  
### ------------------------------


## [1.8.10](https://github.com/VIHATTeam/OmiKit.git) (13/03/2025)

#### Changed
- Add log tracking start call failed 
  
### ------------------------------

## [1.8.9](https://github.com/VIHATTeam/OmiKit.git) (27/02/2025)

#### Changed
- Fix change speaker in callkit 
  
### ------------------------------


## [1.8.8](https://github.com/VIHATTeam/OmiKit.git) (26/02/2025)

#### Changed
- Add func toggle speaker 
  
### ------------------------------


## [1.8.6](https://github.com/VIHATTeam/OmiKit.git) (26/02/2025)

#### Changed
- Fix audio port ios 
  
### ------------------------------


## [1.8.5](https://github.com/VIHATTeam/OmiKit.git) (17/02/2025)

#### Changed
- Fix audio session when end call 
  
### ------------------------------

## [1.8.4](https://github.com/VIHATTeam/OmiKit.git) (06/02/2025)

#### Changed
- Fix codec opus for out going 
  
### ------------------------------

## [1.8.3](https://github.com/VIHATTeam/OmiKit.git) (05/02/2025)

#### Changed
- Fix codec opus for out going 
  
### ------------------------------

## [1.8.2](https://github.com/VIHATTeam/OmiKit.git) (25/12/2024)

#### Changed
- Fix crash SDK
  
### ------------------------------

## [1.8.1](https://github.com/VIHATTeam/OmiKit.git) (07/10/2024)

#### Changed
- Optimize flow incoming call and fix prefix phone number
  
### ------------------------------

## [1.7.41](https://github.com/VIHATTeam/OmiKit.git) (07/10/2024)

#### Changed
- Fix space in phone number
  
### ------------------------------

## [1.7.40](https://github.com/VIHATTeam/OmiKit.git) (07/10/2024)

#### Changed
- Update hide prefix phone number with CallKit
  
### ------------------------------

#### Changed
- Add SipNameNumber, projectId 

## [1.7.39](https://github.com/VIHATTeam/OmiKit.git) (04/10/2024)

- Optimize code Codes, media 

## [1.7.38](https://github.com/VIHATTeam/OmiKit.git) (01/10/2024)


- Add Sip_number for object OMICALL

## [1.7.37](https://github.com/VIHATTeam/OmiKit.git) (24/09/2024)

- Fix crash removeObjectKey 

## [1.7.35](https://github.com/VIHATTeam/OmiKit.git) (16/09/2024)


- Fix Show Phone CallKit 

## [1.7.34](https://github.com/VIHATTeam/OmiKit.git) (23/08/2024)


#### Changed

- Fix message code error when turn off number internal 

## [1.7.33](https://github.com/VIHATTeam/OmiKit.git) (22/08/2024)

#### Changed

- Add message for destination ads

## [1.7.32](https://github.com/VIHATTeam/OmiKit.git) (15/08/2024)

#### Changed

- Fix secret show phone number in UI Callkit

## [1.7.31](https://github.com/VIHATTeam/OmiKit.git) (14/08/2024)

#### Changed

- Fix same call Id Omi 

## [1.7.30](https://github.com/VIHATTeam/OmiKit.git) (07/08/2024)


#### Changed

- Update code SwitchBoard

## [1.7.29](https://github.com/VIHATTeam/OmiKit.git) (31/07/2024)



- Update code SwitchBoard

## [1.7.28](https://github.com/VIHATTeam/OmiKit.git) (30/07/2024)

#### Changed

- Update code SwitchBoard

## [1.7.27](https://github.com/VIHATTeam/OmiKit.git) (29/07/2024)


#### Changed

- Add log tracking log in/out

## [1.7.26](https://github.com/VIHATTeam/OmiKit.git) (23/07/2024)

#### Changed

- Rollback code and fix missed OMI_ID

## [1.7.25](https://github.com/VIHATTeam/OmiKit.git) (20/06/2024)


#### Changed

- Fix missing omi_id off incoming call 

## [1.7.24](https://github.com/VIHATTeam/OmiKit.git) (19/06/2024)

#### Changed
- Add function clear call when close Callkit false 

## [1.7.23](https://github.com/VIHATTeam/OmiKit.git) (13/06/2024)


#### Changed
- Fix wrong call_id when get push incoming call second
- Reduce time start call  

## [1.7.22](https://github.com/VIHATTeam/OmiKit.git) (13/06/2024)


#### Changed

- Revert code add mission file Omikit.h

## [1.7.21](https://github.com/VIHATTeam/OmiKit.git) (06/06/2024)


#### Changed

- Update new core SDK 

## [1.7.20](https://github.com/VIHATTeam/OmiKit.git) (30/05/2024)


#### Changed


- Fix crash in coming call when transfer call

## [1.7.18](https://github.com/VIHATTeam/OmiKit.git) (21/05/2024)
 

#### Changed

- Fix call id off func answerIncommingCall for SDK React Native 

## [1.7.17](https://github.com/VIHATTeam/OmiKit.git) (15/05/2024)


#### Changed

- Fix hang when canceling calls, 
- Fix error of not being able to call continuously, add UDP connection

## [1.5.90](https://github.com/VIHATTeam/OmiKit.git) (17/10/2023)



## [1.0.0](https://github.com/VIHATTeam/OmiKit.git) (15/06/2020)

Released on Monday, June 15, 2020.

#### Changed

- Create Library
- Provide all function of Omicall for Voip: call inbound/outbound, setup Endpoint, Login system

## [1.0.4](https://github.com/VIHATTeam/OmiKit.git) (15/09/2020)

Released on Monday, June 15, 2020.

#### Changed

- Update Video function
- Fix bug

## [1.0.6](https://github.com/VIHATTeam/OmiKit.git) (12/12/2020)

Released on Monday, June 15, 2020.

#### Changed

- Ddd callback for call directly
- Fix bug

## [1.0.7](https://github.com/VIHATTeam/OmiKit.git) (12/12/2020)

Released on Monday, June 15, 2020.

#### Changed

- Fix bug multi call incomming

## [1.0.8](https://github.com/VIHATTeam/OmiKit.git) (03/05/2022)

Released on Monday, June 15, 2020.

#### Changed

- Fix bug video call

#### Changed

- Fix bug multi call incomming

## [1.0.15](https://github.com/VIHATTeam/OmiKit.git) (08/08/2022)

Released on Monday, June 15, 2020.

#### Changed

- Fix bug get CurrentCall
- Add Get newest call

## [1.0.16](https://github.com/VIHATTeam/OmiKit.git) (12/12/2022)

Released on Monday, June 15, 2020.

#### Changed

- Fix bug get Newest call
- Fix event Toggle Muted

## [1.0.20](https://github.com/VIHATTeam/OmiKit.git) (12/12/2022)

Released on Monday, June 15, 2020.

#### Changed

- Update version IOS

## [1.5.2](https://github.com/VIHATTeam/OmiKit.git) (21/03/2023)

## [1.5.18](https://github.com/VIHATTeam/OmiKit.git) (12/12/2022)

Released on Monday, June 15, 2020.

#### Changed

- Fix bug 2 call receive cause crash
- Optimize quality Video call depend on network
- Add more function util process audio
- Add callback when mute/hold call

Released on Monday, June 15, 2020.

#### Changed

- Fix bug video call
- Fixing bud multicall cause get wrong active2

## [1.5.26](https://github.com/VIHATTeam/OmiKit.git) (12/12/2022)

Released on Friday, April 21, 2023.

#### Changed

- Fix bug
- Optimize quality Video call depend on network

## [1.5.27](https://github.com/VIHATTeam/OmiKit.git) (25/04/2023)

Released on April 25, 2023.

#### Changed

- Return transaction id

## [1.5.28](https://github.com/VIHATTeam/OmiKit.git) (29/04/2023)

Released on April 29, 2023.

#### Changed

- Return more informations for `getUser` function

## [1.5.29](https://github.com/VIHATTeam/OmiKit.git) (30/04/2023)

Released on April 30, 2023.

#### Changed

- Optimize call function

## [1.5.30](https://github.com/VIHATTeam/OmiKit.git) (04/05/2023)

Released on May 04, 2023.

#### Changed

- Support custom notifiaction icon

## [1.5.31](https://github.com/VIHATTeam/OmiKit.git) (11/05/2023)

Released on May 11, 2023.

#### Changed

- Return employee sip number in script call.

## [1.5.32](https://github.com/VIHATTeam/OmiKit.git) (16/05/2023)

Released on Friday, May 16, 2023.

#### Changed

- Fix login for api key case
- Support to custom incoming notification title

## [1.5.35](https://github.com/VIHATTeam/OmiKit.git) (16/05/2023)

Released on May 16, 2023.

#### Changed

- Optimate `logout` function. We removed all sip service when user called `logout` function.

## [1.5.43](https://github.com/VIHATTeam/OmiKit.git) (31/05/2023)

Released on May 31, 2023.

#### Changed

- Optimate `startCall` function. We return `OMIStartCallStatus` error enum.

## [1.5.46](https://github.com/VIHATTeam/OmiKit.git) (05/06/2023)

Released on June 05, 2023.

#### Changed

- Optimate `startCall` function. We check it on background thread.

## [1.5.47](https://github.com/VIHATTeam/OmiKit.git) (08/06/2023)

Released on June 08, 2023.

#### Changed

- Support to check same with owner sip number. We don't allow to your self.

## [1.5.48](https://github.com/VIHATTeam/OmiKit.git) (08/06/2023)

Released on June 08, 2023.

#### Changed

- Optimate `startCall` function. We don't allow to start call if user have a another call.

## [1.5.52](https://github.com/VIHATTeam/OmiKit.git) (12/06/2023)

Released on June 12, 2023.

#### Changed

- Optimate core and improve performance for call holding.

## [1.5.53](https://github.com/VIHATTeam/OmiKit.git) (13/06/2023)

Released on June 13, 2023.

#### Changed

- Support to get current sip.

## [1.5.54](https://github.com/VIHATTeam/OmiKit.git) (16/06/2023)

Released on June 16, 2023.

#### Changed

- Improve audio function. User can listen audio change in UI.

## [1.5.55](https://github.com/VIHATTeam/OmiKit.git) (21/06/2023)

Released on June 21, 2023.

#### Changed

- Fix `startCall` with video params. When user start call, incoming user receive audio notification.
