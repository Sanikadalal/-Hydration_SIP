// NotchWindowController.swift
// Sip – macOS Menu Bar hydration reminder
//
// Manages a transparent, borderless NSPanel that sits just above the
// built-in display's notch cutout and hosts the SwiftUI mascot view.

import AppKit
import SwiftUI

// ---------------------------------------------------------------------------
// MARK: - NotchWindowController
// ---------------------------------------------------------------------------

final class NotchWindowController: NSWindowController {

    // ------------------------------------------------------------------
    // Constants
    // ------------------------------------------------------------------

    /// Initial (collapsed) panel dimensions in points.
    private let initialWidth:  CGFloat = 320
    private let initialHeight: CGFloat = 220

    // ------------------------------------------------------------------
    // MARK: - Init
    // ------------------------------------------------------------------

    init() {
        let panel = NotchWindowController.makePanel()
        super.init(window: panel)

        // Embed the SwiftUI content view.
        let hostingView = NSHostingView(rootView: NotchContentView())
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init()") }

    // ------------------------------------------------------------------
    // MARK: - Panel factory
    // ------------------------------------------------------------------

    private static func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )

        // Transparency / shadow.
        panel.backgroundColor = .clear
        panel.isOpaque        = false
        panel.hasShadow       = false

        // Sit just above the status-window level so it floats over most content.
        panel.level = NSWindow.Level(
            rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1
        )

        // Visible on all spaces / full-screen apps.
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Clicks pass through to windows below when the panel itself is not
        // interacting with the user (avoids stealing focus unintentionally).
        panel.ignoresMouseEvents = false
        panel.acceptsMouseMovedEvents = true

        // Don't appear in the Window menu or Mission Control thumbnail strip.
        panel.isExcludedFromWindowsMenu = true

        return panel
    }

    // ------------------------------------------------------------------
    // MARK: - Positioning
    // ------------------------------------------------------------------

    /// Repositions the panel so it is horizontally centred on the primary
    /// screen directly below the notch cutout.
    func updatePosition() {
        guard let screen = NSScreen.main else { return }

        // `safeAreaInsets.top` equals the notch height on notch Macs,
        // and 0 on machines without a notch.
        let notchHeight: CGFloat = screen.safeAreaInsets.top
        let screenFrame          = screen.frame

        // The notch sits at the top-centre of the screen.
        // We position the panel so its top edge aligns with the top of the
        // screen (i.e. the notch base), centred horizontally.
        let panelX = screenFrame.midX - initialWidth / 2
        let panelY = screenFrame.maxY - max(notchHeight, 38) - initialHeight

        let origin = CGPoint(x: panelX, y: panelY)
        let size   = CGSize(width: initialWidth, height: initialHeight)

        window?.setFrame(CGRect(origin: origin, size: size), display: true)
    }

    /// Adjusts the panel height to `newHeight` while keeping it centred.
    func resize(toHeight newHeight: CGFloat) {
        guard let screen = NSScreen.main,
              let panel  = window else { return }

        let notchHeight = screen.safeAreaInsets.top
        let screenFrame = screen.frame

        let panelX = screenFrame.midX - initialWidth / 2
        let panelY = screenFrame.maxY - max(notchHeight, 38) - newHeight

        let newFrame = CGRect(x: panelX, y: panelY,
                              width: initialWidth, height: newHeight)
        panel.setFrame(newFrame, display: true, animate: false)
    }

    // ------------------------------------------------------------------
    // MARK: - Visibility
    // ------------------------------------------------------------------

    func show() {
        guard let panel = window else { return }
        updatePosition()
        panel.orderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
    }
}

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
