//
//  OMIVideoCallManager.h
//  OmiKit
//
//  Singleton manager that automatically handles video call lifecycle.
//  App only needs to provide container views - SDK handles the rest.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OMIVideoCallManager;

/**
 * Delegate protocol for video call events.
 * All methods are optional - SDK handles video automatically.
 * Use this for UI updates only (show/hide loading, update buttons, etc.)
 */
@protocol OMIVideoCallManagerDelegate <NSObject>
@optional

/// Called when video is ready and displaying (both local and remote)
- (void)videoCallManagerDidStartVideo:(OMIVideoCallManager *)manager;

/// Called when video call ended
- (void)videoCallManagerDidEndCall:(OMIVideoCallManager *)manager;

/// Called when remote video becomes available
- (void)videoCallManagerDidReceiveRemoteVideo:(OMIVideoCallManager *)manager;

/// Called when there's an error with video
- (void)videoCallManager:(OMIVideoCallManager *)manager didFailWithError:(NSError *)error;

@end


/**
 * OMIVideoCallManager - Automatic video call management
 *
 * USAGE (SIMPLE):
 *
 *   // 1. In your video call view controller's viewDidLoad:
 *   [[OMIVideoCallManager shared] setupWithRemoteView:self.remoteContainerView
 *                                           localView:self.localContainerView];
 *
 *   // 2. That's it! SDK handles everything automatically:
 *       - Detecting when call is confirmed
 *       - Setting up video streams
 *       - Handling background/foreground transitions
 *       - Recreating views when needed
 *       - Cleanup when call ends
 *
 *   // 3. Optional: Set delegate for UI updates
 *   [OMIVideoCallManager shared].delegate = self;
 *
 *   // 4. In your dealloc or when leaving video call:
 *   [[OMIVideoCallManager shared] cleanup];
 *
 *
 * CONTROLS:
 *   [[OMIVideoCallManager shared] switchCamera];     // Switch front/back
 *   [[OMIVideoCallManager shared] toggleCamera];     // On/off camera
 *   [OMIVideoCallManager shared].isCameraOn;         // Check camera state
 */
@interface OMIVideoCallManager : NSObject

/// Shared singleton instance
+ (instancetype)shared;

/// Delegate for optional UI callbacks
@property (nonatomic, weak, nullable) id<OMIVideoCallManagerDelegate> delegate;

/// Whether camera is currently on
@property (nonatomic, readonly) BOOL isCameraOn;

/// Whether video is currently active
@property (nonatomic, readonly) BOOL isVideoActive;

/// Check if remote video is currently receiving frames
/// Use this to check if video is actually working before triggering re-INVITE
/// @return YES if frames received in last 2 seconds, NO otherwise
- (BOOL)checkIsVideoReceivingFrames;

#pragma mark - Setup (REQUIRED)

/**
 * Setup video with container views.
 * Call this once in your video call view controller's viewDidLoad.
 * SDK will automatically handle all video lifecycle events.
 *
 * @param remoteView Container view for remote video (typically full screen)
 * @param localView Container view for local camera preview (typically small PiP)
 */
- (void)setupWithRemoteView:(UIView *)remoteView localView:(UIView *)localView;

#pragma mark - Controls

/// Switch between front and back camera
- (void)switchCamera;

/// Toggle camera on/off
- (void)toggleCamera;

/// Force refresh video views (useful after orientation change)
- (void)refreshVideoViews;

#pragma mark - Cleanup (REQUIRED)

/**
 * Cleanup video resources.
 * Call this when:
 * - Leaving video call screen
 * - Call ends
 * - In your view controller's dealloc
 */
- (void)cleanup;

@end

NS_ASSUME_NONNULL_END
