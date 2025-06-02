//
//  OmiKit.h
//  OmiKit iOS SDK
//
//  Copyright © 2024 OMICALL. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for OmiKit.
FOUNDATION_EXPORT double OmiKitVersionNumber;

//! Project version string for OmiKit.
FOUNDATION_EXPORT const unsigned char OmiKitVersionString[];

// Category Extensions (from SIPCore)
#import "NSError+OMIError.h"

#import "CallKitProviderDelegate.h"
#import "Constants.h"
#import "OMIAccount.h"
#import "OMIAccountConfiguration.h"
#import "OMIAudioCodecs.h"
#import "OMIAudioController.h"
#import "OMICall.h"
#import "OMICallManager.h"
#import "OMICallInfo.h"
#import "OMICallStats.h"
#import "OmiClient.h"
#import "OMICodecConfiguration.h"
#import "OMIEndpoint.h"
#import "OMIEndpointConfiguration.h"
#import "OMIIceConfiguration.h"
#import "OMIIpChangeConfiguration.h"
#import "OMILogging.h"
#import "OMINetworkMonitor.h"
#import "OMIOpusConfiguration.h"
#import "OMIRingback.h"
#import "OMIRingtone.h"
#import "OMISIPLib.h"
#import "OmiClient.h"
#import "OMIStunConfiguration.h"
#import "OMITransportConfiguration.h"
#import "OMITurnConfiguration.h"
#import "OMIVideoCodecs.h"
#import "PushKitManager.h"
#import "SipInvite.h"
#import "VoIPPushHandler.h"
#import "OMIVideoCallViewController.h"
#import "OMIVideoPreviewView.h"
#import "OMIVideoViewManager.h"
#import "OMIUtils.h"
#import "LogFileManager.h"
