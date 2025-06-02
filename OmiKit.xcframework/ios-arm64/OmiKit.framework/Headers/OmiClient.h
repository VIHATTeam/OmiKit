//
//  OmiClient.h
//  Copyright © 2022 OMICALL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OMISIPLib.h"
#import <AVFoundation/AVFoundation.h>


@class OMICallInfo, OMICallInfoItem;
@interface OmiClient : NSObject

/**
 *  Init user name/password for endpoint, ussually this step need to be init
 * when app open firstime or login
 *  @Param usrUuid This is unique id of user
 *  @Param fullName is user not exits it will create new user with this name
 *  @Param apiKey this key From omicall, help we can authen request from
 * SDK
 */
+ (BOOL)initWithUUID:(NSString *_Nonnull)usrUuid
            fullName:(NSString *_Nullable)fullName
            apiKey:(NSString *_Nonnull)apiKey;

+ (BOOL)initWithUUIDAndPhone:(NSString *_Nonnull)usrUuid
            fullName:(NSString *_Nullable)fullName
            apiKey:(NSString *_Nonnull)apiKey
            phone: (NSString *_Nonnull)phone;

+ (void)initWithUsername:(NSString *_Nonnull)userName
                password:(NSString *_Nonnull)password
                   realm:(NSString *_Nonnull)realm
                   proxy:(NSString *_Nonnull)proxy;

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
 *  Start call with option video call
 */
+ (void)startCall:(NSString *_Nonnull) toNumber isVideo:(BOOL) isVideo result: (void (^)(OMIStartCallStatus status)) completion;
/**
 *  Get phone number from UUID
 */
+ (NSString *)getPhone:(NSString *_Nonnull)toUuid;

+ (id)getAccountInfo:(NSString *_Nonnull)sipAccount;
/**
 *  Start call with Uuid (use for api key)
 */
+ (void)startCallWithUuid:(NSString * _Nonnull) toUuid isVideo: (BOOL) isVideo result: (void (^)(OMIStartCallStatus status)) completion;
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

+ (void)setEnviroment:(NSString *_Nonnull)enviroment userNameKey: (NSString *) userNameKey maxCall: (int) maxCall callKitImage: (NSString*) callKitImage typePushVoip:(NSString *)typePushVoip;

+  (void) setEnviroment:(NSString *) enviroment userNameKey: (NSString *) userNameKey maxCall: (int) maxCall callKitImage: (NSString*) callKitImage typePushVoip: (NSString *)typePushVoip representName: (NSString *)representName;

/**
 * Used to set your projectId of Firebase project for OMI. This is important, because we need to know to properly push incoming calls according to your project Id.
 *
 * Params:
 * - projectId: NSString*
 */
+ (void) setFcmProjectId:(NSString * _Nonnull) projectId;

/**
 *Check and remove voip token on my server.
 */
+ (void) checkVoipToken:(NSString * _Nonnull) voipToken;

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

/**
 * Set the missed block for when a call is missed.
 *
 *  @param missedCallBlock block that will be invoked when a call is completed elsewhere or has been hungup before pickup
 */
+ (void)setMissedCallBlock:(void(^ _Nonnull )(__weak OMICall * _Nonnull call))missedCallBlock;

/**
 * get current user sip
 */
+ (NSString *_Nullable)getCurrentSip;

/**
 * get user sip info
 */
+ (NSString *_Nullable)getSipInfo;


/**
 * get all audios in your device
 */
+ (NSArray<NSDictionary<NSString *, NSString *> *> *_Nonnull) getAudioInDevices;

/**
 * get current audio in device
 */
+ (NSArray<NSDictionary<NSString *, NSString *> *> *_Nonnull) getCurrentAudio;


/**
 * set audio output/input
 */
+ (void)setAudioOutputs:(NSString *_Nonnull)portType;

+ (int)getLogLevel;

+ (void)sendLogRTPCall:(OMICallInfoItem *_Nonnull)_OMICallInfoItem;

+ (void)handleEndpointNotAvailable:(NSString *)toNumber isVideo:(BOOL)isVideo retry:(int)retryTimes isFirstCall:(BOOL)isFirstCall result:(void (^)(OMIStartCallStatus status))completion;

+ (void)handleExistingEndpoint:(NSString *)toNumber isVideo:(BOOL)isVideo retry:(int)retryTimes isFirstCall:(BOOL)isFirstCall result:(void (^)(OMIStartCallStatus status))completion;

/**
 This func will check and auto close all call when user kill app.
 **/
+ (void) OMICloseCall;


// isPartialPhoneNumber lưu trữ giá trị ẩn hay hiện thị số điện thoại ở callkit
+ (void)setIsPartialPhoneNumber:(BOOL)value;

// isPartialPhoneNumber lưu trữ giá trị ẩn hay hiện thị số điện thoại ở callkit
+ (BOOL)isPartialPhoneNumber;

/**
 * Kiểm tra cuộc gọi có được trả lời hay không.
 * @param callId ID của cuộc gọi cần kiểm tra
 * @return YES nếu cuộc gọi đã trả lời, NO nếu cuộc gọi bị hủy hoặc không được trả lời.
 */
+ (BOOL)checkHasAnsweredCall:(NSString * _Nonnull)callId;

@end
