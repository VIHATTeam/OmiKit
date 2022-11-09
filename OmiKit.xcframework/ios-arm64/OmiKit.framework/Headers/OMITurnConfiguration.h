//
//  OMITurnConfiguration.h
//  OMISIPLib
//
//  Created by Maciek Gierszewski on 25/10/2017.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, OMIStunPasswordType) {
    OMIStunPasswordTypePlain = 0,
    OMIStunPasswordTypeHashed = 1,
};

@interface OMITurnConfiguration : NSObject
@property (nonatomic, assign) BOOL enableTurn;
@property (nonatomic, assign) OMIStunPasswordType passwordType;

@property (nonatomic, strong) NSString * _Nullable server;
@property (nonatomic, strong) NSString * _Nullable username;
@property (nonatomic, strong) NSString * _Nullable password;
@end
