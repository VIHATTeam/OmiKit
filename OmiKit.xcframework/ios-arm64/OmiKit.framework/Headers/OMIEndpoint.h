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

typedef NS_ENUM(NSUInteger, OMIEndCause) {
    
    OMI_SC_NULL = 0,
    OMI_SC_TRYING = 100,
    OMI_SC_RINGING = 180,
    OMI_SC_CALL_BEING_FORWARDED = 181,
    OMI_SC_QUEUED = 182,
    OMI_SC_PROGRESS = 183,
    OMI_SC_EARLY_DIALOG_TERMINATED = 199,

    OMI_SC_OK = 200,
    OMI_SC_ACCEPTED = 202,
    OMI_SC_NO_NOTIFICATION = 204,

    OMI_SC_MULTIPLE_CHOICES = 300,
    OMI_SC_MOVED_PERMANENTLY = 301,
    OMI_SC_MOVED_TEMPORARILY = 302,
    OMI_SC_USE_PROXY = 305,
    OMI_SC_ALTERNATIVE_SERVICE = 380,

    OMI_SC_BAD_REQUEST = 400,
    OMI_SC_UNAUTHORIZED = 401,
    OMI_SC_PAYMENT_REQUIRED = 402,
    OMI_SC_FORBIDDEN = 403,
    OMI_SC_NOT_FOUND = 404,
    OMI_SC_METHOD_NOT_ALLOWED = 405,
    OMI_SC_NOT_ACCEPTABLE = 406,
    OMI_SC_PROXY_AUTHENTICATION_REQUIRED = 407,
    OMI_SC_REQUEST_TIMEOUT = 408,
    OMI_SC_CONFLICT = 409,
    OMI_SC_GONE = 410,
    OMI_SC_LENGTH_REQUIRED = 411,
    OMI_SC_CONDITIONAL_REQUEST_FAILED = 412,
    OMI_SC_REQUEST_ENTITY_TOO_LARGE = 413,
    OMI_SC_REQUEST_URI_TOO_LONG = 414,
    OMI_SC_UNSUPPORTED_MEDIA_TYPE = 415,
    OMI_SC_UNSUPPORTED_URI_SCHEME = 416,
    OMI_SC_UNKNOWN_RESOURCE_PRIORITY = 417,
    OMI_SC_BAD_EXTENSION = 420,
    OMI_SC_EXTENSION_REQUIRED = 421,
    OMI_SC_SESSION_TIMER_TOO_SMALL = 422,
    OMI_SC_INTERVAL_TOO_BRIEF = 423,
    OMI_SC_BAD_LOCATION_INFORMATION = 424,
    OMI_SC_USE_IDENTITY_HEADER = 428,
    OMI_SC_PROVIDE_REFERRER_HEADER = 429,
    OMI_SC_FLOW_FAILED = 430,
    OMI_SC_ANONIMITY_DISALLOWED = 433,
    OMI_SC_BAD_IDENTITY_INFO = 436,
    OMI_SC_UNSUPPORTED_CERTIFICATE = 437,
    OMI_SC_INVALID_IDENTITY_HEADER = 438,
    OMI_SC_FIRST_HOP_LACKS_OUTBOUND_SUPPORT = 439,
    OMI_SC_MAX_BREADTH_EXCEEDED = 440,
    OMI_SC_BAD_INFO_PACKAGE = 469,
    OMI_SC_CONSENT_NEEDED = 470,
    OMI_SC_TEMPORARILY_UNAVAILABLE = 480,
    OMI_SC_CALL_TSX_DOES_NOT_EXIST = 481,
    OMI_SC_LOOP_DETECTED = 482,
    OMI_SC_TOO_MANY_HOPS = 483,
    OMI_SC_ADDRESS_INCOMPLETE = 484,
    OMI_AC_AMBIGUOUS = 485,
    OMI_SC_BUSY_HERE = 486,
    OMI_SC_REQUEST_TERMINATED = 487,
    OMI_SC_NOT_ACCEPTABLE_HERE = 488,
    OMI_SC_BAD_EVENT = 489,
    OMI_SC_REQUEST_UPDATED = 490,
    OMI_SC_REQUEST_PENDING = 491,
    OMI_SC_UNDECIPHERABLE = 493,
    OMI_SC_SECURITY_AGREEMENT_NEEDED = 494,

    OMI_SC_INTERNAL_SERVER_ERROR = 500,
    OMI_SC_NOT_IMPLEMENTED = 501,
    OMI_SC_BAD_GATEWAY = 502,
    OMI_SC_SERVICE_UNAVAILABLE = 503,
    OMI_SC_SERVER_TIMEOUT = 504,
    OMI_SC_VERSION_NOT_SUPPORTED = 505,
    OMI_SC_MESSAGE_TOO_LARGE = 513,
    OMI_SC_PUSH_NOTIFICATION_SERVICE_NOT_SUPPORTED = 555,
    OMI_SC_PRECONDITION_FAILURE = 580,

    OMI_SC_BUSY_EVERYWHERE = 600,
    OMI_SC_DECLINE = 603,
    OMI_SC_DOES_NOT_EXIST_ANYWHERE = 604,
    OMI_SC_NOT_ACCEPTABLE_ANYWHERE = 606,
    OMI_SC_UNWANTED = 607,
    OMI_SC_REJECTED = 608,

    OMI_SC_TSX_TIMEOUT = OMI_SC_REQUEST_TIMEOUT,
    OMI_SC_TSX_TRANSPORT_ERROR = OMI_SC_SERVICE_UNAVAILABLE,
    OMI_SC_TSX_TRANSPORT_ERROR_SC__force_32bit = 0x7FFFFFFF
};

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
