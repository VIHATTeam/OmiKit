//
//  Constants.h
//  Copyright © 2016 OMICALL. All rights reserved.
//

#import <Foundation/Foundation.h>

extern int const ddLogLevel;

#pragma PUSH
static NSString * KEY_OMI_VOIP_TOKEN = @"omicall/voipToken";
static NSString * KEY_OMI_DEVICE_TOKEN = @"omicall/device_token";
static NSString * KEY_OMI_MAX_CALL = @"omicall/max_call";
static NSString * KEY_OMI_RECEIVE_APNS_TOKEN = @"KEY_OMI_RECEIVE_APNS_TOKEN";
static NSString * KEY_OMI_APP_ENVIROMENT = @"KEY_OMI_APP_ENVIROMENT";

#pragma APP

static NSString * KEY_OMI_APP_ENVIROMENT_PRODUCTION = @"1";
static NSString * KEY_OMI_APP_ENVIROMENT_SANDBOX = @"2";
static NSString * KEY_OMI_APP_DEVICE_TYPE_IOS = @"2";
static NSString * KEY_OMI_APP_DEVICE_TYPE_ANDROID = @"1";
static NSString * KEY_OMI_APP_USE_NOISE_SUPPRESSION = @"KEY_OMI_APP_USE_NOISE_SUPPRESSION";

#pragma NOTI
static NSString * KEY_OMI_USER_NAME_KEY = @"omicall/userNameKey";

