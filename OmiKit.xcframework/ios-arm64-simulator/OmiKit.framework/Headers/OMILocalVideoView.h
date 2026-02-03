//
//  OMILocalVideoView.h
//  OmiKit
//
//  Local video preview view - simplified for PiP display
//  Separate from OMIVideoPreviewView to avoid complex scaling logic conflicts
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * OMILocalVideoView - Dedicated view for local camera preview (PiP style)
 *
 * Features:
 * - Simple aspect FIT scaling (shows full face without cropping)
 * - Horizontal mirror for selfie view (like front camera)
 * - Automatic PJSIP window management
 * - Optimized for small PiP containers
 *
 * Usage:
 *   OMILocalVideoView *localView = [[OMILocalVideoView alloc] init];
 *   [localView setVideoView:pjsipView];
 */
@interface OMILocalVideoView : UIView

/**
 * Set the PJSIP video view from createViewForVideoLocal
 * @param view The UIView from PJSIP containing Metal rendering layer
 */
- (void)setVideoView:(UIView *)view;

/**
 * Mirror the video horizontally (default: YES for front camera selfie view)
 */
@property (nonatomic, assign) BOOL mirrorHorizontally;

/**
 * Use aspect FIT instead of FILL (default: YES - shows full face)
 */
@property (nonatomic, assign) BOOL useAspectFit;

/**
 * Check if video view has been set (readonly)
 * Use to avoid re-creating local video if already showing
 */
@property (nonatomic, readonly) BOOL hasVideoView;

/**
 * Cleanup video resources - call when done with the view
 * Hides PJSIP window and removes subviews to release memory
 */
- (void)cleanup;

@end

NS_ASSUME_NONNULL_END
