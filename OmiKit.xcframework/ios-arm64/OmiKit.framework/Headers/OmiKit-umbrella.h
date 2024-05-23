//
//  OmiKit-umbrella.h
//  OmiKit
//
//  Created by H-Solutions on 23/02/2024.
//

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

#import <OmiKit/CallKitProviderDelegate.h>
#import <OmiKit/Constants.h>
#import <OmiKit/OMIAccount.h>
#import <OmiKit/OMIAccountConfiguration.h>
#import <OmiKit/OMIAudioCodecs.h>
#import <OmiKit/OMIAudioController.h>
#import <OmiKit/OMICall.h>
#import <OmiKit/OMICallManager.h>
#import <OmiKit/OMICallStats.h>
#import <OmiKit/OmiClient.h>
#import <OmiKit/OMICodecConfiguration.h>
#import <OmiKit/OMIEndpoint.h>
#import <OmiKit/OMIEndpointConfiguration.h>
#import <OmiKit/OMIIceConfiguration.h>
#import <OmiKit/OMIIpChangeConfiguration.h>
#import <OmiKit/OMILogging.h>
#import <OmiKit/OMINetworkMonitor.h>
#import <OmiKit/OMIOpusConfiguration.h>
#import <OmiKit/OMIRingback.h>
#import <OmiKit/OMIRingtone.h>
#import <OmiKit/OMISIPLib.h>
#import <OmiKit/OMIStunConfiguration.h>
#import <OmiKit/OMITransportConfiguration.h>
#import <OmiKit/OMITurnConfiguration.h>
#import <OmiKit/OMIUtils.h>
#import <OmiKit/OMIVideoCallViewController.h>
#import <OmiKit/OMIVideoCodecs.h>
#import <OmiKit/OMIVideoPreviewView.h>
#import <OmiKit/OMIVideoViewManager.h>
#import <OmiKit/PushKitManager.h>
#import <OmiKit/SipInvite.h>
#import <OmiKit/VoIPPushHandler.h>

FOUNDATION_EXPORT double OmiKitVersionNumber;
FOUNDATION_EXPORT const unsigned char OmiKitVersionString[];
