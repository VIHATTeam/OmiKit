//
//  OmiClient.h
//  Copyright © 2022 OMICALL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OMISIPLib.h"

@interface OmiClient : NSObject

/**
 *  Get current active call.
 *
 *  @return current confirm call
 */
@property OMICall * currentCall;

/**
 *  state using noise cancel.
 *
 */
@property OMICall * isUsingNoiseCancel;

/**
 *  state using noise cancel.
 *
 */
+ (void)setNoiseSuppression:(BOOL) isUseNoiseSuppression;

+ (BOOL)setupSIPEndpoint;
+ (void) initWithUsername:(NSString *) userName password:(NSString *) password realm:(NSString *) realm ;
+ (BOOL)startOmiService:(BOOL) isVideo  ;
+ (void)startCall:(NSString * _Nonnull) toNumber;
+ (void)startVideoCall:(NSString * _Nonnull) toNumber;

/**
 *  Remove the SIP endpoint.
 */
+ (void)removeSIPEndpoint;
+ (void) removeAllCall;
+ (void) removeCallByUUid:(NSUUID * _Nonnull) uuid;
+ (void) removeCallExcepCall:(NSUUID * _Nonnull) uuid;

/*
 * Remove the SIP endpoint if there are no active calls.
 */
+ (BOOL)safelyRemoveSipEndpoint;

+ (BOOL)isSafeToRemoveSipEndpoint;

/**
 *  Only update the codecs on the SIP endpoint.
 */
+ (BOOL)updateCodecs;

/**
 *  Add the sipAccount of the current OmiSipUser to the endpoint.
 *
 *  @return BOOL YES if the adding of the account was a success.
 */
+ (OMIAccount * _Nullable)addSIPAccountToEndpoint;

/**
 *  Register the sip account with the endpoint.
 *
 *  @return BOOL YES if the registration was a success.
 */
+ (void)registerSIPAccountWithEndpointWithCompletion:(void (^_Nonnull)(BOOL success, OMIAccount *_Nullable account))completion;

/**
 *  Get a OMICall instance based on a callId.
 *
 *  @param callId NSString with the callId that needs the be found.
 *
 *  @return OMICall instance or nil.
 */
+ (OMICall * _Nullable)getCallWithId:(NSString *_Nonnull)callId __attribute__((unavailable("Deprecated, use OMICallManager -callWithCallId: instead")));

/**
 *  Check if there is another call in progress.
 *
 *  @param receivedCall OMICall instance of the call that is incoming.
 *
 *  @return BOOL YES if there is another call in progress.
 */
+ (BOOL)anotherCallInProgress:(OMICall * _Nonnull)receivedCall;

/**
 *  Get the first active call.
 *
 *  @return A OMICall instance or nil.
 */
+ (OMICall * _Nullable)getFirstActiveCall;

/**
 *  The codec configuration that is going to be used.
 *
 *  @return a OMICodecConfiguration instance.
 */
+ (OMICodecConfiguration * _Nonnull)codecConfiguration;
+ (void) setEnviroment:(NSString *_Nonnull) enviroment;
+ (void) registerAccount;

+ (void) refreshMiddlewareRegistration ;
+ (void) setUserPushNotificationToken:(NSString * ) token ;



@end
