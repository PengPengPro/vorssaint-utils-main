// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

#ifndef Vorssaint_LaunchAtLoginShim_h
#define Vorssaint_LaunchAtLoginShim_h

#import <Foundation/Foundation.h>

BOOL VorssaintIsLaunchAtLoginEnabled(NSURL *bundleURL);
BOOL VorssaintSetLaunchAtLogin(BOOL enabled, NSURL *bundleURL, NSError **error);

#endif
