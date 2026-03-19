# Changelog

All notable changes to this project will be documented in this file.

## [1.11.3](https://github.com/VIHATTeam/OmiKit.git) (19/03/2026)

### Crash Fixes (Crashlytics top crashes — ~503 crashes eliminated)

- **NSRangeException crash** (`OMIEndpoint.h`, Crash #2/#7/#8 — 255 crashes) — `OMIEndpointStateString` macro had 3 elements but enum had 4 (`OMIEndpointClosing`). `objectAtIndex:3` on 3-element array → crash. Fixed: added `"OMIEndpointClosing"` + safe bounds check returns `"Unknown"` for any future out-of-range values.

- **EXC_BAD_ACCESS pjmedia_codec_mgr_enum_codecs** (`OMIEndpoint.m`, `OMICallStats.m`, Crash #3 — 72 crashes) — `pjsua_enum_codecs()` called with NULL codec_mgr during VoIP push cold start. 4 call sites missing NULL guard (1 already had it). Fixed: added `pjsua_get_pjmedia_endpt()` + `pjmedia_endpt_get_codec_mgr()` NULL check before every `pjsua_enum_codecs` call.

- **PushKit VoIP kill by iOS** (`VoIPPushHandler.m`, Crash #4 — 85 crashes) — Duplicate VoIP push detection (FIX PUSH-1) called `completion()` without `reportNewIncomingCall` → iOS killed app. Fixed: duplicate push path now calls `reportAndEndDummyCallWithCompletion` to satisfy PushKit requirement.

- **pjsip_timer_init_session crash** (`OMICallManager.m`, Crash #5 — 91 crashes) — `startCallToNumberNoReg` created PJSIP session while endpoint transitioning to Closing state → session pool corrupt → crash. Fixed: added `pjsua_get_state() != PJSUA_STATE_RUNNING` guard before call creation.

### Call Handling

- **OMIHaveAnotherCall false positive** (`OmiClient.m`) — `getNewestCall != nil` rejected new calls even when existing call was already `disconnected`/`disconnecting` (PJSIP cleanup delay). Most common customer complaint. Fixed: added `callState` check — only reject if existing call is truly active (not disconnected/disconnecting).

- **OMIHaveAnotherCall diagnostic logging** (`OmiClient.m`) — All 3 HaveAnotherCall exit paths now log full context (SIP user, endpoint state, all active calls with uuid/state/phone/createDate) and auto-upload log file. Search `[HaveAnotherCall]` on server to diagnose.

### Audio

- **AUDIO-STORM speaker toggle fix** (`OMIEndpoint.m`) — Toggle speaker caused ~30 audio underflows in 0.3s → AUDIO-STORM detector killed the call. Fixed: increased threshold from 30→60 and decreased window from 2s→0.5s. Speaker switch (~30 underflows) stays below threshold, real network death (100+ underflows) still detected.

### Sample App

- **CallingView timer not starting** (`ViewController.m`) — Outgoing call: CallingView presented at CALLING state, then CONFIRMED created a NEW CallingView → timer reset to 0. Fixed: CONFIRMED reuses existing CallingView, only updates `callUUID`. Incoming call: CallingView presented AT CONFIRMED → missed CONFIRMED notification. Fixed: `startCallTimer` called in present completion block.

---

## [1.11.2](https://github.com/VIHATTeam/OmiKit.git) (18/03/2026)

### Video Call Stability (PJSIP Metal Renderer)

- **CADisplayLink renderer replaces performSelectorOnMainThread** (`metal_dev.m`) — Metal rendering no longer competes with SwiftUI/RN/Flutter for main thread time. Frames render at display vsync via dedicated CADisplayLink, bypassing main thread entirely. Video stable 5+ minutes on SwiftUI client (was 5-8 seconds before).

- **CADisplayLink auto pause/resume on background/foreground** (`metal_dev.m`) — Prevents iOS GPU penalty box when app enters background. CADisplayLink pauses automatically via `UIApplicationDidEnterBackgroundNotification`, resumes on `UIApplicationWillEnterForegroundNotification`.

- **A/V sync threshold relaxed for VoIP** (`vid_stream.c`) — Changed sync threshold from 0ms to -100ms and MAX_SKIP_MS from 0 to 33ms (1 frame). VoIP doesn't need perfect lip-sync; showing every frame with slight delay is better than dropping frames for sync accuracy. Reduces video stutter.

### Video Recovery

- **PJ_EIGNORED codec filter** (`OMIEndpoint.m`, Fix JJ-11) — PJ_EIGNORED counter now distinguishes `vid_conf.c` Metal errors (need recovery) from `vid_toolbox.m` codec errors (harmless). Previously codec unpacketize errors false-triggered Metal recovery → re-INVITE → destroyed stable video.

- **QQ-3 grace period increased to 2000ms** (`OMIVideoPreviewView.m`) — After FORMAT_CHANGE, Metal needs up to 1.5s to stabilize. Previous 500ms grace was too short → PJ_EIGNORED during stabilization triggered recovery → GPU Timeout.

- **Foreground recovery: PLI + show Metal** (`OMIVideoPreviewView.m`, Fix BG-8) — After background→foreground, SDK sends 2 PLIs (0ms + 500ms) and ensures Metal window visible. No hide, no loading, no re-INVITE. VT decoder gets fresh IDR frame and resumes in ~1s. Watchdog handles dead decoder case (5s fallback).

- **Background Metal guard** (`OMIVideoPreviewView.m`, Fix BG-6) — `safeShowVideoWindow` and FIX AAA timer now check `UIApplicationState` before enabling Metal. Prevents catastrophic GPU penalty when FMCH timer fires during background transition.

- **Timestamp reset on foreground** (`OMIVideoPreviewView.m`, Fix BG-1) — Reset `lastSuccessfulRenderTimestamp` and `lastFrameTimestamp` in `appWillEnterForeground`. Prevents watchdog FIX-OO false positive (stale timestamp → loading shown over working video).

- **Timestamp init on executeShowVideoWindow** (`OMIVideoPreviewView.m`, Fix BG-7) — Initialize frame tracking timestamps when Metal window first shown. After cleanup+setup recovery, new view had timestamp=0 → watchdog false positive after 14s.

### Call Handling

- **Duplicate VoIP push guard** (`VoIPPushHandler.m`, Fix PUSH-1) — iOS can deliver same VoIP push 2+ times within milliseconds. Second push destroyed endpoint from first push → call died on accept. Now detects duplicate `callId` via `CallIDsManager` and skips.

### Performance

- **Production readiness optimizations** (`OMIVideoPreviewView.m`, `OMIVideoCallManager.m`) — Static variable converted to instance property for per-view debounce (C1), `dispatch_sync` replaced with `dispatch_async` for `presentsWithTransaction` (C2), strong self replaced with weak in cleanup timer (C3), 64 high-frequency log statements downgraded from INFO to DEBUG (H1).

- **Double-dispatch fix in handleMetalStreamRestarted** (`OMIVideoPreviewView.m`, Fix DD-1) — `forceHideLoadingIndicator` called directly instead of nested in `dispatch_async(main_queue)`. Reduces loading hide from 2 runloop cycles to 1.

- **Safety prepareForVideoDisplay fallback** (`OMIVideoCallManager.m`, Fix DD-2) — 1.5s delayed `prepareForVideoDisplay` call from `setupWithRemoteView` as safety net when `viewDidAppear` doesn't fire promptly (navigation push stalls during background→foreground).

---

## [1.11.0](https://github.com/VIHATTeam/OmiKit.git) (15/03/2026)

### Fixed

- **App freeze (deadlock) after FORMAT_CHANGE during video call** — ABBA deadlock between PJSIP decode thread (holding stream mutex, waiting for PJSUA_LOCK) and PLI retry thread (holding PJSUA_LOCK, waiting for stream mutex). `onCallMediaEvent` FMCH callback called `pjsua_call_get_info()` directly on decode thread → deadlock → app completely unresponsive.

  **Fix II** (`OMIEndpoint.m`): Capture event data (`size`, `call_id`, `med_idx`) by value before async dispatch, then wrap all FMCH processing in `[OMIThread run:^{...}]` to execute on GCD queue with PJSIP thread registration instead of on the decode thread holding stream mutex.

- **EXC_BAD_ACCESS crash after ~30s in video call** — `attemptViewSwapRecovery` called from `handlePJIgnoredBurstDetected` on GCD background thread created UIView and accessed `self.remoteContainerView.bounds` off main thread → crash at `objc_msgSend`.

  **Fix JJ-1** (`OMIVideoCallManager.m`): Wrapped UIView creation in `dispatch_sync(dispatch_get_main_queue(), ^{...})` with `[NSThread isMainThread]` guard.

- **Outgoing video call: local camera shows briefly then goes blank until CONFIRMED** — `startLocalVideoImmediately` starts camera at call initiation (`isLocalVideoInitComplete=YES`). `prepareForVideoDisplay` fires during EARLY state → after 100ms delay calls `createInternalVideoViews` → destroys localVideoView with running camera → blank screen until CONFIRMED state recreates views.

  **Fix KK** (`OMIVideoCallManager.m`): In `prepareForVideoDisplay`, skip `createInternalVideoViews` if `isLocalVideoInitComplete == YES` — both remote and local views already exist with camera running.

---

## [1.10.38](https://github.com/VIHATTeam/OmiKit.git) (15/03/2026)

### Fixed

- **Incoming video call: screen freezes permanently after answer** — Race condition in `handlePJIgnoredBurstDetected` re-setting `hasMetalDrawableError=YES` during the Metal stream restart stabilization window after FMCH, permanently blocking `hideLoadingIndicator`.

  **Root cause chain** (Fix QQ-3, `OMIVideoPreviewView.m`):
  1. VT decode cascade (15 errors / 0.5s) fires → `handleH264DecodeErrorBurst` (FIX PP) sets `hasMetalDrawableError=YES` + schedules 5000ms Metal recovery
  2. FMCH (format change 1920x1080→640x480) fires ~1.6s later → `handleMetalStreamRestarted` clears `hasMetalDrawableError=NO` + increments `keyframeRetryGeneration` (cancels 5000ms block) + schedules `dispatch_async(main_queue, ^{ hideLoadingIndicator })`
  3. Metal stream physically restarts immediately ("Starting Metal video stream gen=1")
  4. Within the ~100-200ms stabilization window before drawable pool is fully initialized, PJSIP delivers frames → PJ_EIGNORED burst fires
  5. `handlePJIgnoredBurstDetected` sets `hasMetalDrawableError=YES` AGAIN
  6. `dispatch_async(main_queue, ^{ hideLoadingIndicator })` from step 2 arrives, sees `hasMetalDrawableError=YES` → BLOCKED → loading spinner stuck FOREVER → user sees frozen screen

  **Fix**: Added 500ms grace period in `handlePJIgnoredBurstDetected` using existing `lastMetalStreamRestartTimestamp` property (already set in `handleMetalStreamRestarted`). PJ_EIGNORED during this window is expected (same pattern as existing camera switch guard FIX W1). After 500ms, drawable pool is fully initialized and genuine burst detection resumes normally.

---

## [1.10.37](https://github.com/VIHATTeam/OmiKit.git) (12/03/2026)

### Fixed

- **Outgoing video CONFIRMED state: app frozen 4.6s, video never shows** — Two-stage deadlock in `executeShowVideoWindow:` (`OMIVideoPreviewView.m`):

  **Stage 1 (Fix D)**: `[OMIThread runSync:]` → `dispatch_sync(GLOBAL_DEFAULT)` on main thread + `createViewForVideoLocalAsync` on `GLOBAL_HIGH` holding PJSUA_LOCK during camera init → 3-party deadlock. `hasShownWindow` never set → video never shown. Fixed by replacing `dispatch_sync` with `dispatch_async(GLOBAL_HIGH)`.

  **Stage 2 (Fix E)**: After Fix D, `pjsua_call_get_stream_stat` was still called on the main thread (lines 1281-1290) for packet baseline initialization. This call acquires PJSUA_LOCK → blocked main thread for 4.6s while `createViewForVideoLocalAsync` (camera restart at CONFIRMED) held the lock. Main thread frozen → `dispatch_async(GLOBAL_HIGH)` for `pjsua_vid_win_set_show` never queued → `dispatch_after` keyframe requests never fired → video never shown for the duration of the log. Fixed by moving `pjsua_call_get_stream_stat` inside the `dispatch_async(GLOBAL_HIGH)` block so the main thread is NEVER blocked on PJSUA_LOCK.

---

## [1.10.36](https://github.com/VIHATTeam/OmiKit.git) (12/03/2026)

### Fixed

- **Outgoing video call takes 10s+ to connect, freezes at 20s** — Three compounding bugs caused the delay and freeze:

  1. **Fix A — Premature video start at EARLY (183) state** (`OMIVideoCallManager.m`): `onCallMediaState` fired `OMIVideoRemoteReady` during 183 ringing (remote doesn't send video until `CONFIRMED`). SDK attempted to show Metal window → no frames for ~5s → 5s watchdog timer fired → re-INVITE skipped (EARLY state) → wasted 5s. Fixed by detecting outgoing+EARLY state in `handleVideoNotification:` and deferring video start to `CONFIRMED`. `pendingWindowId` stores the wid; `handleCallStateChanged` triggers `startVideoPreviewWithRetry` when CONFIRMED fires.

  2. **Fix B — New Metal views stuck with wid=-1 after CONFIRMED** (`OMIVideoCallManager.m`, `OMICall.m`): At `CONFIRMED`, `SampleVideoCallViewController` pushed → `createInternalVideoViews` destroyed old Metal views and created fresh ones. `mediaStateChanged` fired again with same wid=1 → `videoReadyNotificationPosted` flag blocked the notification → new Metal views never received their wid → black screen forever. Fixed by calling `resetVideoReadyNotificationState` on the active `OMICall` inside `createInternalVideoViews`, allowing the next `mediaStateChanged` to re-post `OMIVideoRemoteReady` to the fresh views.

  3. **Fix C — IFRM cascade fires force re-INVITE on working video** (`OMIEndpoint.m`): After ~15s of IFRM (keyframe-missing) events (normal during PLI/keyframe request cycles), `forceReinviteForGPURecovery` was called unconditionally, destroying ALL media (audio+video) and causing 5-10s freeze + audio underflow storms. Fixed by checking `checkIsVideoReceivingFrames` before escalating: if video frames are flowing normally → reset IFRM cascade tracking (no re-INVITE); if video is genuinely not flowing → escalate as before.

- **Declining call B (CallingView) causes broken state when call A is active** — CallingView was presented at `OMICallStateIncoming` (before CallKit answer). When user declined via CallingView while call A active, old CallingView not dismissed cleanly. Fixed by moving CallingView presentation to `OMICallStateConfirmed` only (after actual answer). Added dismiss-existing-CallingView guard before presenting new one (Example/ViewController.m)

### Added

- **`OMICallWaitingForEndpoint` status** — New `OMIStartCallStatus` enum value sent as intermediate callback when `startCall` is waiting for endpoint teardown. Completion block fires twice: first `OMICallWaitingForEndpoint` (client shows loading), then final status (success/fail). Sent from `startCall2` and `handleExistingEndpoint` when detecting `OMIEndpointClosing` state (OMICall.h, OmiClient.m)

---


## [1.10.35](https://github.com/VIHATTeam/OmiKit.git) (10/03/2026)

### Fixed

- **Rapid repeated `startCall` creates duplicate calls** — Added static `_isStartingCall` guard at `startCall:` entry to prevent concurrent call setups. When client calls `startCall` multiple times rapidly, only the first invocation proceeds; subsequent calls receive `OMIHaveAnotherCall` immediately. Guard is reset via `wrappedCompletion` in `makeCall` (covers all exit paths: success, 403, fail, register fail). Additional resets in `handleCallSetupForNumber` (disconnect fail), `startCall2` (max retry). 30-second safety timeout auto-resets the flag if stuck due to missed edge case (OmiClient.m)

- **Call immediately after hangup causes 3-5s silent freeze** — When endpoint is mid-destroy (`OMIEndpointClosing`) after previous call ended, `startOmiService` kicked off async config that raced with the ongoing destroy. Now `startCall2` detects `OMIEndpointClosing` and skips `startOmiService`, going directly to `handleEndpointNotAvailable` which properly waits for destroy completion before retrying (OmiClient.m)

- **Declining incoming call B kills audio of active call A** — `performEndCallAction` called `deactivateSoundDevice` unconditionally for every end call action. `pjsua_set_no_snd_dev()` is GLOBAL — it closes the single shared audio device for all PJSIP calls. When user declines call B while call A is active, this killed call A's audio immediately. Fixed by checking if other active calls exist before deactivating; skips `deactivateSoundDevice` when other calls are still running (CallKitProviderDelegate.m). Secondary fix: `setCallState` Disconnected handler now uses account-agnostic `getAllCalls` check alongside `activeCallsForAccount` to prevent false-empty from account mismatch triggering redundant audio deactivation (OMICall.m)

- **End call A + accept call B → audio lost on call B** — CallKit transition fires `AVAudioSessionInterruptionTypeBegan` temporarily. `audioInterruption:` unconditionally called `deactivateSoundDevice` → posted `OMIAudioControllerAudioInterrupted` → `OMICall.audioInterruption:` called `toggleHold` → re-INVITE with sendonly SDP → call B permanently on HOLD. Fixed by adding active-calls guard: when `InterruptionTypeBegan` fires and active calls exist, skip `deactivateSoundDevice` and do NOT post the interrupted notification (OMIAudioController.m)

- **Decline call B kills active call A — spam check targets wrong call** — `startCheckSpamCalls` was a GLOBAL check without per-call targeting. VoIP Push for Call B starts spam timer → user declines Call B → Call B removed → 2s timer fires → finds 1 remaining call (Call A) + empty `stateSignalSwitchBoard` → ends Call A. Fixed by adding `forCallUUID:` parameter binding spam check to the specific VoIP push call UUID. If target call no longer exists when timer fires, spam check exits early (OMICallManager.m, OMICallManager.h, VoIPPushHandler.m)

### Added

- **`OMICallWaitingForEndpoint` status** — New `OMIStartCallStatus` enum value sent as intermediate callback when `startCall` is waiting for endpoint teardown. Completion block fires twice: first `OMICallWaitingForEndpoint` (client shows loading), then final status (success/fail). Sent from `startCall2` and `handleExistingEndpoint` when detecting `OMIEndpointClosing` state (OMICall.h, OmiClient.m)

---


## [1.10.34](https://github.com/VIHATTeam/OmiKit.git) (05/03/2026)


### Fixed

- **Outgoing call disconnects immediately when remote answers** — Audio underflow storm detector (Fix N) was false-triggering on ringback teardown at `CONFIRMED` state. When the remote party answers, PJSIP disconnects the ringback tone port (`Conf disconnect: 1 -x- 0`) causing a brief `playdbuf/capdbuf` underflow burst (~30 underflows in 0.4s) — a normal, self-resolving audio glitch. This burst incorrectly matched the TCP RST storm threshold (30 underflows in 2s), causing `CXEndCallAction` to fire at `call_secs=0` and disconnect the call. Fixed by adding a 3-second suppression window after call enters `CONFIRMED`: underflow bursts within 3s of `CONFIRMED` are discarded and the counter reset. Real TCP RST storms (which occur after the call has been running for several seconds) are unaffected. Uses a file-scope `_lastCallConfirmedTimestamp` static (ARM64 atomic double) set in `onCallState` — safe to read from the audio thread without ObjC object access (OMIEndpoint.m)



## [1.10.33](https://github.com/VIHATTeam/OmiKit.git) (04/03/2026)

### Added

- **DNS pre-warm for TURN/STUN servers** — Added `+prewarmDNSForHosts:` class method on `OMIEndpoint` that runs `getaddrinfo` on a HIGH priority background thread to warm the OS DNS cache before PJSIP needs to resolve TURN/STUN hostnames. Called automatically in `createAccountWithSipUser:` with the actual dynamic STUN/TURN servers from the account configuration (vary per country/network). Eliminates TURN DNS cold-start delay of 5+ seconds that caused `PJ_ETIMEDOUT` on first outgoing call after a cold app launch (OMIEndpoint.m, OMIEndpoint.h, OMISIPLib.m)


## [1.10.32](https://github.com/VIHATTeam/OmiKit.git) (04/03/2026)

### Added

- **`logoutWithCompletion:` method** — Added async logout with completion callback so app can call login immediately after logout without arbitrary delay. HTTP deregister request runs on background queue; completion is always called on main thread with `success=YES/NO`. Original `logout` method preserved for backward compatibility (OmiClient.m, OmiClient.h)

### Changed

- `logout` now internally delegates to `logoutWithCompletion:nil` — identical behavior, no breaking change


## [1.10.31](https://github.com/VIHATTeam/OmiKit.git) (03/03/2026)

### Added
- **OmiClient: `isNetworkAvailable`** - New static method to check if network is available (WiFi or Cellular) before starting a call
- **OMICall: `OMINoNetwork` status** - New `OMIStartCallStatus` enum value returned when attempting to start a call with no network connectivity

### Improved
- **OMIStartCallStatus enum formatting** - Code style cleanup in enum declaration

## [1.10.29](https://github.com/VIHATTeam/OmiKit.git) (03/03/2026)

### Added
- **VoIPPushHandler: `reportAndEndDummyCallWithCompletion:`** - New static method to report and end dummy CallKit call with completion handler, improving PushKit compliance when no valid incoming call is available

### Fixed
- **XCFramework: Info.plist library identifiers** - Fixed incorrect `LibraryIdentifier` mapping in XCFramework Info.plist. Correctly associates `ios-arm64-simulator` with simulator variant and `ios-arm64` with device

## [1.10.28](https://github.com/VIHATTeam/OmiKit.git) (27/02/2026)

### Added
- **OMIEndpoint: `ensureVideoCodecsConfigured`** - Lazy initialization of video codecs on first video call. Calls `adjustVideoStreamConfig` only once, safe to call multiple times (no-op after first configuration)

### Fixed
- **Video: Codec initialization timing** - Prevent codec configuration race condition by deferring `adjustVideoStreamConfig` until first video call instead of during SDK startup

## [1.10.27](https://github.com/VIHATTeam/OmiKit.git) (25/02/2026)

### Fixed
- **Video: CAMetalLayerDrawable corruption recovery** - Added `forceRestartVideoStreamForDrawableRecovery` method to OMIEndpoint for fast Metal video stream restart (~165ms) when `addPresentedHandler` errors occur. Resets codec cache to force fresh drawable pool without full re-INVITE (~2-5s)
- **Video: VideoToolbox -12909 decode error cascade detection** - Added `isVTDecodeCascadeActive` method to OMIEndpoint to prevent false "resolved" detection when RTCP packets arrive but decoded frames are zero
- **Video: Metal recovery coordination** - Added `isRecoveryInProgress` flag and `lastRecoveryCompletedTime` cooldown (2s) in OMIVideoCallManager to prevent overlapping recovery operations

### Added
- **OMIVideoPreviewView: `hasShownWindow` property** - Read-only property to check if PJSIP video window has been successfully shown (`pjsua_vid_win_set_show` called). Used to verify video is rendering before triggering recovery
- **Example: Complete SIP end cause messages** - Added 27 status codes in `getEndCauseMessage` including standard SIP codes (200, 408, 480, 486, 487, 500, 503, 600-603) and OmiCall custom codes (850-865: call limits, DNC list, prefix routing, trial package limits, advertising time restrictions)
- **Example: AppDelegate-based OMICallDealloc observer** - Moved observer from CallManagerV2 to AppDelegate with `handleCallEnded` forwarding for reliable notification delivery

## [1.10.25](https://github.com/VIHATTeam/OmiKit.git) (11/02/2026)

### Fixed
- **Podspec: EXCLUDED_ARCHS for simulator** - Changed from `arm64` to `x86_64` to fix `pod lib lint` validation failure on Apple Silicon (arm64 simulator slice)
- **Example: OMICallDeallocNotification observer not receiving events** - Moved observer registration from CallManagerV2 to AppDelegate using selector-based pattern (matching Objective-C example) for reliable notification delivery
- **Example: Swift 6 Sendable warnings in notification observers** - Extract all data from `notification.userInfo` before entering `MainActor.assumeIsolated` context to prevent data race warnings
- **Example: Logout not clearing saved credentials** - Added `UserDefaults.synchronize()` to force immediate save when clearing login credentials
- **Example: Duplicate PushKitManager conflict** - Removed local PushKitManager.swift that conflicted with OmiKit SDK's built-in `PushKitManager.sharedInstance()`

### Added
- **Example: UUID + Phone login support** - Added `loginWithUUID(usrUuid:fullName:apiKey:phone:)` in CallManagerV2 with toggle UI in LoginView for switching between SIP and UUID login modes
- **Example: Comprehensive README** - Added call flow diagrams (ASCII art), CallManager vs CallManagerV2 comparison, Swift 6 setup guide, and API reference
- **Main README: Link to Example README** - Added section pointing to SwiftUI Example Project documentation

### Changed
- **Example: Notification observer pattern** - OMICallDealloc uses selector-based observer in AppDelegate; CallKit and CallState observers use closure-based pattern with `queue: .main` in CallManagerV2

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
