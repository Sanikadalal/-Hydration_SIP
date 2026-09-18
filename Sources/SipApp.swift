// SipApp.swift
// Sip – macOS Menu Bar hydration reminder
// Entry point: pure AppKit window management via AppDelegate.
// No scenes are declared so SwiftUI does not create any default windows.

import SwiftUI

@main
struct SipApp: App {

    // Wire AppDelegate into the SwiftUI lifecycle.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We manage all windows ourselves in AppDelegate/NotchWindowController.
        // An empty Settings scene keeps the compiler happy while producing
        // no visible UI surface on its own.
        Settings {
            EmptyView()
        }
    }
}
