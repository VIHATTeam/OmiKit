//
//  OMIUtils.h
//  Copyright © 2016 OMICALL. All rights reserved.
//

#import <Foundation/Foundation.h>


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

@end

@interface HttpRequest : NSObject

- (NSData* _Nonnull )httpRequestWithURL:(NSURL * _Nonnull)url httpMethod:(NSString * _Nullable)httpMethod body:(NSData *_Nullable)body contentType:(NSString * _Nullable)contentType error:(NSError *_Nullable* _Nullable)error;
- (NSData* _Nonnull )httpRequestWithURLAuthen:(NSURL * _Nonnull)url httpMethod:(NSString * _Nullable)httpMethod body:(NSData *_Nullable)body contentType:(NSString * _Nullable)contentType error:(NSError *_Nullable* _Nullable)error;
- (NSData* _Nonnull )httpRequestWithDefaultAuthen:(NSURL * _Nonnull)url httpMethod:(NSString * _Nullable)httpMethod body:(NSData *_Nullable)body contentType:(NSString * _Nullable)contentType error:(NSError *_Nullable* _Nullable)error;
@end
