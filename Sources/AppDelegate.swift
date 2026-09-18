// AppDelegate.swift
// Sip – macOS Menu Bar hydration reminder

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    // ------------------------------------------------------------------
    // MARK: - Core objects
    // ------------------------------------------------------------------

    /// Central state / business-logic manager (created first).
    private(set) var hydrationManager: HydrationManager = .shared

    /// Owns the NSStatusItem that lives in the system menu bar.
    private var menuBarController: MenuBarController?

    /// Owns the transparent NSPanel anchored to the notch.
    private(set) var notchWindowController: NotchWindowController?

    // ------------------------------------------------------------------
    // MARK: - NSApplicationDelegate
    // ------------------------------------------------------------------

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Prevent a dock icon – belt-and-suspenders complement to Info.plist.
        NSApp.setActivationPolicy(.accessory)

        // 2. Build the notch window (before the menu bar so it's ready to show).
        let nwc = NotchWindowController()
        notchWindowController = nwc
        nwc.updatePosition()

        // 3. Build the menu-bar status item.
        let mbc = MenuBarController(
            hydrationManager: hydrationManager
        )
        menuBarController = mbc

        // 4. Start the hydration reminder timer.
        hydrationManager.startTimer()

        // 5. Listen for screen-layout changes (resolution switch, external display, etc.)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        hydrationManager.stopTimer()
    }

    // ------------------------------------------------------------------
    // MARK: - Screen parameter changes
    // ------------------------------------------------------------------

    @objc private func screenParametersDidChange(_ notification: Notification) {
        // Give the OS a moment to finish resizing before we recompute.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.notchWindowController?.updatePosition()
        }
    }
}

