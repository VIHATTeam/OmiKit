#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

// Core OmiKit Headers
#import "OmiKit.h"
#import "OmiClient.h"

// Account & Configuration
#import "OMIAccount.h"
#import "OMIAccountConfiguration.h"
#import "OMIEndpoint.h"
#import "OMIEndpointConfiguration.h"

// Call Management
#import "OMICall.h"
#import "OMICallInfo.h"
#import "OMICallManager.h"
#import "OMICallStats.h"
#import "CallKitProviderDelegate.h"

// Audio & Video
#import "OMIAudioCodecs.h"
#import "OMIAudioController.h"
#import "OMIVideoCodecs.h"
#import "OMIVideoCallViewController.h"
#import "OMIVideoPreviewView.h"
#import "OMIVideoViewManager.h"

// Codec Configuration
#import "OMICodecConfiguration.h"
#import "OMIOpusConfiguration.h"

// Network & Transport
#import "OMITransportConfiguration.h"
#import "OMIIceConfiguration.h"
#import "OMIStunConfiguration.h"
#import "OMITurnConfiguration.h"
#import "OMIIpChangeConfiguration.h"
#import "OMINetworkMonitor.h"

// Push & VoIP
#import "PushKitManager.h"
#import "VoIPPushHandler.h"

// Utilities (Safe ones only)
#import "OMIUtils.h"
#import "OMILogging.h"
#import "OMIRingback.h"
#import "OMIRingtone.h"
#import "Constants.h"

// Error Handling (Safe)
#import "NSError+OMIError.h"

// SIP (Core functionality)
#import "OMISIPLib.h"
#import "SipInvite.h"

// Internal Management
#import "CallIDsManager.h"
#import "LogFileManager.h"
#import "OMICallMapping.h"

FOUNDATION_EXPORT double OmiKitVersionNumber;
FOUNDATION_EXPORT const unsigned char OmiKitVersionString[]; 