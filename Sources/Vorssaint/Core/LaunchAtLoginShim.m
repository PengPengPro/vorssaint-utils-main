// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

#import "LaunchAtLoginShim.h"
#import <CoreServices/CoreServices.h>

static BOOL VorssaintLoginItemMatchesURL(LSSharedFileListItemRef item, NSURL *bundleURL) {
    CFURLRef resolved = NULL;
    if (LSSharedFileListItemResolve(item, 0, &resolved, NULL) != noErr || resolved == NULL) {
        return NO;
    }
    BOOL matches = CFEqual(resolved, (__bridge CFURLRef)bundleURL)
        || [[(__bridge NSURL *)resolved path] isEqualToString:bundleURL.path];
    CFRelease(resolved);
    return matches;
}

BOOL VorssaintIsLaunchAtLoginEnabled(NSURL *bundleURL) {
    LSSharedFileListRef list = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (!list) {
        return NO;
    }

    UInt32 seed = 0;
    CFArrayRef snapshot = LSSharedFileListCopySnapshot(list, &seed);
    if (!snapshot) {
        CFRelease(list);
        return NO;
    }

    BOOL found = NO;
    CFIndex count = CFArrayGetCount(snapshot);
    for (CFIndex i = 0; i < count; i++) {
        LSSharedFileListItemRef item = (LSSharedFileListItemRef)CFArrayGetValueAtIndex(snapshot, i);
        if (VorssaintLoginItemMatchesURL(item, bundleURL)) {
            found = YES;
            break;
        }
    }

    CFRelease(snapshot);
    CFRelease(list);
    return found;
}

BOOL VorssaintSetLaunchAtLogin(BOOL enabled, NSURL *bundleURL, NSError **error) {
    LSSharedFileListRef list = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (!list) {
        if (error) {
            *error = [NSError errorWithDomain:@"VorssaintLaunchAtLogin"
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Login items are unavailable."}];
        }
        return NO;
    }

    BOOL ok = YES;
    if (enabled) {
        if (!VorssaintIsLaunchAtLoginEnabled(bundleURL)) {
            LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(
                list,
                kLSSharedFileListItemBeforeFirst,
                NULL,
                NULL,
                (__bridge CFURLRef)bundleURL,
                NULL,
                NULL
            );
            if (!item) {
                ok = NO;
                if (error) {
                    *error = [NSError errorWithDomain:@"VorssaintLaunchAtLogin"
                                                 code:2
                                             userInfo:@{NSLocalizedDescriptionKey: @"Could not update the login item."}];
                }
            }
        }
    } else {
        UInt32 seed = 0;
        CFArrayRef snapshot = LSSharedFileListCopySnapshot(list, &seed);
        if (!snapshot) {
            ok = NO;
            if (error) {
                *error = [NSError errorWithDomain:@"VorssaintLaunchAtLogin"
                                             code:2
                                         userInfo:@{NSLocalizedDescriptionKey: @"Could not update the login item."}];
            }
        } else {
            CFIndex count = CFArrayGetCount(snapshot);
            for (CFIndex i = 0; i < count; i++) {
                LSSharedFileListItemRef item = (LSSharedFileListItemRef)CFArrayGetValueAtIndex(snapshot, i);
                if (VorssaintLoginItemMatchesURL(item, bundleURL)) {
                    LSSharedFileListItemRemove(list, item);
                    break;
                }
            }
            CFRelease(snapshot);
        }
    }

    CFRelease(list);
    return ok;
}
