// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation
import ServiceManagement

enum LaunchAtLogin {
    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return VorssaintIsLaunchAtLoginEnabled(Bundle.main.bundleURL)
    }

    static func setEnabled(_ enabled: Bool) throws {
        if #available(macOS 13.0, *) {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return
        }
        var error: NSError?
        guard VorssaintSetLaunchAtLogin(enabled, Bundle.main.bundleURL, &error) else {
            throw error ?? LaunchAtLoginError.failed
        }
    }

    static func unregisterIfNeeded() {
        guard isEnabled else { return }
        try? setEnabled(false)
    }
}

private enum LaunchAtLoginError: LocalizedError {
    case failed

    var errorDescription: String? {
        "Could not update the login item."
    }
}
