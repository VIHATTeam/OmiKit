//
//  OMIVideoPreviewView.h
//  OmiKit
//
//  Created by VietHQ on 2022/11/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OMIVideoPreviewView : UIView

/// update preview view from ViewManager
/// - Parameter view: the preview view from VideoViewManager
- (void)setView: (UIView *)view;

@end

NS_ASSUME_NONNULL_END
