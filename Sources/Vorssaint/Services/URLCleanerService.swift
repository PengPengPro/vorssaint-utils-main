// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Combine
import UniformTypeIdentifiers

final class URLCleanerService: ObservableObject {
    static let shared = URLCleanerService()
    private static let automaticRewriteTypes: Set<NSPasteboard.PasteboardType> = [
        .string,
        NSPasteboard.PasteboardType(UTType.url.identifier),
        NSPasteboard.PasteboardType("public.url-name"),
        NSPasteboard.PasteboardType("NSStringPboardType"),
        NSPasteboard.PasteboardType("NSURLPboardType"),
    ]

    @Published private(set) var isRunning = false
    @Published private(set) var lastCleaned: String?

    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount

    private init() {}

    func syncWithPreferences() {
        if UserDefaults.standard.bool(forKey: DefaultsKey.urlCleanerEnabled) {
            start()
        } else {
            stop()
        }
    }

    func clean(_ text: String) -> String? {
        URLCleaning.cleanedString(from: text)
    }

    func copy(_ urlString: String) {
        writeToPasteboard(urlString)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func start() {
        guard timer == nil else {
            isRunning = true
            return
        }
        lastChangeCount = NSPasteboard.general.changeCount
        let timer = Timer(timeInterval: 0.8, repeats: true) { [weak self] _ in
            self?.cleanClipboardIfNeeded()
        }
        timer.tolerance = 0.25
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        isRunning = true
    }

    private func cleanClipboardIfNeeded() {
        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount
        guard changeCount != lastChangeCount else { return }
        lastChangeCount = changeCount

        guard let text = pasteboard.string(forType: .string),
              let cleaned = URLCleaning.cleanedString(from: text),
              cleaned != text.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }
        guard canSafelyRewriteAutomatically(pasteboard) else { return }

        writeToPasteboard(cleaned)
    }

    private func canSafelyRewriteAutomatically(_ pasteboard: NSPasteboard) -> Bool {
        guard let types = pasteboard.types, !types.isEmpty else { return false }
        let typeSet = Set(types)
        return typeSet.isSubset(of: Self.automaticRewriteTypes)
    }

    private func writeToPasteboard(_ urlString: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(urlString, forType: .string)
        pasteboard.setString(urlString, forType: NSPasteboard.PasteboardType(UTType.url.identifier))
        lastChangeCount = pasteboard.changeCount
        lastCleaned = urlString
    }
}
