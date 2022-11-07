//
//  OmiClient.h
//  Copyright © 2022 OMICALL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OMISIPLib.h"

@interface OmiClient : NSObject

/**
 *  Init client after that we can make call
 *   @param userName it's Sip User ( not omicall user )
 *   @param password  it's Sip password
 *   @param realm its Sip domain
 *    we can get those params at web admin *omicrm.io/config/switchboard/internal-number/list
 *
 */

+ (void) initWithUsername:(NSString * _Nonnull) userName password:(NSString * _Nonnull) password realm:(NSString * _Nonnull) realm ;
/**
 *  Make call to a number.
 *   @param toNumber number callee, will be phone number or extension number
 */
+ (void)startCall:(NSString * _Nonnull) toNumber ;

/**
 *  Setup the SIP endpoint with the OMISIPLib.
 *
 *  @return BOOL
 */
+ (BOOL)startOmiService;

/**
 *  Remove the SIP endpoint.
 */
+ (void)removeSIPEndpoint;
/**
 *  Remove all call , if call is calling it's will be cancel.
 */
+ (void) removeAllCall;
/**
 *  Remove call by uuid.
 */
+ (void) removeCallByUUid:(NSUUID * _Nonnull) uuid;
/**
 *  Remove all call except call have uuid same with params uuid
 *   @param uuid : uuid of call need to keep
 */
+ (void) removeCallExceptCall:(NSUUID * _Nonnull) uuid;

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
@end
