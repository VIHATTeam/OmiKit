//
//  OmiClient.h
//  Copyright © 2022 OMICALL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OMISIPLib.h"

@interface OmiClient : NSObject

/**
 *  Init user name/password for endpoint, ussually this step need to be init
 * when app open firstime or login
 *  @Param uuid: This is unique id of user
 *  @Param fullName: is user not exits it will create new user with this name
 *  @Param apiKey: this key get From omicall, help we can authen request from
 * SDK
 */
+ (BOOL)initWithUUID:(NSString *_Nonnull)usrUuid
            fullName:(NSString *_Nullable)fullName
              apiKey:(NSString *_Nonnull)apiKey;

+ (void)initWithUsername:(NSString *_Nonnull)userName
                password:(NSString *_Nonnull)password
                   realm:(NSString *_Nonnull)realm;

/**
 *  call this function when user logout to prevent notification came to this
 * device without login
 *
 */
+ (void)logout;

/**
 *  Start Service OMI - in Most case User ussually dont call this function
 */
+ (BOOL)startOmiService:(BOOL)isVideo;
/**
 *  Start call if call is normal Call
 */
+ (BOOL)startCall:(NSString *_Nonnull)toNumber;
/**
 *  Start call with option video call
 */
+ (BOOL)startCall:(NSString *_Nonnull)toNumber isVideo:(BOOL)isVideo;
/**
 *  Get phone number from UUID
 */
+ (NSString *)getPhone:(NSString *_Nonnull)toUuid;
/**
 *  Start call with Uuid (use for api key)
 */
+ (BOOL)startCallWithUuid:(NSString *_Nonnull)toNumber isVideo:(BOOL)isVideo;

/**
 *  Start call if call is Video Call
 */
+ (BOOL)startVideoCall:(NSString *_Nonnull)toNumber;
/**
 *  Answer by function call, dont neet user interactive with callkit
 */
+ (void)answerIncommingCall:(NSUUID *)uuid;

/**
 *  Remove one call by UUID
 */
+ (void)removeCallByUUid:(NSUUID *_Nonnull)uuid;
/**
 *  Remove all call exept this call
 */
+ (void)removeCallExcepCall:(NSUUID *_Nonnull)uuid;

/**
 *  Register the sip account with the endpoint.
 *
 *  @return BOOL YES if the registration was a success.
 */
+ (void)registerSIPAccountWithEndpointWithCompletion:
    (void (^_Nonnull)(BOOL success, OMIAccount *_Nullable account))completion;

/**
 *  Get a OMICall instance based on a callId.
 *
 *  @param callId NSString with the callId that needs the be found.
 *
 *  @return OMICall instance or nil.
 */
+ (__weak OMICall *_Nullable)getCallWithId:(NSString *_Nonnull)callId
    __attribute__((unavailable(
        "Deprecated, use OMICallManager -callWithCallId: instead")));

/**
 *  Check if there is another call in progress.
 *
 *  @param receivedCall OMICall instance of the call that is incoming.
 *
 *  @return BOOL YES if there is another call in progress.
 */
+ (BOOL)anotherCallInProgress:(__weak OMICall *_Nonnull)receivedCall;

/**
 *  Get the first active call.
 *
 *  @return A OMICall instance or nil.
 */
+ (__weak OMICall *_Nullable)getCurrentConfirmCall;

/**
 *  The codec configuration that is going to be used.
 *
 *  @return a OMICodecConfiguration instance.
 */
+ (OMICodecConfiguration *_Nonnull)codecConfiguration;

/**
 *Set Enviroment for product
 *PRODUCTION = 1;
 *SANDBOX = 2;
 */

+ (void)setEnviroment:(NSString *_Nonnull)enviroment;

/**
 *Use to set APNS Normal push notification by application
 *This push notification will use to make SDK able to push cancel call, chat,
 *another infomation
 */
+ (void)setUserPushNotificationToken:(NSString *)token;
/**
 *Use this function to set love level 0 - 5
 *  1 - OMILogVerbose
 *  2 - OMILogDebug
 *  3 - OMILogInfo
 *  4 - OMILogWarning
 *  5 - OMILogError

 */
+ (void)setLogLevel:(int)level;

/**
 *Use to change information of Call in Callkit like CallerName, Caller Number
 * @Param: call: object call need to update
 */
+ (void)reportIncomingCall:(OMICall *_Nonnull)call;

/**
 *Use to set output sound for call
 * @Param: output: Outut need to request
 */
+ (void)setOutput:(NSString *_Nonnull)output;
/**
 *Use to get list of output sound devices
 * @Param:
 * @return: list String name of output device
 */
+ (NSMutableArray<NSString *> *)getListOutputDevices;

/**
 *  state using noise cancel. Notice that user will slow down or add latency
 * with noise cancel
 *
 */
+ (void)setNoiseSuppression:(BOOL)isUseNoiseSuppression;

@end
