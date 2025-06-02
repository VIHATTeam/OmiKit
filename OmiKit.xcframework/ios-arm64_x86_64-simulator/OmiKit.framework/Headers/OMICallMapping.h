//
//  OMICallMapping.h
//  OmiKit
//
//  Created by H-Solutions on 13/06/2024.
//

#ifndef OMICallMapping_h
#define OMICallMapping_h


#endif /* OMICallMapping_h */

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "NSError+OMIError.h"
#import "NSString+PJString.h"
#import "OMILogging.h"
#import "OMISIPLib.h"

@interface OMICallMapping : NSObject
@property (nonatomic, strong) NSMutableDictionary<NSUUID *, NSNumber *> *callMapping;
+ (instancetype)sharedInstance;
- (void)addCallWithUUID:(NSUUID *)uuid callID:(pjsua_call_id)callID;
- (pjsua_call_id)getCallIDForUUID:(NSUUID *)uuid;
- (void)removeCallWithUUID:(NSUUID *)uuid;
@end
