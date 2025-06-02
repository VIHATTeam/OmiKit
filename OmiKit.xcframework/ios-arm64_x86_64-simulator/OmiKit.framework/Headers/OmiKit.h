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

// Core SDK Components
#import "OMIEndpoint.h"
#import "OMIEndpointConfiguration.h"
#import "OmiClient.h"
#import "OMISIPLib.h"

// Account Management
#import "OMIAccount.h"
#import "OMIAccountConfiguration.h"

// Call Management
#import "OMICall.h"
#import "OMICallManager.h"
#import "OMICallInfo.h"
#import "OMICallStats.h"
#import "OMICallMapping.h"
#import "CallIDsManager.h"
#import "SipInvite.h"

// Audio Components
#import "OMIAudioController.h"
#import "OMIAudioCodecs.h"
#import "OMIOpusConfiguration.h"
#import "OMIRingback.h"
#import "OMIRingtone.h"

// Video Components
#import "OMIVideoCallViewController.h"
#import "OMIVideoViewManager.h"
#import "OMIVideoCodecs.h"
#import "OMIVideoPreviewView.h"

// Configuration Classes
#import "OMICodecConfiguration.h"
#import "OMITransportConfiguration.h"
#import "OMIIceConfiguration.h"
#import "OMIStunConfiguration.h"
#import "OMITurnConfiguration.h"
#import "OMIIpChangeConfiguration.h"

// Utilities and Helpers
#import "OMIUtils.h"
#import "OMILogging.h"
#import "OMINetworkMonitor.h"
#import "LogFileManager.h"
#import "Constants.h"

// CallKit and Push Integration
#import "CallKitProviderDelegate.h"
#import "PushKitManager.h"
#import "VoIPPushHandler.h"

// Category Extensions (from SIPCore)
#import "NSError+OMIError.h"
#import "NSString+PJString.h" 