// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

extension Notification.Name {
    /// Posted when the menu panel's computed height changes so AppKit can resize
    /// the popover on macOS 12, where sizingOptions is unavailable.
    static let menuPanelContentSizeChanged = Notification.Name("VorssaintMenuPanelContentSizeChanged")
}

/// Menu-bar popover host: on macOS 12, SwiftUI's fittingSize overshoots the
/// panel frame, so the popover window ends up taller than the content (gray
/// dead space below). Sizes come from MenuPanelView's explicit frame instead.
final class MenuPanelHostingController: NSHostingController<MenuPanelView> {
    static let legacyInitialMenuPanelSize = CGSize(width: 332, height: 620)

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(macOS 13.0, *) {
            sizingOptions = .preferredContentSize
        }
    }

    func applyExplicitContentSize(_ size: CGSize) {
        if #available(macOS 13.0, *) { return }
        guard size.width > 1, size.height > 1 else { return }
        if abs(preferredContentSize.width - size.width) > 0.5
            || abs(preferredContentSize.height - size.height) > 0.5 {
            preferredContentSize = size
            view.setFrameSize(size)
            view.needsLayout = true
            view.layoutSubtreeIfNeeded()
        }
    }
}

/// NSHostingController that keeps preferredContentSize in sync with SwiftUI on
/// macOS 12, where sizingOptions is unavailable.
final class SizingHostingController<Content: View>: NSHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()
        applyPreferredContentSizing()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        syncPreferredContentSizeIfNeeded()
    }
}

extension NSHostingController {
    func applyPreferredContentSizing() {
        if #available(macOS 13.0, *) {
            sizingOptions = .preferredContentSize
        } else {
            syncPreferredContentSizeIfNeeded()
        }
    }

    func syncPreferredContentSizeIfNeeded() {
        if #available(macOS 13.0, *) { return }
        view.layoutSubtreeIfNeeded()
        let size = view.fittingSize
        guard size.width > 1, size.height > 1 else { return }
        if abs(preferredContentSize.width - size.width) > 0.5
            || abs(preferredContentSize.height - size.height) > 0.5 {
            preferredContentSize = size
        }
    }
}

extension View {
    @ViewBuilder
    func groupedFormStyle() -> some View {
        if #available(macOS 13.0, *) {
            formStyle(.grouped)
        } else {
            self
        }
    }

    @ViewBuilder
    func numericTextTransition() -> some View {
        if #available(macOS 14.0, *) {
            contentTransition(.numericText())
        } else {
            self
        }
    }
}

extension Text {
    func sectionTitleTracking() -> Text {
        if #available(macOS 13.0, *) {
            return kerning(0.5)
        }
        return tracking(0.5)
    }
}

extension View {
    @ViewBuilder
    func tertiaryForegroundStyle() -> some View {
        if #available(macOS 13.0, *) {
            foregroundStyle(.tertiary)
        } else {
            foregroundColor(Color(nsColor: .tertiaryLabelColor))
        }
    }

    @ViewBuilder
    func enabledTextSelection() -> some View {
        if #available(macOS 13.0, *) {
            textSelection(.enabled)
        } else {
            self
        }
    }

    @ViewBuilder
    func lineLimitCompat(_ limit: Int, reservesSpace: Bool = false) -> some View {
        if #available(macOS 13.0, *), reservesSpace {
            lineLimit(limit, reservesSpace: true)
        } else {
            lineLimit(limit)
        }
    }

    @ViewBuilder
    func letterSpacingCompat(_ spacing: CGFloat) -> some View {
        if #available(macOS 13.0, *) {
            tracking(spacing)
        } else {
            self
        }
    }

    @ViewBuilder
    func scrollDisabledCompat(_ disabled: Bool) -> some View {
        if #available(macOS 13.0, *) {
            scrollDisabled(disabled)
        } else {
            self
        }
    }

    /// Accepts dragged `.app` bundles (and other file URLs as a fallback).
    func appBundleDropDestination(
        isTargeted: Binding<Bool>,
        onDrop: @escaping ([URL]) -> Bool
    ) -> some View {
        modifier(AppBundleDropDestinationModifier(isTargeted: isTargeted, onDrop: onDrop))
    }
}

private struct AppBundleDropDestinationModifier: ViewModifier {
    @Binding var isTargeted: Bool
    let onDrop: ([URL]) -> Bool

    func body(content: Content) -> some View {
        if #available(macOS 13.0, *) {
            content.dropDestination(for: URL.self) { urls, _ in
                onDrop(urls)
            } isTargeted: { isTargeted = $0 }
        } else {
            content.onDrop(of: ["public.file-url"], isTargeted: $isTargeted) { providers in
                for provider in providers {
                    _ = provider.loadObject(ofClass: URL.self) { object, _ in
                        guard let url = object as? URL else { return }
                        DispatchQueue.main.async {
                            _ = onDrop([url])
                        }
                    }
                }
                return !providers.isEmpty
            }
        }
    }
}
