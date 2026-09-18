import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var notchWindow: CustomNotchWindow?
    let hydrationManager = HydrationManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as a background/menu bar app without a dock icon
        NSApp.setActivationPolicy(.accessory)
        
        setupMenuBar()
        setupNotchWindow()
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "Hydration")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Trigger Reminder", action: #selector(triggerReminder), keyEquivalent: "t"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func triggerReminder() {
        hydrationManager.triggerReminder()
        // Also trigger the UI animation
        NotificationCenter.default.post(name: NSNotification.Name("TriggerAnimation"), object: nil)
    }

    func setupNotchWindow() {
        guard let screen = NSScreen.main else { return }
        
        let windowWidth: CGFloat = 350
        let windowHeight: CGFloat = 400
        let windowRect = NSRect(x: screen.frame.midX - windowWidth / 2, 
                                y: screen.frame.maxY - windowHeight, 
                                width: windowWidth, 
                                height: windowHeight)
                                
        notchWindow = CustomNotchWindow(contentRect: windowRect)
        
        // Pass HydrationManager into the root view
        let rootView = NotchContentView().environmentObject(hydrationManager)
        let hostingController = NSHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .clear
        
        notchWindow?.contentView = hostingController.view
        notchWindow?.makeKeyAndOrderFront(nil)
    }
}

class CustomNotchWindow: NSWindow {
    init(contentRect: NSRect) {
        super.init(contentRect: contentRect, styleMask: .borderless, backing: .buffered, defer: false)
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .popUpMenu // Or .statusBar, ensures it's above normal windows
        
        // This makes sure clicks on transparent parts pass through to the apps below
        self.ignoresMouseEvents = false
    }
}
