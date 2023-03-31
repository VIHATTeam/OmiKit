//
//  OMIVideoCallViewController.h
//  OmiKit
//
//  Created by VietHQ on 2022/11/14.
//

#import <UIKit/UIKit.h>
#import <OmiKit/OmiKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OMIVideoCallViewController : UIViewController
-(id)initWithCall:( __weak OMICall *)call;

@end

NS_ASSUME_NONNULL_END
