//
//  PushKitManager.h
//  OmiKit
//
//  Created by QUOC VIET  on 03/11/2022.
//
//#import <PushKit/PKPushRegistryDelegate.h>
#import <PushKit/PushKit.h>

#ifndef PushKitManager_h
#define PushKitManager_h
@interface PushKitManager : NSObject<PKPushRegistryDelegate>
- (instancetype)initWithVoipRegistry:(PKPushRegistry *)voIPRegistry;


@end

#endif /* PushKitManager_h */
