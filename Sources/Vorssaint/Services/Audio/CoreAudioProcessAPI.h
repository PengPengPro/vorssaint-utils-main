// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

#ifndef Vorssaint_CoreAudioProcessAPI_h
#define Vorssaint_CoreAudioProcessAPI_h

#import <CoreAudio/CoreAudio.h>
#import <Foundation/Foundation.h>

// CoreAudio process/tap APIs shipped in macOS 14.2+ / 14.4+. Older SDKs omit
// the declarations; current SDKs already provide them.
#if __MAC_OS_X_VERSION_MAX_ALLOWED < 140200

static const AudioObjectPropertySelector kAudioHardwarePropertyProcessObjectList = 0x70727323; // 'prs#'
static const AudioObjectPropertySelector kAudioProcessPropertyPID = 0x70706964;                 // 'ppid'
static const AudioObjectPropertySelector kAudioProcessPropertyIsRunningOutput = 0x7069726f;      // 'piro'

typedef NS_ENUM(NSInteger, CATapMuteBehavior) {
    CATapUnmuted = 0,
    CATapMuted = 1,
    CATapMutedWhenTapped = 2,
};

@interface CATapDescription : NSObject
- (instancetype)initStereoMixdownOfProcesses:(NSArray<NSNumber *> *)processObjectIDs;
@property(nonatomic) CATapMuteBehavior muteBehavior;
@property(nonatomic, getter=isPrivate) BOOL private;
@property(nonatomic, readonly) NSUUID *UUID;
@end

OSStatus AudioHardwareCreateProcessTap(CATapDescription *inDescription, AudioObjectID *outTapID);
OSStatus AudioHardwareDestroyProcessTap(AudioObjectID inTapID);

#endif

extern CFStringRef const kVorssaintAudioAggregateDeviceTapListKey;
extern CFStringRef const kVorssaintAudioAggregateDeviceTapAutoStartKey;
extern CFStringRef const kVorssaintAudioSubTapUIDKey;
extern CFStringRef const kVorssaintAudioSubTapDriftCompensationKey;

#endif
