#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>


// TODO: Add ability to change device orientation!

typedef enum ObjectFit : NSUInteger {
    contain,
    cover
} ObjectFit;

@interface PjSipVideo : UIView
@property int winId;
@property UIView* winView;
@property ObjectFit winFit;

-(void)setWindowId:(int) windowId;
-(void)setObjectFit:(ObjectFit) objectFit;
@end
