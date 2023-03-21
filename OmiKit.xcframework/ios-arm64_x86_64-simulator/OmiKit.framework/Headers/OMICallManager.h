//
//  OMICallManager.h
//  Copyright © 2016 OMICALL. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "OMIAudioController.h"
#import "CallKitProviderDelegate.h"

@class OMICall;
@class OMIAccount;

/**
 *  The OMICallManager class is the single point of entry for everything you want to do with a call.
 *  - start an outbound call
 *  - end a call
 *  - mute or hold a call
 *  - sent DTMF signals
 *
 *  It takes care the CallKit (if available) and PJSIP interactions.
 */
@interface OMICallManager : NSObject

/**
 *  Controler responsible for managing the audio streams for the calls.
 */
@property (readonly) OMIAudioController * _Nonnull audioController;
@property (nonatomic) CallKitProviderDelegate * _Nonnull callKitProvider;

/**
 *  Start a call to the given number for the given account.
 *
 *  @param number The number to call.
 *  @param account The account to use for the call
 *  @param completion A completion block which is always invoked. Either the call is started successfully and you can obtain an
 *  OMICall instance throught the block or, when the call fails, you can query the blocks error parameter.
 */
- (void)startCallToNumber:(NSString * _Nonnull)number forAccount:(OMIAccount * _Nonnull)account completion:(void (^_Nonnull )(OMICall * _Nullable call, NSError * _Nullable error))completion;

- (void)startCallToNumberNoReg:(NSString * _Nonnull)number forAccount:(OMIAccount * _Nonnull)account completion:(void (^_Nonnull )(OMICall * _Nullable call, NSError * _Nullable error))completion;


/**
 *  Answers the given inbound call.
 *
 *  #param completion A completion block giving access to an NSError when unable to answer the given call.
 */
- (void)answerCall:(OMICall * _Nonnull)call completion:(void (^ _Nonnull)(NSError * _Nullable error))completion;

/**
 *  End the given call.
 *
 *  @param call The OMICall instance to end.
 *  @param completion A completion block giving access to an NSError when the given call could not be ended.
 */
- (void)endCall:(OMICall * _Nonnull)call completion:(void (^ _Nullable)(NSError * _Nullable error))completion;

/**
 *  Toggle mute of the microphone for this call.
 *
 *  @param completion A completion block giving access to an NSError when mute cannot be toggle for the given call.
 */
- (void)toggleMuteForCall:(OMICall * _Nonnull)call completion:(void (^ _Nonnull)(NSError * _Nullable error))completion;

/**
 *  Toggle hold of the call.
 *
 *  @param completion A completion block giving access to an NSError when the given call cannot be put on hold.
 */
- (void)toggleHoldForCall:(OMICall * _Nonnull)call completion:(void (^ _Nonnull)(NSError * _Nullable error))completion;

/**
 *  Send DTMF tone for this call with a character.
 *
 *  @param character character NSString the character for the DTMF.
 *  @param completion A completion block giving access to an NSError when sending DTMF fails.
 */
- (void)sendDTMFForCall:(OMICall * _Nonnull)call character:(NSString * _Nonnull)character completion:(void (^ _Nonnull)(NSError * _Nullable error))completion;

/**
 *  Find a call with the given UUID.
 *
 *  @param uuid The UUID of the call to find.
 *
 *  @return A OMICall instance if a call was found for the given UUID, otherwise nil.
 */
- (OMICall * _Nullable)callWithUUID:(NSUUID * _Nonnull)uuid;

/**
 *  Find a call for the given call ID.
 *
 *  @param callId The PJSIP generated call ID given to an incoming call.
 *
 *  @return A OMICall instance if a call with the given call ID was found, otherwise nil.
 */
- (OMICall * _Nullable)callWithCallId:(NSInteger)callId;


/**
 *  remove a call for the given call ID.
 *
 *  @param callId The PJSIP generated call ID given to an incoming call.
 *
 *  @return A OMICall instance if a call with the given call ID was found, otherwise nil.
 */
- (BOOL) removeCallByUUID:(NSString *)uuid;
- (BOOL) removeCallExcepCall:(NSString *)uuid;

/**
 *  Returns all the calls for a given account.
 *
 * @param account The OMIAccount for which to find it's calls.
 *
 * @return An NSArray containing all the accounts calls or nil.
 */
- (NSArray * _Nullable)callsForAccount:(OMIAccount * _Nonnull)account;

/**
 *  Add the given call to the Call Manager.
 *
 *  @param call The OMICall instance to add.
 */
- (void)addCall:(OMICall * _Nonnull)call;

/**
 *  Remove the given call from the Call Manager.
 *
 *  @param call the OMICall instance to remove.
 */
- (void)removeCall:(OMICall * _Nonnull)call;

- (void)removeAllCall;

/**
 *  End active calling call
 */
- (void)endActiveCall;

/**
 * OmiID is unique id of call in 2 leg A & B
 */
- (void)setOmiID:(NSString * _Nonnull ) omiId callID:(NSInteger) callId;


/**
 *  End all calls.
 *  Notice this function just use to hangup SIP Call not End Callkit
 */
- (void)endAllCalls;


- (NSMutableArray *)getAllCalls;

/**
 *  End all calls.
 */

/**
 *  End all calls for the given account.
 *
 *  @param account The OMIAccount instance for which to end all calls.
 */
- (void)endAllCallsForAccount:(OMIAccount * _Nonnull)account;

/**
 *  Returns the first call for the given account
 *
 *  @param account The OMIAccount instance for which to return the first call.
 *
 *  @return The first call for the given account, otherwise nil.
 */
- (OMICall * _Nullable)firstCallForAccount:(OMIAccount * _Nonnull)account;

/**
 *  Returns the first ACTIVE call for the given account.
 *
 *  @param account The OMIAccount instance for which to return the first active call.
 *
 *  @return The first active call for the given account, otherwise nil.
 */
- (OMICall * _Nullable)firstActiveCallForAccount:(OMIAccount * _Nonnull)account;

/**
 *  Returns the last call for the given account
 *
 *  @param account The OMIAccount instance for which to return the last call.
 *
 *  @return The last call for the given account, otherwise nil.
 */
- (OMICall * _Nullable)lastCallForAccount:(OMIAccount * _Nonnull)account;

/**
 *  Returns the current confirm call
 * *
 */
- (OMICall * _Nullable)getCurrentConfirmCall;

    
/**
 *  Reinvite all active calls for the given account.
 *
 *  @param account The OMIAccount instance for which to reinvite all calls.
 */
- (void)reinviteActiveCallsForAccount:(OMIAccount * _Nonnull)account;

/**
 *  Sent a SIP UPDATE message to all active calls for the given account.
 *
 *  @param account The OMIAccount instance for which to sent the UPDATE.
 */
- (void)updateActiveCallsForAccount:(OMIAccount * _Nonnull)account;
@end
