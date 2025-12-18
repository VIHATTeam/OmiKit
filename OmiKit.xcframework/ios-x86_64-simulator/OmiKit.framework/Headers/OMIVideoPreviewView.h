//
//  OMIVideoPreviewView.h
//  OmiKit
//
//  Created by VietHQ on 2022/11/6.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface OMIVideoPreviewView : UIView

/// YES if this is local camera preview, NO if remote video
@property (nonatomic, assign) BOOL isLocalVideo;

/// update preview view from ViewManager
/// - Parameter view: the preview view from VideoViewManager
- (void)setView: (UIView *)view;

- (void)setPlayer:(AVPlayer *)player;

/**
 * Cleanup video resources - call when done with the view
 * Hides PJSIP window and removes subviews to release memory
 */
- (void)cleanup;

/**
 * Show loading indicator overlay
 * Used to indicate waiting for video frames to arrive
 */
- (void)showLoadingIndicator;

/**
 * Hide loading indicator overlay
 * Called when video frames start rendering or video becomes unavailable
 */
- (void)hideLoadingIndicator;

/**
 * Check if video is currently receiving frames
 * Uses RTCP statistics to verify if new RTP packets are arriving
 * @return YES if frames received in last 2 seconds, NO otherwise
 */
- (BOOL)isReceivingFrames;

@end

NS_ASSUME_NONNULL_END
