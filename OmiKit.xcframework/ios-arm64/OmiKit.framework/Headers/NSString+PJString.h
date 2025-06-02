//
//  NSString+PJString.h
//  Copyright © 2015 OMICALL. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <pjsua.h>
#import "OMIAccount.h"

@interface NSString (PJString)

/**
 *  This returns a string for the pjsip library.
 */
@property (readonly) pj_str_t pjString;

/**
 *  This will return a string which can be read by human eyes.
 *
 *  @param pjString pjString struct
 *
 *  @return NSString
 */
+ (NSString *)stringWithPJString:(pj_str_t)pjString;

/**
 *  This will prepend "sip:" in front of the string.
 *
 *  @return NSString
 */
- (NSString *)prependSipUri;

/**
 *  This will create a sip uri with added domain info if necessary.
 *
 *  @param domain a NSString with domain info.
 *
 */
- (pj_str_t)sipUriWithDomain:(NSString *)domain;

+(NSString *) toString: (pj_str_t *) str;
+(BOOL) isEmptyString : (NSString *) str;

+(NSString *) callStateToString: (pjsip_inv_state) state;
+(NSString *) callStatusToString: (pjsip_status_code) status;
+(NSString *) mediaDirToString: (pjmedia_dir) dir;
+(NSString *) mediaStatusToString: (pjsua_call_media_status) status;
+(NSString *) mediaTypeToString: (pjmedia_type) type;

+(void) fillCallSettings: (pjsua_call_setting*) callSettings dict:(NSDictionary*) dict;
+(void) fillMsgData: (pjsua_msg_data*) msgData dict:(NSDictionary*) dict pool:(pj_pool_t*) pool;

@end
