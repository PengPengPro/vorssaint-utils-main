// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// How tightly the menu bar metric blocks pack together. The standard reserve
/// keeps every number rock-steady by sizing blocks for their largest possible
/// value, which reads as wide gaps on short values (user feedback); compact
/// hugs the current number instead.
enum MenuBarMetricSpacing: String, CaseIterable {
    case standard, compact

    static var current: MenuBarMetricSpacing {
        let raw = UserDefaults.standard.string(forKey: DefaultsKey.menuBarMetricSpacing) ?? ""
        return MenuBarMetricSpacing(rawValue: Defaults.sanitizedMenuBarMetricSpacing(raw)) ?? .standard
    }
}

enum MenuBarSpacingSupport {
    /// Idle CPU/GPU readings live right at the one-to-two digit boundary
    /// (4% one tick, 10% the next); reserving the bare current digit count
    /// made the whole bar wobble on every crossing. Two digits cover 0-99
    /// without ever moving.
    static let compactMinimumDigits = 2

    /// Highest digit count each block has shown this session, so a spike to
    /// three digits widens that block once and keeps it there instead of
    /// letting the width oscillate while the value hovers at the boundary.
    /// Touched only on the main thread (status item refresh and the settings
    /// preview both render there).
    private static var digitHighWater: [String: Int] = [:]

    /// The reserve compact mode uses for a metric block: the current value's
    /// shape, widened to at least `compactMinimumDigits` digits and to the
    /// block's session high-water mark. Stable by construction; still far
    /// narrower than reserving each metric's absolute maximum.
    static func compactReserve(label: String, value: String) -> String {
        let digits = value.filter(\.isNumber).count
        let floor = compactFloor(currentDigits: digits, highWater: digitHighWater[label])
        digitHighWater[label] = floor
        return digitMatchedReserve(for: value, minimumDigits: floor)
    }

    static func compactFloor(currentDigits: Int, highWater: Int?) -> Int {
        max(currentDigits, compactMinimumDigits, highWater ?? 0)
    }

    /// A same-width stand-in for the value ("14%" gives "88%"), padded with
    /// extra digits in front of the first number until `minimumDigits` is
    /// met ("4%" with a minimum of 2 gives "88%"). Values without digits are
    /// returned shape-for-shape.
    static func digitMatchedReserve(for value: String, minimumDigits: Int = 0) -> String {
        var out = ""
        var digitCount = value.filter(\.isNumber).count
        var padded = false
        for character in value {
            if character.isNumber, !padded {
                while digitCount < minimumDigits {
                    out.append("8")
                    digitCount += 1
                }
                padded = true
            }
            out.append(character.isNumber ? "8" : character)
        }
        return out
    }

    /// The glue string drawn between two metric blocks.
    static func blockGlue(readableStyle: Bool, spacing: MenuBarMetricSpacing) -> String {
        switch spacing {
        case .standard: return readableStyle ? "  " : " "
        case .compact: return readableStyle ? " " : "\u{200A}"
        }
    }

    /// Whether the app glyph may hide so the menu bar shows metrics only
    /// (user request). Every gate protects the same invariant: the status
    /// item must never end up with no image and no text, and hiding must
    /// never swallow a signal the user opted into.
    /// - `metricsEnabled` keeps a countdown-only title from hiding the glyph.
    /// - `renderedTitleLength` covers the launch gap where metrics are on
    ///   but the first sample has not landed yet (empty title).
    /// - `separateMetrics` keeps the glyph when metrics live in their own
    ///   status items and the main one would otherwise be empty.
    /// - `mustShowForSignal` brings the glyph back while it carries a signal
    ///   (update available, mic muted indicator).
    static func shouldHideStatusIcon(optionEnabled: Bool,
                                     separateMetrics: Bool,
                                     metricsEnabled: Bool,
                                     renderedTitleLength: Int,
                                     mustShowForSignal: Bool) -> Bool {
        optionEnabled
            && !separateMetrics
            && metricsEnabled
            && renderedTitleLength > 0
            && !mustShowForSignal
    }

    /// Whether the whole main status item may hide in the separate-items
    /// mode, where each metric is its own clickable item and the main one
    /// carries only the glyph. It may only vanish while at least one metric
    /// item is actually installed (the panel stays reachable through them),
    /// its own title is empty (an active countdown renders there and must
    /// not disappear), and no signal needs the glyph back.
    static func shouldHideMainStatusItem(optionEnabled: Bool,
                                         separateMetrics: Bool,
                                         metricItemsShown: Int,
                                         renderedTitleLength: Int,
                                         mustShowForSignal: Bool) -> Bool {
        optionEnabled
            && separateMetrics
            && metricItemsShown > 0
            && renderedTitleLength == 0
            && !mustShowForSignal
    }
}
