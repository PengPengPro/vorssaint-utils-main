// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit

extension NSScreen {
    /// The screen under the mouse pointer — where summoned panels (switcher,
    /// shelf, cut HUD) belong. Falls back to the main screen. A Mac running a
    /// menu bar app always has at least one screen.
    static var withMouse: NSScreen {
        let mouse = NSEvent.mouseLocation
        return screens.first { $0.frame.contains(mouse) } ?? main ?? screens[0]
    }
}
