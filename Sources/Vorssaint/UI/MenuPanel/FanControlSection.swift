// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Beta entry point for fan control. It is intentionally informational for now:
/// writing fan curves safely needs model-by-model validation before controls are
/// enabled in a public build.
struct FanControlSection: View {
    @ObservedObject private var l10n = L10n.shared
    @Environment(\.colorScheme) private var colorScheme
    var collapsible = true

    var body: some View {
        PanelSection(.fanControl, title: l10n.s.fanControlBetaSection, collapsible: collapsible) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "fanblades.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(PanelMetricColor.cyan(for: colorScheme))
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text(l10n.s.fanControlBetaTitle)
                                .font(.system(size: 12, weight: .semibold))
                            Text(l10n.s.betaBadge)
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(PanelMetricColor.cyan(for: colorScheme).opacity(0.16)))
                                .foregroundStyle(PanelMetricColor.cyan(for: colorScheme))
                        }
                        Text(l10n.s.fanControlBetaStatus)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Picker("", selection: .constant("automatic")) {
                    Text(l10n.s.fanControlModeAutomatic).tag("automatic")
                    Text(l10n.s.fanControlModeManual).tag("manual")
                }
                .pickerStyle(.segmented)
                .disabled(true)

                Text(l10n.s.fanControlBetaCaption)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .panelCard()
        }
    }
}
