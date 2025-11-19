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

@end

NS_ASSUME_NONNULL_END
