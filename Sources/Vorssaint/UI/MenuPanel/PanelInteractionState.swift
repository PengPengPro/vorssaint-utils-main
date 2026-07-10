// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Combine
import Foundation

/// Shared hints from panel content to the AppKit popover host.
final class PanelInteractionState: ObservableObject {
    static let shared = PanelInteractionState()

    @Published var keepsPopoverOpen = false

    private init() {}
}
