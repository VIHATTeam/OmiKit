//
//  OMIEndpoint.h
//  Copyright © 2015 OMICALL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OMIEndpointConfiguration.h"

@class DDLogMessage;
@class OMIAccount;
@class OMICall;
@class OMITransportConfiguration;

/**
 *  Possible errors the Endpoint can return.
 */
typedef NS_ENUM(NSInteger, OMIEndpointError) {
    /**
     *  Unable to create the pjsip library.
     */
    OMIEndpointErrorCannotCreatePJSUA,
    /**
     *  Unable to initialize the pjsip library.
     */
    OMIEndpointErrorCannotInitPJSUA,
    /**
     *  Unable to add transport configuration to endpoint.
     */
    OMIEndpointErrorCannotAddTransportConfiguration,
    /**
     *  Unable to start the pjsip library.
     */
    OMIEndpointErrorCannotStartPJSUA,
    /**
     *  Unable to create the thread for pjsip.
     */
    OMIEndpointErrorCannotCreateThread
};
#define OMIEndpointErrorString(OMIEndpointError) [@[@"OMIEndpointErrorCannotCreatePJSUA", @"OMIEndpointErrorCannotInitPJSUA", @"OMIEndpointErrorCannotAddTransportConfiguration", @"OMIEndpointErrorCannotStartPJSUA", @"OMIEndpointErrorCannotCreateThread"] objectAtIndex:OMIEndpointError]

/**
 *  Possible states for the Endpoint.
 */
typedef NS_ENUM(NSInteger, OMIEndpointState) {
    /**
     *  Endpoint not active.
     */
    OMIEndpointStopped,
    /**
     *  Endpoint is starting.
     */
    OMIEndpointStarting,
    /**
     *  Endpoint is running.
     */
    OMIEndpointStarted,
    /**
     *  Endpoint is closing.
     */
    OMIEndpointClosing,
};
#define OMIEndpointStateString(OMIEndpointState) [@[@"OMIEndpointStopped", @"OMIEndpointStarting", @"OMIEndpointStarted"] objectAtIndex:OMIEndpointState]

@interface OMIEndpoint : NSObject

/**
 *  Current state of the endpoint.
 */
@property (nonatomic) OMIEndpointState state;

@property (assign) bool isV6Transport;
@property int udpTransportId;
@property int tcpTransportId;
@property int tlsTransportId;
@property BOOL isSupportVideo;
@property NSDate *_Nullable lastTimeDestroy;
@property NSDate *_Nullable lastTimeIpChange;
@property NSDate *_Nullable lastTimeForeground;
@property int  lastMOS;


/**
 *  The pool associated with the endpoint.
 */
@property (readonly) void * _Nullable pjPool;

@property (readwrite) BOOL ipChangeInProgress;

/**
 *  The incomingCallBlock will be called when an incoming call is received by pjsip.
 */
@property (copy, nonatomic) void (^ _Nonnull incomingCallBlock)(__weak OMICall * _Nullable call);

/**
 * The missedCallBlock will be called when a call is completed elsewhere or the original call hung up.
 */
@property (copy, nonatomic) void(^ _Nonnull missedCallBlock)(__weak OMICall * _Nullable call);

/**
 The logCallBackBlock will be called when there is a log message to be shown.
 */
@property (copy, nonatomic) void( ^ _Nonnull logCallBackBlock)(DDLogMessage * _Nonnull logMessage);

/**
 *  References to the account that have been added to the endpoint.
 *  To add accounts as reference use the addAccount function.
 *  To remove accounts use the removeAccount function.
 */
@property (readonly, nonatomic) NSArray * _Nullable accounts;

/**
 *  The endpoint configuration that has been set in the configure function for the endpoint.
 */
@property (readonly) OMIEndpointConfiguration * _Nonnull endpointConfiguration;


/**
 *  The shared instance for the endpoint.
 *
 *  @return The singleton instance.
 */
+ (instancetype _Nonnull)sharedEndpoint;

/**
 *  This will remove the pjsua configuration.
 */
- (void)destroyEndpointInstance;

/**
 *  Adjust config realtime of Opus
 */
-(void) adjustOpusConfig:(float)mos sampleRate:(int) sampleRate bitRate:(int) bitRate;
-(void) adjustStreamByNetwork:(float)mos sampleRate:(int) sampleRate bitRate:(int) bitRate;

/**
 *  This will configure the endpoint with pjsua.
 *
 *  @param endpointConfiguration Instance of an end point configuration.
 *  @param error                 Pointer to NSError pointer. Will be set to a NSError instance if cannot start endpoint.
 *
 *  @return BOOL success of configuration.
 */
- (BOOL)startEndpointWithEndpointConfiguration:(OMIEndpointConfiguration  * _Nonnull)endpointConfiguration error:(NSError * _Nullable * _Nullable)error;

/**
 *  This will add the account as reference to the endpoint.
 *
 *  @param account The account that has been added.
 */
- (void)addAccount:(OMIAccount * _Nonnull)account;

/**
 *  This will search for the account given the accountId.
 *
 *  @param accountId ID of the account.
 *
 *  @return OMIAccount Instance if found.
 */
- (OMIAccount * _Nullable)lookupAccount:(NSInteger)accountId;

/**
 *  This will remove the account reference in the endpoint.
 *
 *  @param account The account that needs to be removed.
 */
- (void)removeAccount:(OMIAccount * _Nonnull)account;

/**
 *  Returns an account if it is available.
 *
 *  @param sipAccount NSString the sip username you want to check.
 *
 *  @return OMIAccount instance of the account.
 */
- (OMIAccount * _Nullable)getAccountWithSipAccount:(NSString * _Nonnull)sipAccount;

/**
 *  This will update the codec configuration.
 *
 *  @param codecConfiguration OMICodecConfiguration Instance of an OMICodecConfiguration
 */
- (BOOL)updateCodecConfiguration:(OMICodecConfiguration * _Nonnull)codecConfiguration;

-(void) reinviteWithVideoIfCalling;

@end
