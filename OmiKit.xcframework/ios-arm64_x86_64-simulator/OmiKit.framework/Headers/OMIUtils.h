//
//  OMIUtils.h
//  Copyright © 2016 OMICALL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CallKit/CallKit.h>

@interface OMIUtils : NSObject

/**
 *  This will configure the basic Endpoint to use with pjsip.
 *
 *  @param endpointConfiguration Instance of an endpoint configuration.
 *  @param error                 Pointer to NSError pointer. Will be set to a NSError instance if it can't configure the library.
 *
 *  @return success of configuration.
 */

/**
 *  This will clean the input phone number from characters that cannot be used when setting up a call.
 *
 *  @param phoneNumber Phone number that needs to be cleaned.
 *
 *  @return the cleaned phone number.
 */
+ (NSString *_Nullable)cleanPhoneNumber:(NSString *_Nonnull)phoneNumber;

+ (NSString*) getOmiID;
+ (int)getAvailableBandwidth ;
+ (BOOL)isPhoneNumber:(NSString *)name;
+ (NSString *)formatPhoneNumber:(NSString *)name;
+ (void)saveProxy:(NSString *)proxy;
+ (NSString *)getProxy;
+ (BOOL)lookupSipHeaders:(NSString *) textFind textPosition:(NSString *) textPosition sipMessage:(NSString *) sipMessage;
+ (void)delayActionAfterTime:(NSInteger ) numberSecond completion:(void (^)(void))completion;
/*
 Find the method: INVITED, REGISTER from the sip string
 */
+ (NSString *)getMethodFromSIPMessage:(NSString *)sipMessage;
/*
 Find the UUID from Sip Message
 */
+ (NSString *)findAndCutUUIDFromSipMessages:(NSString *)sipMessage;


/*
 Find and cut sip number from message
 */
+ (NSString *)findAndCutSipNumberFromSipMessages:(NSString *)sipMessage;

/*
 Find IP and cut ip from proxy
 */
+(NSString *)extractIPAddress:(NSString * _Nonnull)inputString;


/*
 Find phone number and hide with *
 */
+ (NSString *)maskedPhoneNumberOrName:(NSString *)inputString;

/*
 Update UI CallKit
 */
+ (CXCallUpdate *)prepareCallUpdateWithVideo:(BOOL)isVideo
                                  callNumber:(NSString *)callNumber
                                  remoteName:(NSString *)remoteName ;

/*
 Check if IPv6 is available on cellular network
 */
+ (BOOL)isIPv6Available;

/*
 Check if IP address is APIPA (169.254.x.x)
 */
+ (BOOL)isAPIPA_Address:(NSString *)ipAddress;

/*
 Get valid local IP address (not APIPA)
 */
+ (NSString *)getValidLocalIPAddress;

extern NSString *const SDK_VERSION;

@end

@interface HttpRequest : NSObject

- (NSData* _Nonnull )httpRequestWithURL:(NSURL * _Nonnull)url httpMethod:(NSString * _Nullable)httpMethod body:(NSData *_Nullable)body contentType:(NSString * _Nullable)contentType error:(NSError *_Nullable* _Nullable)error;
- (NSData* _Nonnull )httpRequestWithURLAuthen:(NSURL * _Nonnull)url httpMethod:(NSString * _Nullable)httpMethod body:(NSData *_Nullable)body contentType:(NSString * _Nullable)contentType error:(NSError *_Nullable* _Nullable)error;
- (NSData* _Nonnull )httpRequestWithDefaultAuthen:(NSURL * _Nonnull)url httpMethod:(NSString * _Nullable)httpMethod body:(NSData *_Nullable)body contentType:(NSString * _Nullable)contentType error:(NSError *_Nullable* _Nullable)error;
- (NSString* _Nullable )httpRequestWithURLFast:(NSURL * _Nonnull)url httpMethod:(NSString * _Nullable)httpMethod body:(NSData *_Nullable)body contentType:(NSString * _Nullable)contentType error:(NSError *_Nullable* _Nullable)error;
@end
