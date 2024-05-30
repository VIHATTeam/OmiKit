//
//  CallIDsManager.h
//  OmiKit
//
//  Created by H-Solutions on 28/02/2024.
//

//#ifndef CallIDsManager_h
//#define CallIDsManager_h
//
//
//#endif /* CallIDsManager_h */


/**
THIS CLASS USE FOR MANAGE CALL ID PUSH VOIP
**/

#import <Foundation/Foundation.h>


@interface CallIDsManager : NSObject

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *callIDsArray;

+ (instancetype)sharedInstance;

- (void)addCallIDWithGenerate:(NSString *)callIdGenerate origin:(NSString *)callIdOrigin;
- (NSDictionary *)getCallIDAtIndex:(NSUInteger)index;
// Trong CallIDsManager.h thêm khai báo của hàm
- (NSUUID *)findAndGenCallIDGenerate:(NSUUID *)callUUID;

- (NSUUID *)getCallIDGenerate:(NSUUID *)callUUID;

- (NSUUID *)getCallIDOrigin:(NSUUID *)callUUID;

- (NSUUID *)genCallIDGenerate:(NSUUID *)callUUID;

- (void)removeCallIDOrigin:(NSUUID *)callUUID;

- (void)removeCallIDGenerate:(NSUUID *)callUUID;

- (void)removeCallID:(NSUUID *)callUUID;

- (BOOL)findCallIDOrigin:(NSUUID *)callUUID;

@end
       

