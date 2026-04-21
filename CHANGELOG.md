# CHANGELOG of OmiKit

## [1.11.12] - 2026-04-20


### Bug Fix — Multi-call: Active call dropped when second incoming call is cancelled by caller

- **[BUG] Active call (call 1) forced disconnect when incoming call (call 2) is CANCEL'd by caller** (`OMIEndpoint.m`) — `logCallBack` CANCEL/BYE detector runs on the PJSIP transport thread as a deadlock-safe fallback for `onTxStateChange`. It iterates all calls and disconnects **the first non-disconnected call found** — with no knowledge of which call the CANCEL belongs to. With 2 active calls, call 1 (CONFIRMED) is encountered first and incorrectly forced to DISCONNECTED. `onTxStateChange` (which has the correct `call_id`) also handles the CANCEL moments later, but the damage is already done. User-initiated decline via CallKit is unaffected because it routes through `performEndCallAction` with the exact UUID. Fixed: added multi-call guard — if `getAllCalls.count > 1`, skip the logCallBack fallback and let `onTxStateChange` handle it with the correct call_id.


### Crash Fixes (v3.4.6 Production Crashes)

- **[CRASH] `pjsip_timer_init_session.cold.2` — 55 crashes, 27 users** (`sip_timer.c`) — ICE completion callback fires on OMISIP worker thread `pjsua_0` after hangup triggers `pjsip_timer_deinit_module()` → `is_initialized=FALSE`. `pjsip_timer_init_session` asserts `is_initialized` → `abort()` → SIGABRT. Fix already existed in source (`PJ_ASSERT_RETURN` → graceful return) but was in a build not yet deployed. Included in this OMISIP rebuild.

- **[CRASH] `op_disconnect_ports.cold.3` — 1 crash** (`OMIRingback.m`) — `OMIRingback dealloc` called from `onCallState` OMISIP callback (holds PJSUA_LOCK) → `OMICall dealloc` → `self.ringback = nil` → `[OMIThread runSync:]` dispatches to global queue and waits → `pjsua_conf_remove_port` needs PJSUA_LOCK → **deadlock** → timeout → `op_disconnect_ports` assertion → SIGABRT. Fixed: changed `runSync` to `runNonBlock` in `OMIRingback dealloc` — fire-and-forget, never blocks the caller.

- **[CRASH] `cancel_timer.cold.1` — 1 crash** (`pjsua_core.c`) — `pjsua_update_stun_servers(wait=false)` called during cold start (VoIP push) while `pjsua_init`'s own async STUN resolution is still running (`stun_status==PJ_EPENDING`). Both sessions race to `pj_stun_sock_destroy` → `cancel_timer` assertion inside timer heap poll → SIGABRT. Root cause fixed in OMISIP C layer: `pjsua_update_stun_servers` now checks `stun_status==PJ_EPENDING` before calling `resolve_stun_server` — if pending, only updates the server list and returns (the in-flight session will complete naturally). ObjC layer unchanged.

- **[CRASH] `pj_leave_critical_section.cold.1` — 1 crash** (`OMISIPLib.m`) — `startEndpoint` dispatches to `dispatch_get_global_queue` which is a GCD thread not registered with OMISIP. `pjsua_transport_create` internally acquires/releases `pj_mutex` → `pj_mutex_unlock` asserts unregistered thread → SIGABRT. Fixed: added `[OMIThread ensureThreadRegistered]` inside the `dispatch_sync` block before calling `startEndpointWithEndpointConfiguration`.

- **[CRASH] `pjsip_endpt_unregister_module.cold.1` — 2 crashes** — Same root cause as `pj_leave_critical_section`: GCD thread calling OMISIP during endpoint init without thread registration. Covered by the same `ensureThreadRegistered` fix in `OMISIPLib.m`.

- **[CRASH] `pjmedia_vid_stream_pause.cold.1` — 9 crashes** (`OMIVideoCallManager.m`) — `triggerVideoRecoveryAfterMediaError` waits 300ms + 200ms before calling `pjsua_call_set_vid_strm(STOP_TRANSMIT)`. During this 500ms window the call can be hung up, destroying the video stream. `pjmedia_vid_stream_pause` asserts on destroyed stream → SIGABRT. Fix (media-active guard before STOP_TRANSMIT) was already in source but not yet deployed. Included in this build.

- **[CRASH] `objc_release`/`objc_release_x0` EXC_BAD_ACCESS — 4 crashes** (`os_core_unix.c`) — OMISIP worker thread `pjsua_0` exits without `@autoreleasepool` wrapper. Autoreleased ObjC objects accumulate on the thread-local pool. When thread exits, `_pthread_tsd_cleanup` drains the pool but some objects may already be deallocated elsewhere → `objc_release` on dangling pointer → `EXC_BAD_ACCESS (KERN_INVALID_ADDRESS)`. Fixed: wrapped `worker_thread` body in `@autoreleasepool { }` inside `thread_main` in OMISIP C layer (`#ifdef __OBJC__`).

---

## [1.11.11] - 2026-04-13

### Thread Safety

- **Assertion crash: "Calling pjlib from unknown/external thread"** (`OMICall.m`, `OMIEndpoint.m`) — Two SDK functions call OMISIP C API directly without registering the calling thread:
  1. `connectDuration` getter (`OMICall.m`) — calls `pjsua_call_get_info()`. Triggered when client app reads call duration from `DispatchQueue.global()` (SwiftUI `.onChange` after background→foreground).
  2. `resetOpusCodecToDefault` (`OMIEndpoint.m`) — calls `pjsua_codec_get_param()`. Triggered from `NSNotificationCenter` observer on `[NSOperationQueue mainQueue]` during call cleanup (cuộc 1 kết thúc → cleanup → reset codec → assertion → cuộc 2 bị ảnh hưởng).
  
  Fixed: added `[OMIThread ensureThreadRegistered]` at entry of both functions. No-op for already-registered threads.

---

## [1.11.10] - 2026-04-13

### Video Call — Resolution Change Fix (FIX QQ series)

- **[ROOT CAUSE] Remote video permanently lost after resolution change** (`vid_toolbox.m`) — When remote switches resolution (e.g. 240x426 → 360x640), VideoToolbox callback detects the new size but the first decode attempt fails (err:220082, P-frame mismatch). The `FMT_CHANGED` event broadcast was inside the decode-success-only branch, so it **never fired** on decode failure. Result: vid_conf never learned the new resolution → buffer overflow (`supplied=153360, required=345600`) looped forever → VT decode cascade → re-INVITE → OMISIP mutex deadlock → video dead permanently. Fixed: moved `FMT_CHANGED` broadcast outside the success/failure branch — fires regardless of decode result. **(FIX QQ-7)**

- **[BACKUP] Direct port format update on buffer overflow** (`vid_stream.c`) — When `get_frame()` detects buffer overflow, directly update decoder port format from `codec_param->dec_fmt` (already updated by VT callback). This lets vid_conf detect size mismatch via `cmp_size()` and resize buffer even if FMT_CHANGED event is delayed. Belt-and-suspenders for QQ-7. **(FIX QQ-6)**

- **[SAFETY] Block all re-INVITE escalation from decode cascades** (`OMIEndpoint.m`) — Previously, 4 separate code paths could trigger `forceReinviteForGPURecovery`: buffer overflow handler, VT cascade >10s, FIX ZZ Phase 3 (20s), and IFRM cascade. re-INVITE destroys entire media session → SDP renegotiation often causes remote to stop sending video → OMISIP mutex deadlock. All 4 paths now send PLI + reset cascade instead. Only intentional re-INVITE (video bitrate adaptation) remains. **(FIX QQ-5)**

- **[SAFETY] Prevent main thread deadlock from stats timer** (`OMICall.m`) — `calculateStats` and `checkIfAudioPresent` used `[OMIThread runSync:]` (dispatch_sync to global queue). When called from NSTimer on main thread during re-INVITE (OMISIP mutex held), main thread blocked indefinitely → all timers stopped → MOS loop died → no recovery possible. Changed to async `[OMIThread run:]`. **(FIX QQ-3)**

### Diagnostic Logging

- **SDP diagnostic logging in `onCallSdpCreated`** — Logs media direction, port, connection address for both local and remote SDP on every SDP creation (including re-INVITE).
- **Media state diagnostic logging in `onCallMediaState`** — Logs per-media type, status, direction, window ID, and video RTP packet counters (rx/tx) after every media state change.

---

## [1.11.9] - 2026-04-06

### Registration Fix

- **Registration fails with `OMISIP_EINVALIDURI` when UDP IPv4 STUN times out** (`OMIEndpoint.m`) — When STUN server is unreachable on UDP/IPv4 (e.g. blocked port), PJSIP falls back to UDP6 transport and sets `isV6Transport = YES`. TCP4 then creates successfully, but `isV6Transport` stays `YES`. Account Contact URI is built from UDP6 link-local (`fe80::`) instead of TCP4 IPv4 → PJSIP rejects as `Invalid URI (OMISIP_EINVALIDURI)` → registration never sends. Fixed: when TCP4 creates successfully in the has-valid-IPv4 path, reset `isV6Transport = NO` so Contact URI uses correct IPv4 address.

---

## [1.11.8] - 2026-04-06

### Crash Fixes

- **[CRASH A] `endSingleCall` NSRangeException** (`OMICallManager.m`) — `self.calls[0]` was read twice: once at call-site and once inside an async `dispatch_async(main_queue)` completion block. The array can be emptied between the two reads, making the second access out-of-bounds. Fixed: capture strong reference `callToEnd = self.calls[0]` before dispatch, add bounds check (`calls.count == 0`) and nil guard before subscripting.

- **[CRASH B] `getCallIDGenerate:` NSGenericException in CallKit** (`CallIDsManager.m`) — A nil `callUUID` passed to `getCallIDGenerate:` caused the method to return nil. Callers pass this return value directly to `CXEndCallAction` / `CXSetMutedCallAction`; CallKit initializes these actions via `__NSSingleObjectEnumerator init` which throws `NSGenericException` when given nil. Stack: `getCallIDGenerate:` → `callStateChanged:` → `setCallState:` → `decline:` → `provider:performEndCallAction:`. Fixed: nil guard at entry of `getCallIDGenerate:` returns `[NSUUID UUID]` instead of nil. Also fixed `genCallIDGenerate:callName:` with nil guard to prevent storing nil strings in `callIDsArray`, which would corrupt future lookups. Added nil checks for dictionary values inside the lookup loop.

---

## [1.11.7] - 2026-03-31

### Audio Routing

- **Video call forces speaker when Bluetooth/wired headset is connected** (`OMIAudioController.m`, `configureAudioSession`) — `DefaultToSpeaker` + `overrideOutputAudioPort:Speaker` were unconditionally applied to all video calls. Fixed by checking `availableInputs` for `BluetoothHFP` / `HeadsetMic` before applying speaker override. When external audio is detected, both overrides skipped and `overrideNone` set so iOS routes naturally.

- **FIX BT-1: First outgoing video call ignores Bluetooth headset** (`CallKitProviderDelegate.m`, `handleAudioRouteChange:`) — TWS headsets (JBL, AirPods) take 10-16s to reconnect HFP after app launch. `configureAudioSession` runs at call start (~T+0.1s) before HFP is available → speaker forced. When HFP reconnects mid-call, `handleAudioRouteChange` only logged but never reconfigured audio. Fixed: when `NewDeviceAvailable` fires with BT HFP in `availableInputs` and current output is Speaker during active video call, auto-reconfigure audio session to switch to headset.

### Video Recovery

- **FIX A v2: Rapid-fire re-INVITE storm on poor network** (`OMIEndpoint.m`, `onCallMediaState`) — `onCallMediaState` unconditionally reset `_lastForceReinviteTimestamp = 0` after every re-INVITE 200 OK, bypassing the 15s cooldown. On bad network: VT decode cascade → re-INVITE → `onCallMediaState` resets cooldown → another trigger fires immediately → 3 concurrent re-INVITEs in 1.4s → SIP race condition. Fixed with conditional reset: if re-INVITE was sent recently (< 30s), refresh timestamp to `now` (keeps 15s cooldown active); if > 30s or never, reset to 0 (preserves Fix A original intent for cross-call scenarios).

- **FIX BB: Blank remote video after GPU recovery re-INVITE** (`OMIVideoPreviewView.m`, `OMIVideoCallManager.m`, `OMIEndpoint.m`) — `flag=0` re-INVITE keeps same wid + same Metal view pointer. FIX AA hides Metal before re-INVITE, but `hasShownWindow=YES` on `remoteVideoView` never reset → all notification-driven re-show paths skip (same view + `hasShownWindow=YES`) → Metal stays hidden forever. Fixed: at T+2s after re-INVITE, `reshowMetalWindowAfterGPURecovery:` directly resets `hasShownWindow=NO` and calls `showVideoWindowWithId:`, bypassing the notification-driven path. Guards: `isSetup`, `isVideoStarted`, `isRecoveryInProgress`, wid-match prevent stale callbacks.

---

## [1.11.6] - 2026-03-30

### OMISIP Framework Rebuild (sip_timer race fix)

- **[CRASH #3] `pjsip_timer_init_session` abort after ICE completion** (`pjsip/src/pjsip-ua/sip_timer.c:625`) — Race condition between ICE async callback and endpoint shutdown: user hangs up → `pjsip_timer_deinit_module()` sets `is_initialized=FALSE` → ICE timer fires late → `on_make_call_med_tp_complete` → `pjsip_timer_init_session` → `pj_assert(is_initialized)` → **SIGABRT**. Fixed by replacing `pj_assert(is_initialized)` with `PJ_ASSERT_RETURN(is_initialized, PJ_EINVALIDOP)` — converts fatal abort to graceful error return. Caller already handles `status != PJ_SUCCESS` via `goto on_error`. OMISIP framework rebuilt from source; all existing configuration preserved (video 1080p@30fps, VideoToolbox HW H.264, OpenH264, Opus 48kHz, ICE/STUN/TURN, TLS/SRTP, WebRTC AEC).

### Crash Fixes (Crashlytics v3.4.2 — 30-day report)

- **[CRASH #2] `pjmedia_port_destroy` abort on NULL port** (`OMIRingback.m`) — `dealloc` called `pjmedia_port_destroy(NULL)` when `pjmedia_tonegen_create2` failed in `init` (e.g. pool exhaustion). Added NULL guard: early-return if `ringbackPort == NULL`. Also fixed memory leak: port was never destroyed when `conf_remove_port` failed on double-stop — now always destroys port if non-NULL.

- **[CRASH #2] `OMICall` dealloc inside PJSIP C callback** (`OMIEndpoint.m`, `onTxStateChange`) — All 3 `OMICall` lookups inside `onTxStateChange` (CANCEL, BYE, ACK blocks) used `__weak OMICall *call`. ARC could release the call object mid-callback while PJSIP still holds execution. Changed to strong references to defer dealloc past the callback scope.

- **[CRASH #6] `CXCallAction` nil UUID crash** (`OMIEndpoint.m`, `onTxStateChange`) — CANCEL and BYE dispatch blocks captured `call.uuid` lazily inside `dispatch_async`. By the time the block ran on main thread, `__weak call` was already nil. Fixed by capturing UUID into a strong local variable before the `dispatch_async` block, with nil guard inside the block.

- **[CRASH #8] `NSRegularExpression` crash on nil input** (`OMIUtils.m`) — `isPhoneNumber:nil` and `formatPhoneNumber:nil` passed nil to `numberOfMatchesInString:options:range:`, which throws `NSInvalidArgumentException`. Added nil/empty guard at entry of both methods: return `NO`/`@""` immediately.

- **[CRASH #9] `pjsua_conf_connect2` assertion on invalid port** (`OMICall.m`, `toggleMute:`) — Mute triggered on a call that was already ended: `conf_slot` was invalid (≤ 0) but code fell through and called `pjsua_conf_connect`. Added `pjsua_call_is_active` guard at entry, and `return` after `conf_slot <= 0` error log.

- **[CRASH #10] `NSCFString` out-of-bounds in `wasCallMissed:`** (`OMIEndpoint.m`) — `__weak` reference to `OMICall` was released before `getCallerName:` accessed `callerName`, feeding a nil or freed string to regex. Changed to strong reference + nil guard before string operations.

---

## [1.11.5] - 2026-03-27

### Multi-Call Handling (2-layer rejection)

- **Layer 1 — VoIP Push rejection** (`VoIPPushHandler.m`, FIX MULTI-CALL) — When push B arrives while call A is ringing, auto-reject with dummy CallKit report. Fully defensive: `@try/@catch`, nil checks, array copy for mutation safety. Fallback always allows push (never blocks user by mistake).

- **Layer 2 — SIP INVITE rejection** (`OMIEndpoint.m`, FIX MULTI-CALL-2) — When INVITE B arrives on same TCP session (no push), reject with `486 Busy Here` if call A is ringing. Only rejects calls with `callId >= 0` (real INVITE matched) — push placeholders (`callId=-1`) are skipped to avoid rejecting the first call's own INVITE. Re-INVITE for same `call_id` also skipped.

- **Rule**: Call A ringing → reject B (486). Call A confirmed → allow B (CallKit shows both, user decides). No existing call → proceed normally.

### Audio

- **Speaker toggle no longer kills call** (`OMIEndpoint.m`) — AUDIO-STORM threshold increased from 30→60, window decreased from 2.0s→0.5s. Speaker switch causes ~30 underflows in 0.3s (below new threshold). Real network death causes 100+ underflows (still detected). No grace period needed — pure threshold adjustment.

### Diagnostic Logging

- **Multi-call diagnostic in performEndCallAction** (`CallKitProviderDelegate.m`) — When ending a call with multiple calls active, logs all remaining calls (uuid, state, phone, callId) + auto-uploads log file. Helps diagnose "decline call 2 kills call 1" reports from customers.

- **OMICloseCall diagnostic** (`OmiClient.m`) — Warning log when `closeAllCalls` runs with >1 active call. Helps trace unexpected multi-call teardown.

- **Endpoint init tracking** (`OMIEndpoint.m`) — Logs endpoint creation with call count context (appendLog, no upload). Helps trace rapid endpoint restart cycles seen in customer logs.

### Call Handling

- **haveAnotherCall skip disconnected/disconnecting** (`OmiClient.m`) — `getNewestCall` check now allows new calls when existing call is already `disconnected` or `disconnecting` (OMISIP cleanup delay). Previously the most common customer complaint — user couldn't redial after call ended.

- **Zombie call cleanup** (`OmiClient.m`, FIX STUCK-1/STUCK-2) — Outgoing calls stuck >60s in EARLY/CALLING/CONNECTING state are force-removed. Endpoint with stuck calls >90s are cleaned in `isSafeToRemoveSipEndpoint`. Prevents permanent "haveAnotherCall" block requiring app restart.

- **haveAnotherCall diagnostic logging** (`OmiClient.m`) — All 3 exit paths (double-tap, existing call, waitForDisconnect fail) now log full context: SIP user, endpoint state, all active calls with uuid/state/phone/createDate. Auto-uploads log file for server-side analysis. Search `[HaveAnotherCall]` in logs.

### Sample App

- **CallingView timer fix** (`ViewController.m`) — Outgoing: reuse existing CallingView at CONFIRMED instead of creating new one. Incoming: start timer in present completion block. Timer now counts correctly for both directions.

---

## [1.11.4] - 2026-03-23

### Multi-Call Support

- **New API: `endCallWithUUID:`** — End a specific call by UUID. Safe for multi-call scenarios: decline call 2 without affecting call 1.

- **New API: `endCall:andAnswerCall:`** — End current call and answer incoming call with 500ms OMISIP cleanup delay. For "End & Answer" flow when user on call 1 wants to pick up call 2.

- **New API: `getAllActiveCalls`** — Returns array of all active calls (uuid, state, phone, incoming, isVideo, isOnHold) for multi-call UI display.

- **Multi-call diagnostic logging** (`CallKitProviderDelegate.m`) — When ending a call with other calls active, logs all call states before and 1s after action. POST-CHECK verifies surviving call is still alive. Writes to LogFileManager for server upload.

- **`OMICloseCall` warning log** (`OmiClient.m`) — Logs warning with full call list when `OMICloseCall` is called with multiple active calls. Helps diagnose "decline call 2 kills call 1" customer reports.

### Call Handling

- **`haveAnotherCall` diagnostic in log file** (`OmiClient.m`) — `logHaveAnotherCallDiagnostic` now writes to `LogFileManager.appendLog` before upload. Previously diagnostic only went to CocoaLumberjack console — invisible in customer-uploaded log files.

- **`haveAnotherCall` disconnected/disconnecting fix** (`OmiClient.m`) — `startCall` no longer rejects new calls when existing call is in `disconnected` or `disconnecting` state. OMISIP cleanup delay caused false "haveAnotherCall" when user called immediately after previous call ended.

### Audio

- **AUDIO-STORM speaker toggle fix** (`OMIEndpoint.m`) — Threshold increased from 30→60, window decreased from 2s→0.5s. Speaker switch causes ~30 audio underflows in 0.3s which false-triggered call termination. Real network death (100+ underflows) still detected.

### ICE/STUN Configuration

- **STUN/TURN provider visibility** (`OmiClient.m`) — `applyDynamicConfiguration` now logs matched STUN/TURN servers from API provider. Previously only proxy was logged, STUN/TURN was silently cached without visibility.

### Sample App

- **CallingView timer fix** (`ViewController.m`) — Outgoing: reuses existing CallingView on CONFIRMED instead of creating duplicate. Incoming: starts timer in present completion block since CONFIRMED notification fires before CallingView exists.

---

## [1.11.3] - 2026-03-19

### Crash Fixes (Crashlytics top crashes — ~503 crashes eliminated)

- **NSRangeException crash** (`OMIEndpoint.h`, Crash #2/#7/#8 — 255 crashes) — `OMIEndpointStateString` macro had 3 elements but enum had 4 (`OMIEndpointClosing`). `objectAtIndex:3` on 3-element array → crash. Fixed: added `"OMIEndpointClosing"` + safe bounds check returns `"Unknown"` for any future out-of-range values.

- **EXC_BAD_ACCESS pjmedia_codec_mgr_enum_codecs** (`OMIEndpoint.m`, `OMICallStats.m`, Crash #3 — 72 crashes) — `pjsua_enum_codecs()` called with NULL codec_mgr during VoIP push cold start. 4 call sites missing NULL guard (1 already had it). Fixed: added `pjsua_get_pjmedia_endpt()` + `pjmedia_endpt_get_codec_mgr()` NULL check before every `pjsua_enum_codecs` call.

- **PushKit VoIP kill by iOS** (`VoIPPushHandler.m`, Crash #4 — 85 crashes) — Duplicate VoIP push detection (FIX PUSH-1) called `completion()` without `reportNewIncomingCall` → iOS killed app. Fixed: duplicate push path now calls `reportAndEndDummyCallWithCompletion` to satisfy PushKit requirement.

- **pjsip_timer_init_session crash** (`OMICallManager.m`, Crash #5 — 91 crashes) — `startCallToNumberNoReg` created OMISIP session while endpoint transitioning to Closing state → session pool corrupt → crash. Fixed: added `pjsua_get_state() != PJSUA_STATE_RUNNING` guard before call creation.

### Call Handling

- **OMIHaveAnotherCall false positive** (`OmiClient.m`) — `getNewestCall != nil` rejected new calls even when existing call was already `disconnected`/`disconnecting` (OMISIP cleanup delay). Most common customer complaint. Fixed: added `callState` check — only reject if existing call is truly active (not disconnected/disconnecting).

- **OMIHaveAnotherCall diagnostic logging** (`OmiClient.m`) — All 3 HaveAnotherCall exit paths now log full context (SIP user, endpoint state, all active calls with uuid/state/phone/createDate) and auto-upload log file. Search `[HaveAnotherCall]` on server to diagnose.

### Audio

- **AUDIO-STORM speaker toggle fix** (`OMIEndpoint.m`) — Toggle speaker caused ~30 audio underflows in 0.3s → AUDIO-STORM detector killed the call. Fixed: increased threshold from 30→60 and decreased window from 2s→0.5s. Speaker switch (~30 underflows) stays below threshold, real network death (100+ underflows) still detected.

### Sample App

- **CallingView timer not starting** (`ViewController.m`) — Outgoing call: CallingView presented at CALLING state, then CONFIRMED created a NEW CallingView → timer reset to 0. Fixed: CONFIRMED reuses existing CallingView, only updates `callUUID`. Incoming call: CallingView presented AT CONFIRMED → missed CONFIRMED notification. Fixed: `startCallTimer` called in present completion block.

---

## [1.11.2] - 2026-03-18

### Video Call Stability (OMISIP Metal Renderer)

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

## [1.11.0] - 2026-03-15

### Fixed

- **App freeze (deadlock) after FORMAT_CHANGE during video call** — ABBA deadlock between OMISIP decode thread (holding stream mutex, waiting for PJSUA_LOCK) and PLI retry thread (holding PJSUA_LOCK, waiting for stream mutex). `onCallMediaEvent` FMCH callback called `pjsua_call_get_info()` directly on decode thread → deadlock → app completely unresponsive.

  **Fix II** (`OMIEndpoint.m`): Capture event data (`size`, `call_id`, `med_idx`) by value before async dispatch, then wrap all FMCH processing in `[OMIThread run:^{...}]` to execute on GCD queue with OMISIP thread registration instead of on the decode thread holding stream mutex.

- **EXC_BAD_ACCESS crash after ~30s in video call** — `attemptViewSwapRecovery` called from `handlePJIgnoredBurstDetected` on GCD background thread created UIView and accessed `self.remoteContainerView.bounds` off main thread → crash at `objc_msgSend`.

  **Fix JJ-1** (`OMIVideoCallManager.m`): Wrapped UIView creation in `dispatch_sync(dispatch_get_main_queue(), ^{...})` with `[NSThread isMainThread]` guard.

- **Outgoing video call: local camera shows briefly then goes blank until CONFIRMED** — `startLocalVideoImmediately` starts camera at call initiation (`isLocalVideoInitComplete=YES`). `prepareForVideoDisplay` fires during EARLY state → after 100ms delay calls `createInternalVideoViews` → destroys localVideoView with running camera → blank screen until CONFIRMED state recreates views.

  **Fix KK** (`OMIVideoCallManager.m`): In `prepareForVideoDisplay`, skip `createInternalVideoViews` if `isLocalVideoInitComplete == YES` — both remote and local views already exist with camera running.

---

## [1.10.38] - 2026-03-15

### Fixed

- **Incoming video call: screen freezes permanently after answer** — Race condition in `handlePJIgnoredBurstDetected` re-setting `hasMetalDrawableError=YES` during the Metal stream restart stabilization window after FMCH, permanently blocking `hideLoadingIndicator`.

  **Root cause chain** (Fix QQ-3, `OMIVideoPreviewView.m`):
  1. VT decode cascade (15 errors / 0.5s) fires → `handleH264DecodeErrorBurst` (FIX PP) sets `hasMetalDrawableError=YES` + schedules 5000ms Metal recovery
  2. FMCH (format change 1920x1080→640x480) fires ~1.6s later → `handleMetalStreamRestarted` clears `hasMetalDrawableError=NO` + increments `keyframeRetryGeneration` (cancels 5000ms block) + schedules `dispatch_async(main_queue, ^{ hideLoadingIndicator })`
  3. Metal stream physically restarts immediately ("Starting Metal video stream gen=1")
  4. Within the ~100-200ms stabilization window before drawable pool is fully initialized, OMISIP delivers frames → PJ_EIGNORED burst fires
  5. `handlePJIgnoredBurstDetected` sets `hasMetalDrawableError=YES` AGAIN
  6. `dispatch_async(main_queue, ^{ hideLoadingIndicator })` from step 2 arrives, sees `hasMetalDrawableError=YES` → BLOCKED → loading spinner stuck FOREVER → user sees frozen screen

  **Fix**: Added 500ms grace period in `handlePJIgnoredBurstDetected` using existing `lastMetalStreamRestartTimestamp` property (already set in `handleMetalStreamRestarted`). PJ_EIGNORED during this window is expected (same pattern as existing camera switch guard FIX W1). After 500ms, drawable pool is fully initialized and genuine burst detection resumes normally.

---

## [1.10.37] - 2026-03-12

### Fixed

- **Outgoing video CONFIRMED state: app frozen 4.6s, video never shows** — Two-stage deadlock in `executeShowVideoWindow:` (`OMIVideoPreviewView.m`):

  **Stage 1 (Fix D)**: `[OMIThread runSync:]` → `dispatch_sync(GLOBAL_DEFAULT)` on main thread + `createViewForVideoLocalAsync` on `GLOBAL_HIGH` holding PJSUA_LOCK during camera init → 3-party deadlock. `hasShownWindow` never set → video never shown. Fixed by replacing `dispatch_sync` with `dispatch_async(GLOBAL_HIGH)`.

  **Stage 2 (Fix E)**: After Fix D, `pjsua_call_get_stream_stat` was still called on the main thread (lines 1281-1290) for packet baseline initialization. This call acquires PJSUA_LOCK → blocked main thread for 4.6s while `createViewForVideoLocalAsync` (camera restart at CONFIRMED) held the lock. Main thread frozen → `dispatch_async(GLOBAL_HIGH)` for `pjsua_vid_win_set_show` never queued → `dispatch_after` keyframe requests never fired → video never shown for the duration of the log. Fixed by moving `pjsua_call_get_stream_stat` inside the `dispatch_async(GLOBAL_HIGH)` block so the main thread is NEVER blocked on PJSUA_LOCK.

---

## [1.10.36] - 2026-03-12

### Fixed

- **Outgoing video call takes 10s+ to connect, freezes at 20s** — Three compounding bugs caused the delay and freeze:

  1. **Fix A — Premature video start at EARLY (183) state** (`OMIVideoCallManager.m`): `onCallMediaState` fired `OMIVideoRemoteReady` during 183 ringing (remote doesn't send video until `CONFIRMED`). SDK attempted to show Metal window → no frames for ~5s → 5s watchdog timer fired → re-INVITE skipped (EARLY state) → wasted 5s. Fixed by detecting outgoing+EARLY state in `handleVideoNotification:` and deferring video start to `CONFIRMED`. `pendingWindowId` stores the wid; `handleCallStateChanged` triggers `startVideoPreviewWithRetry` when CONFIRMED fires.

  2. **Fix B — New Metal views stuck with wid=-1 after CONFIRMED** (`OMIVideoCallManager.m`, `OMICall.m`): At `CONFIRMED`, `SampleVideoCallViewController` pushed → `createInternalVideoViews` destroyed old Metal views and created fresh ones. `mediaStateChanged` fired again with same wid=1 → `videoReadyNotificationPosted` flag blocked the notification → new Metal views never received their wid → black screen forever. Fixed by calling `resetVideoReadyNotificationState` on the active `OMICall` inside `createInternalVideoViews`, allowing the next `mediaStateChanged` to re-post `OMIVideoRemoteReady` to the fresh views.

  3. **Fix C — IFRM cascade fires force re-INVITE on working video** (`OMIEndpoint.m`): After ~15s of IFRM (keyframe-missing) events (normal during PLI/keyframe request cycles), `forceReinviteForGPURecovery` was called unconditionally, destroying ALL media (audio+video) and causing 5-10s freeze + audio underflow storms. Fixed by checking `checkIsVideoReceivingFrames` before escalating: if video frames are flowing normally → reset IFRM cascade tracking (no re-INVITE); if video is genuinely not flowing → escalate as before.

- **Declining call B (CallingView) causes broken state when call A is active** — CallingView was presented at `OMICallStateIncoming` (before CallKit answer). When user declined via CallingView while call A active, old CallingView not dismissed cleanly. Fixed by moving CallingView presentation to `OMICallStateConfirmed` only (after actual answer). Added dismiss-existing-CallingView guard before presenting new one (Example/ViewController.m)

### Added

- **`OMICallWaitingForEndpoint` status** — New `OMIStartCallStatus` enum value sent as intermediate callback when `startCall` is waiting for endpoint teardown. Completion block fires twice: first `OMICallWaitingForEndpoint` (client shows loading), then final status (success/fail). Sent from `startCall2` and `handleExistingEndpoint` when detecting `OMIEndpointClosing` state (OMICall.h, OmiClient.m)

---

## [1.10.35] - 2026-03-10

### Fixed

- **Rapid repeated `startCall` creates duplicate calls** — Added static `_isStartingCall` guard at `startCall:` entry to prevent concurrent call setups. When client calls `startCall` multiple times rapidly, only the first invocation proceeds; subsequent calls receive `OMIHaveAnotherCall` immediately. Guard is reset via `wrappedCompletion` in `makeCall` (covers all exit paths: success, 403, fail, register fail). Additional resets in `handleCallSetupForNumber` (disconnect fail), `startCall2` (max retry). 30-second safety timeout auto-resets the flag if stuck due to missed edge case (OmiClient.m)

- **Call immediately after hangup causes 3-5s silent freeze** — When endpoint is mid-destroy (`OMIEndpointClosing`) after previous call ended, `startOmiService` kicked off async config that raced with the ongoing destroy. Now `startCall2` detects `OMIEndpointClosing` and skips `startOmiService`, going directly to `handleEndpointNotAvailable` which properly waits for destroy completion before retrying (OmiClient.m)

- **Declining incoming call B kills audio of active call A** — `performEndCallAction` called `deactivateSoundDevice` unconditionally for every end call action. `pjsua_set_no_snd_dev()` is GLOBAL — it closes the single shared audio device for all OMISIP calls. When user declines call B while call A is active, this killed call A's audio immediately. Fixed by checking if other active calls exist before deactivating; skips `deactivateSoundDevice` when other calls are still running (CallKitProviderDelegate.m). Secondary fix: `setCallState` Disconnected handler now uses account-agnostic `getAllCalls` check alongside `activeCallsForAccount` to prevent false-empty from account mismatch triggering redundant audio deactivation (OMICall.m)

- **End call A + accept call B → audio lost on call B** — CallKit transition fires `AVAudioSessionInterruptionTypeBegan` temporarily. `audioInterruption:` unconditionally called `deactivateSoundDevice` → posted `OMIAudioControllerAudioInterrupted` → `OMICall.audioInterruption:` called `toggleHold` → re-INVITE with sendonly SDP → call B permanently on HOLD. Fixed by adding active-calls guard: when `InterruptionTypeBegan` fires and active calls exist, skip `deactivateSoundDevice` and do NOT post the interrupted notification (OMIAudioController.m)

- **Decline call B kills active call A — spam check targets wrong call** — `startCheckSpamCalls` was a GLOBAL check without per-call targeting. VoIP Push for Call B starts spam timer → user declines Call B → Call B removed → 2s timer fires → finds 1 remaining call (Call A) + empty `stateSignalSwitchBoard` → ends Call A. Fixed by adding `forCallUUID:` parameter binding spam check to the specific VoIP push call UUID. If target call no longer exists when timer fires, spam check exits early (OMICallManager.m, OMICallManager.h, VoIPPushHandler.m)

### Added

- **`OMICallWaitingForEndpoint` status** — New `OMIStartCallStatus` enum value sent as intermediate callback when `startCall` is waiting for endpoint teardown. Completion block fires twice: first `OMICallWaitingForEndpoint` (client shows loading), then final status (success/fail). Sent from `startCall2` and `handleExistingEndpoint` when detecting `OMIEndpointClosing` state (OMICall.h, OmiClient.m)

---

## [1.10.34] - 2026-03-05

### Fixed

- **Outgoing call disconnects immediately when remote answers** — Audio underflow storm detector (Fix N) was false-triggering on ringback teardown at `CONFIRMED` state. When the remote party answers, OMISIP disconnects the ringback tone port (`Conf disconnect: 1 -x- 0`) causing a brief `playdbuf/capdbuf` underflow burst (~30 underflows in 0.4s) — a normal, self-resolving audio glitch. This burst incorrectly matched the TCP RST storm threshold (30 underflows in 2s), causing `CXEndCallAction` to fire at `call_secs=0` and disconnect the call. Fixed by adding a 3-second suppression window after call enters `CONFIRMED`: underflow bursts within 3s of `CONFIRMED` are discarded and the counter reset. Real TCP RST storms (which occur after the call has been running for several seconds) are unaffected. Uses a file-scope `_lastCallConfirmedTimestamp` static (ARM64 atomic double) set in `onCallState` — safe to read from the audio thread without ObjC object access (OMIEndpoint.m)

---

## [1.10.33] - 2026-03-04

### Added

- **DNS pre-warm for TURN/STUN servers** — Added `+prewarmDNSForHosts:` class method on `OMIEndpoint` that runs `getaddrinfo` on a HIGH priority background thread to warm the OS DNS cache before OMISIP needs to resolve TURN/STUN hostnames. Called automatically in `createAccountWithSipUser:` with the actual dynamic STUN/TURN servers from the account configuration (vary per country/network). Eliminates TURN DNS cold-start delay of 5+ seconds that caused `PJ_ETIMEDOUT` on first outgoing call after a cold app launch (OMIEndpoint.m, OMIEndpoint.h, OMISIPLib.m)

### Fixed

- **`logoutWithCompletion:` always returns YES** — HTTP device deregister request is best-effort cleanup. Local SIP session is always cleared regardless of HTTP result. Returning `NO` on HTTP failure caused callers to incorrectly believe logout failed and block re-login. Completion now always called with `YES` (OmiClient.m)

---

## [1.10.32] - 2026-03-04

### Added

- **`logoutWithCompletion:` method** — Added async logout with completion callback so app can call login immediately after logout without arbitrary delay. HTTP deregister request runs on background queue; completion is always called on main thread with `success=YES/NO`. Original `logout` method preserved for backward compatibility (OmiClient.m, OmiClient.h)

### Changed

- `logout` now internally delegates to `logoutWithCompletion:nil` — identical behavior, no breaking change

---

## [1.10.31] - 2026-03-03

### Added

- **Network check before startCall (fast-fail)** — Added `isNetworkAvailable` class method (singleton Reachability) to check network before attempting SIP registration. `startCall:` and `startCallWithUuid:` now return `OMINoNetwork` immediately (<1ms) when device has no connection, instead of waiting 10-32s for SIP registration timeout. New `OMINoNetwork` status added to `OMIStartCallStatus` enum (OmiClient.m, OmiClient.h, OMICall.h)

### Changed

- `OMIStartCallStatus` enum — Added `OMINoNetwork` value for explicit no-network error detection

---

## [1.10.29] - 2026-03-02

### Critical Crash Fixes (Firebase Crashlytics)

- **P0: Speaker button causes call disconnect on iOS 18** — `OMIAudioController.setOutput:` called `setCategory:PlayAndRecord mode:VoiceChat` (missing Bluetooth options, wrong mode for video) + `setActive:YES` (conflicts with CallKit audio session ownership). iOS 18 enforces strict CallKit → audio interruption → `deactivateSoundDevice` → call disconnect. Fixed by removing `setCategory` and `setActive:YES`, keeping only `overrideOutputAudioPort:` for speaker toggle. Bluetooth path uses `setPreferredInput:` separately (OMIAudioController.m)
- **P0: pjmedia_codec_mgr_enum_codecs crash (17 crashes, 14 users)** — `pjmedia_codec_mgr` NULL during VoIP push cold start. `@try-@catch` cannot catch C-level EXC_BAD_ACCESS. Single 100ms delay insufficient. Fixed by: (1) NULL check `pjsua_get_pjmedia_endpt()` and `pjmedia_endpt_get_codec_mgr()` before `pjsua_enum_codecs`; (2) Retry mechanism `updateAudioCodecsWithRetry:` with delays 200ms→500ms→1000ms replacing single dispatch_after (OMIEndpoint.m)
- **P0: PushKit kills app — "never posted incoming call" (14 crashes, 7 users)** — iOS requires `reportNewIncomingCall` for EVERY VoIP push. Multiple early-return paths (callId nil, UUID invalid, virtual push, provider nil) called `completion()` without reporting CallKit → iOS kills app. Fixed by adding `reportAndEndDummyCallWithCompletion:` — reports dummy incoming call then immediately ends it. All early-return paths in `VoIPPushHandler.handle` and `PushKitManager.didReceiveIncomingPush` now call this method (VoIPPushHandler.m, VoIPPushHandler.h, PushKitManager.m)

### Changed

- `updateAudioCodecs` return type changed from `void` to `BOOL` (returns NO if codec manager not ready)
- Added `updateAudioCodecsWithRetry:` method with escalating delays for cold start reliability
- Exposed `reportAndEndDummyCallWithCompletion:` as public class method on VoIPPushHandler

---

## [1.10.27] - 2026-02-25

### Video Call - Critical Fixes

- **Critical: VideoToolbox H.264 decode failures causing 43s video lag** - Old code assigned Level 3.0 profile (`42001e`) for portrait videos (width < 1280), but 480x854 = 409,920 pixels exceeds Level 3.0 max (345,600) → VideoToolbox rejected ALL frames → 435 decode failures. Fixed by always using Level 4.0 (`420028`) profile which handles all resolutions up to 2M pixels. Also removed `decoderSizeChanged` condition that triggered mid-call decoder changes causing Metal stream restart and GPU Timeout (OMIEndpoint.m)
- **Critical: Incoming video call loading forever** - `reinviteWithVideoIfCalling` had wrong guard using `isVideoActive` instead of `checkIsVideoReceivingFrames`. `isVideoActive=YES` only means OMISIP opened media channel, NOT that frames are flowing (TURN CreatePermission can lag 2s+). Fixed by removing `isVideoActive` guard and relying solely on `checkIsVideoReceivingFrames` (real Metal frame count). Added 5s fallback timer after video window shown to force re-INVITE if no frames received (OMIEndpoint.m, OMIVideoCallManager.m)
- **Critical: onCallState CONFIRMED not fired after ACK** - OMISIP fires `on_tsx_state(CONFIRMED)` when UAS receives ACK but does NOT fire `on_call_state(CONFIRMED)`. This caused remote video to stay on loading forever because `reinviteWithVideoIfCalling` was never triggered. Fixed by detecting UAS INVITE CONFIRMED in `on_tsx_state` callback and manually calling `callStateChanged:` (OMIEndpoint.m, OMIVideoCallManager.m)
- **Critical: PJ_ETOOBIG (70017) → no video both sides on App→Web calls** - `reinviteWithVideoIfCalling` used `pjsua_call_update()` with `PJSUA_CALL_UPDATE_VIA` flag → triggered `OMISIP_CALL_REINIT_MEDIA` → destroyed all media BEFORE SDP generation → SDP with ICE candidates exceeded `OMISIP_MAX_PKT_LEN=4000` → PJ_ETOOBIG → media permanently lost. Fixed by: (1) Removing `pjsua_call_update()` entirely, using only `pjsua_call_reinvite2()` with flag=0; (2) Increasing outgoing call CONFIRMED delay from 2s to 5s; (3) Adding `OMISIP_MAX_PKT_LEN=8000` to config_site.h (OMIEndpoint.m, OMIVideoCallManager.m, config_site.h)
- **Critical: vid_conf buffer overflow → outgoing video loading** - OMISIP vid_conf.c internally resizes decode buffer on FMT_CHANGED (1504x1504 → 480x360 → buffer shrinks to 259,200). When remote changes to 640x480, VideoToolbox needs 460,800 bytes → overflow. Fixed by detecting "not enough buffer" log message immediately and triggering `reinviteWithVideoIfCalling` with 8s cooldown (OMIEndpoint.m)
- **Critical: VT-DECODE-ERROR cascade → 29s frozen video on outgoing calls** - 4th `onCallMediaState` (FreeSWITCH ICE renegotiation) triggered Metal addPresentedHandler errors → VT session malfunction (-12909) → cascade. Metal recovery hid/showed window creating 23s "lull" where no errors fired → normal escalation check missed it. Fixed by adding guaranteed 8s dispatch_after timer from cascade START. Also: reset `_lastForceReinviteTimestamp` in `onCallMediaState`, reduced reinvite cooldown from 30s to 15s with deferred retry, and added `isVTDecodeCascadeActive` method to prevent false RTCP-based cascade resolution (OMIEndpoint.m, OMIVideoPreviewView.m)
- **Critical: Video freeze + app unresponsive after 15s (infinite re-INVITE loop)** - Level 5.1 decoder (2912x2912 Metal port) + FMT_CHANGED resize corruption + no cooldown caused infinite loop: re-INVITE → Level 5.1 → FMT_CHANGED → corruption → 8s timer → re-INVITE → repeat. Fixed by: (1) Changed decoder from Level 5.1 to Level 4.2 (~1500x1500 Metal port); (2) Reset cascade state in FMT_CHANGED handler; (3) Reduced max hard recovery attempts to 2 with 15s cooldown; (4) Always recreate Metal views during GPU recovery to prevent corrupted CAMetalLayer reuse (OMIEndpoint.m, OMIVideoCallManager.m, OMIVideoPreviewView.m)
- **Critical: Transient VT -12909 triggers unnecessary re-INVITE → video lost + app freeze** - Single transient VT decode error (1-frame corrupt packet) triggered immediate re-INVITE → REINIT_MEDIA destroyed ALL media → ICE UPDATE → TCP RST → audio underflow storm → app freeze. Fixed by adding transient error gate: check `checkIsVideoReceivingFrames` first — if video IS receiving → send PLI burst instead of re-INVITE → wait 3s → check if cascade resolved. Only escalate to re-INVITE if cascade persists (OMIVideoPreviewView.m)
- **Critical: GPU Timeout during PLI recovery wait** - Metal window stayed active during PLI recovery → OMISIP kept sending frames to corrupted Metal port → 350+ GPU Timeout errors in 5s → GPU entered "penalty box" → ALL Metal rendering rejected 30s+. Fixed by hiding Metal window immediately when entering PLI recovery (`pjsua_vid_win_set_show(PJ_FALSE)`) → stops frame delivery → no GPU commands → no GPU Timeout (OMIVideoPreviewView.m)
- **Critical: SIP UPDATE → remote video disappears after ~1 minute** - Remote server sends SIP UPDATE with SDP renegotiation → OMISIP destroys old video stream → creates new stream with SAME window ID (wid=1) but NEW Metal UIView. Old guard `lastVideoWindowId != videoWindowId` → FALSE → notification skipped → new UIView never added to view hierarchy. Fixed by comparing OMISIP render view pointer (`pjsua_vid_win_get_info` → `wi.hwnd.info.ios.window`) instead of window ID. New `lastVideoRenderViewPtr` property detects stream recreation even when wid is unchanged (OMICall.m)
- **Critical: Background→Foreground video failure (intermittent)** - 4 compounding bugs during background→foreground transition: (1) `forceReinviteForGPURecovery` dispatch_after on main queue never fires when main queue blocked → moved to global queue; (2) cooldown timestamp set before dispatch_after (never fires = cooldown blocks all retries 15s) → moved inside block; (3) stale `lastVideoWidth` on singleton across endpoint recreations → reset on startup; (4) `lastSuccessfulRenderTimestamp` guard 2.0s too generous for background→foreground → reduced to 0.5s (OMIEndpoint.m, OMIVideoPreviewView.m)
- **Metal drawable error detection** - Metal "addPresentedHandler" errors go to stderr directly, not through OMISIP logCallBack → detection never fired. Fixed by piggybacking Metal recovery on H264 decode error burst notification (always co-occur) instead of relying on log detection (OMIVideoPreviewView.m)

### Audio Call - Critical Fixes

- **Critical: Audio underflow storm → app freeze, can't end call** - TCP RST kills SIP transport → audio device enters infinite underflow loop (50+ underflow messages in 30ms) → floods logCallBack → blocks OMISIP thread → app unresponsive. Fixed by: (1) Early return in logCallBack with static storm detection flag (skip ALL underflow messages once detected); (2) Count rapid underflow messages (threshold=30 in 2s) → force CallKit CXEndCallAction (works without OMISIP mutex) (OMIEndpoint.m)
- **Critical: Hangup deadlock → app freeze + infinite audio loop** - Cascading PJSUA_LOCK deadlock: internal thread holds lock → `pjsua_call_hangup` blocks → `deactivateSoundDevice` blocks → `dispatch_after(100ms) removeCall` on main thread → `destroyEndpoint` → main thread blocked → UI freeze. Fixed by: (1) Removed `dispatch_after removeCall` from CallKitProviderDelegate; (2) Rewritten hangup to be fully async (no semaphore wait); (3) Emergency AVAudioSession deactivation on hangup failure; (4) 5s safety timeout with forced cleanup; (5) Removed synchronous `toggleMute:` from postCallCleanup (CallKitProviderDelegate.m, OMICall.m)
- **Critical: EXC_BAD_ACCESS in handle_incoming_sip_message** - `rdata->msg_info.msg_buf` is a `char*` pointer that gets corrupted during OMISIP internal processing (ICE/TURN init + 100 Trying). `stringWithUTF8String:` tries to read from corrupted address → EXC_BAD_ACCESS (Mach exception, cannot be caught by @try-@catch). Fixed by using `rdata->pkt_info.packet` (fixed `char[]` array embedded in rdata struct) with bounds-safe `initWithBytes:length:encoding:` (OMIEndpoint.m)
- **Critical: Spam check kills answered call ("call failed" on accept from background)** - Root cause chain: (1) OMISIP reuses rdata buffer during INVITE processing → `pkt_info.packet` overwritten by 401 REGISTER response; (2) `handle_incoming_sip_message` reads REGISTER instead of INVITE → `stateSignalSwitchBoard` not set; (3) spam check timer (2s) finds empty `stateSignalSwitchBoard` → sends CXEndCallAction; (4) `performEndCallAction` calls `decline:` on already-answered call (Connecting state). Fixed by: (1) Setting `stateSignalSwitchBoard = @"INVITE\r"` directly in `onIncomingCall` (always INVITE); (2) Changed decline condition to only decline in Early state (pre-answer), Connecting/Confirmed must use hangup; (3) Added logging for rdata corruption detection (OMIEndpoint.m, CallKitProviderDelegate.m)

### Video Quality Improvements

- **Remote video artifacts "hột mè sọc sọc" (macroblocking)** - Encoder bitrate was too low (600 Kbps for 480x640@20fps = 0.098 bits/pixel). Doubled bitrate for ALL MOS tiers: MOS>4.0: 1200/1500 Kbps, MOS>3.5: 900/1200 Kbps, MOS>3.0: 600/800 Kbps, MOS>2.0: 400/600 Kbps, MOS<2.0: 300/400 Kbps. Also removed per-MOS encoder profile overrides that broke Chrome compatibility (OMIEndpoint.m)

### Changed

- **VideoToolbox Hardware Codec (H.264 HW acceleration)** - Rebuilt OmiSIP with `PJMEDIA_HAS_VID_TOOLBOX_CODEC=1`. VideoToolbox "H264/98" (PT RSV1) now available alongside OpenH264 "H264/97" in SDP, with priority=230. Reduces encode/decode latency from ~100-280ms (OpenH264 software) to ~10-30ms (VideoToolbox hardware) (OmiSIP framework, config_site.h)
- **Video glass-to-glass latency reduction (~150-400ms improvement)** - (1) Disabled OMISIP video stream rate control (`PJMEDIA_VID_STREAM_RC_NONE`) → frames sent immediately after encode (saves 50-100ms); (2) Reduced audio jitter buffer from 150ms to 60ms (`jb_init=20, jb_min_pre=20, jb_max_pre=40, jb_max=60`) → saves ~90ms A/V sync; (3) VideoToolbox HW codec → saves ~100-250ms codec latency (config_site.h, OMIEndpoint.m)
- **OMISIP max packet length** - Increased `OMISIP_MAX_PKT_LEN` from 4000 to 8000 bytes to accommodate re-INVITE SDP with ICE candidates (config_site.h)
- **Decoder profile standardization** - Always use Level 4.2 (`42002a`) for decoder instead of dynamic Level 3.0/3.1/5.1 which caused various issues (OMIEndpoint.m)
- **Example app video call improvements** - Updated SampleVideoCallViewController with improved video UI handling (SampleVideoCallViewController.m, ViewController.m)

---

## [1.10.24] - 2026-02-10

### Security
- **Disabled sensitive API body logging** in `sendAgentCustomerRequest` (OmiClient.m) and `HttpRequest.m` to prevent credential exposure in logs

### Fixed
- **Critical: NSRangeException crash in lookupAccount** - Fixed thread safety issue where OMISIP thread reads `accounts` array while main thread deallocates via `removeAccount:`. Applied atomic property + NSLock + copy-inside-lock pattern (OMIEndpoint.m)
- **Critical: NSRangeException crash in callWithCallId** - Fixed same thread safety pattern in OMICallManager for `calls` array during concurrent access from OMISIP and main threads (OMICallManager.m)
- **Critical: EXC_BAD_ACCESS crash in getAllCalls** - Fixed use-after-free crash when iterating call list during CANCEL/BYE handling. Method now returns copy instead of direct reference to prevent deallocation race condition (OMICallManager.m)
- **Critical: EXC_BAD_ACCESS in CANCEL/BYE handlers** - Added @try-@catch protection and property copying in logCallBack dispatch blocks to prevent crashes when call objects are deallocated during iteration (OMIEndpoint.m)
- **Critical: pjmedia_codec_mgr_enum_codecs crash** - Fixed race condition when enumerating codecs before OMISIP codec manager fully initialized. Added 300ms delay, retry logic with exponential backoff, and NULL checks (OMIEndpoint.m)
- **Critical: PushKit NSInternalInconsistencyException** - Fixed app termination due to unhandled exceptions in VoIP push handler. Wrapped async SIP/Audio setup in @try-@catch-@finally to prevent PushKit 20s timeout kill (VoIPPushHandler.m)
- **Property update order in OMICall.updateCallInfo** - Reordered property updates to set `callState` LAST, preventing notification observers from receiving stale `lastStatus`/`lastStatusText` values (OMICall.m)
- **OMICall dealloc notification timing** - Fixed strong reference cycles preventing timely deallocation. Enhanced dealloc method to cleanup ALL timers, notification observers, audio players, and ringback objects. Timers and observers hold strong references to self preventing ARC deallocation (OMICall.m:443-490)
- **Double removeCall cleanup pattern** - Removed redundant dispatch_after block in setCallState:Disconnected that caused double cleanup attempts. removeCall is now handled exclusively by OMICallManager.callStateChanged observer, enabling immediate deallocation after call ends (OMICall.m:584-595)
- **audioCheckTimer strong reference cycle** - Fixed missing audioCheckTimer invalidation in setCallState:Disconnected. Timer holds strong reference to self (target:self), creating circular reference that prevented call object deallocation. Now invalidates BOTH startCallCheckTimer and audioCheckTimer (OMICall.m:555-563)
- **Notification capture in dispatch_async blocks** - Fixed Example app ViewController capturing notification object in dispatch_async block. Extract call and callState BEFORE dispatch_async to prevent notification userInfo from holding strong reference to call object, enabling immediate deallocation (ViewController.m:367-373)
- **refreshMiddlewareRegistration validation** - Added proper validation to only call API when user is logged in with Agent/Customer flow. Fixed stale session data causing API errors on app startup (OmiClient.m)
- **UUID validation in refreshMiddlewareRegistration** - Made UUID optional (not required for refresh API) to fix false-positive validation failures
- **Critical: Background crash when declining call before INVITE** - Fixed assertion failure `pjsua_call_answer2` when user declines incoming call (or remote cancels) before SIP INVITE arrives. Added callId validation in `decline:`, `declineWithBusyHere:`, and `dropCall:` methods to handle VoIP push scenario where call object exists but SIP session hasn't started yet (OMICall.m:2275-2400)
- **Critical: pj_thread_this assertion crash in ensureThreadRegistered** - Fixed chicken-and-egg problem where `pj_thread_is_registered()` (a OMISIP API) was called from unregistered thread, causing assertion failure. Now checks custom tracking dictionary FIRST before calling OMISIP API to verify registration status. This prevents crash when remote CANCEL arrives and triggers audio deactivation from main thread (OMIThread.m:118-150)
- **Critical: pj_thread_register EINVAL error (status 120022)** - Fixed error when thread is already registered with OMISIP but not in tracking dictionary (occurs after endpoint destroy/recreate cycle). Status 120022 (EINVAL) is now treated as success and thread is added to tracking. This prevents "Could not create OMISIP thread" errors during endpoint restart (OMIThread.m:173-195)
- **Critical: Group lock assertion crash in onIncomingCall (immediate background crash)** - Fixed crash when incoming VoIP call arrives in background. Root cause: `handle_incoming_sip_message()` called synchronously within `onIncomingCall` callback (holding group lock) contains `dispatch_async` for notification posting (line 4104-4114). This creates race condition with OMISIP group lock owner thread → assertion failure `glock->owner == pj_thread_this()` in `grp_lock_unset_owner_thread`. Crash occurs immediately after UUID extraction, before 100 response is sent. Fixed by: (1) Removing `dispatch_async` from `handle_incoming_sip_message` and posting notification synchronously (fast operation, no async needed); (2) Dispatching answer 180 to main queue OUTSIDE callback context; (3) Wrapping entire `onIncomingCall` in @try-@catch-@finally for graceful exception handling (OMIEndpoint.m:4095-4114, 4310-4618)
- **Critical: pj_thread_this crash in destroyEndpointInstanceWithCompletion** - Fixed crash when destroying endpoint with unregistered thread. Root cause: `pjsua_acc_set_registration(i, PJ_FALSE)` called BEFORE thread registration (line 1132), causing OMISIP logging to crash with "Calling pjlib from unknown/external thread". Thread registration was placed AFTER OMISIP API calls (line 1164). Fixed by moving `[OMIThread ensureThreadRegistered]` BEFORE any OMISIP API calls (OMIEndpoint.m:1125)

### Changed
- **Call end status in state change notification** - Added `lastStatus` (OMINotificationEndCauseKey) and `lastStatusText` to OMICallStateChangedNotification userInfo when callState = Disconnected, so apps can get call end reason immediately without waiting for dealloc (OMICall.m:596-610)
- Added `lastStatusText` to OMICallDeallocNotification userInfo dictionary for better call end status tracking
- Added comprehensive logging for call state changes and dealloc events in ViewController for debugging
- Improved error logging with status code descriptions (Busy, Declined, etc.)
- Example app now logs call end status immediately from OMICallStateChangedNotification (ViewController.m:417-431)

### Documentation
- Created comprehensive crash analysis documentation in `/plans/crash-analysis/`
- Updated MEMORY.md with critical learnings about thread safety, property update order, and dealloc timing

---

## [Legacy Changes]
1. Move all  ``` #import <pjsua.h> ``` from .h files to .m files.

2. Update VSLCall class, hidden functions with ```pjsua_call_info``` structure.

move functions below

```objective-c

- (void)callStateChanged:(pjsua_call_info)callInfo;

- (void)mediaStateChanged:(pjsua_call_info)callInfo;

```

to ``` VSLCall+Private.h ``` file

3. ```VSLEndPoint.h```

change ```pj_pool_t *``` to ```void *```, it will auto cast back in .m files, no need to public it.

4. Move headers into PublicHeader folder. Hide other internal headers.

```cpp
CallKitProviderDelegate.h
Constants.h
OmiClient.h
PjSipVideo.h
PjSipVideoViewManager.h
SipInvite.h
VSLAccount.h
VSLAccountConfiguration.h
VSLAudioCodecs.h
VSLAudioController.h
VSLCall.h
VSLCallManager.h
VSLCallStats.h
VSLCodecConfiguration.h
VSLEndpoint.h
VSLEndpointConfiguration.h
VSLIceConfiguration.h
VSLIpChangeConfiguration.h
VSLLogging.h
VSLNetworkMonitor.h
VSLOpusConfiguration.h
VSLRingback.h
VSLRingtone.h
VSLStunConfiguration.h
VSLTransportConfiguration.h
VSLTurnConfiguration.h
VSLVideoCodecs.h
VialerSIPLib.h
VialerUtils.h
```
