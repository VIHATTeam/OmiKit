//
//  OMIVideoViewManager.h
//  Pods
//
//  Created by VietHQ on 2022/11/5.
//

#ifndef OMIVideoViewManager_h
#define OMIVideoViewManager_h

#import <UIKit/UIKit.h>
#import <OmiKit/OMIVideoPreviewView.h>

@interface OMIVideoViewManager : NSObject

@property (nonatomic, assign, readonly) BOOL isCameraOn;

/// Turn on/off camera.
- (void)toggleCamera;

- (void)stopPreview;


/// Switch front/back camera.
- (void)switchCamera;

/// got current active call's local camera preview view from PJSIP apis
- (void)localView: (void(^)(UIView *view))handler;

/// got current active call's remote camera preview view from PJSIP apis
- (void)remoteView: (void(^)(UIView *view))handler;
/**
 *  create view for local camera capture & stream to another leg
*/
- (UIView *)createViewForVideoLocal:(CGRect)frame;
/**
 * create view for remote stream
*/
- (UIView *)createViewForVideoRemote:(CGRect)frame;

@end


#endif /* OMIVideoViewManager_h */
