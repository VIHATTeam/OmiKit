//
//  OMIAudioController.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * __nonnull const OMIAudioControllerAudioInterrupted;
extern NSString * __nonnull const OMIAudioControllerAudioResumed;

/**
 *  Possible outputs the audio can have.
 */
typedef NS_ENUM(NSInteger, OMIAudioControllerOutputs) {
    /**
     *  Audio is sent over the speaker
     */
    OMIAudioControllerOutputSpeaker,
    /**
     *  Audio is sent to the ear speaker or mini jack
     */
    OMIAudioControllerOutputOther,
    /**
     *  Audio is sent to bluetooth
     */
    OMIAudioControllerOutputBluetooth,
};
#define OMIAudioControllerOutputsString(OMIAudioControllerOutputs) [@[@"OMIAudioControllerOutputSpeaker", @"OMIAudioControllerOutputOther", @"OMIAudioControllerOutputBluetooth"] objectAtIndex:OMIAudioControllerOutputs]


@interface OMIAudioController : NSObject

/**
 *  If there is a Bluetooth headset connected, this will return YES.
 */
@property (readonly, nonatomic) BOOL hasBluetooth;

/**
 *  The current routing of the audio.
 *
 *  Attention: Possible values that can be set: OMIAudioControllerSpeaker & OMIAudioControllerOther.
 *  Setting the property to OMIAudioControllerBluetooth won't work, if you want to activatie bluetooth
 *  you have to change the route with the mediaplayer (see example app).
 */
@property (nonatomic) OMIAudioControllerOutputs output;

/**
 *  Configure audio.
 */
- (void)configureAudioSession;

/**
 *  Activate the audio session.
 */
- (void)activateAudioSession;

/**
 *  Deactivate the audio session.
 */
- (void)deactivateAudioSession;

@end
