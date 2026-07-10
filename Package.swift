// swift-tools-version:5.7
// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import PackageDescription

let package = Package(
    name: "Vorssaint",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "Vorssaint",
            path: "Sources/Vorssaint"
        )
    ]
)
