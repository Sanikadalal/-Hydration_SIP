import AppKit
import SwiftUI
import Combine

// MARK: - MenuBarController

/// Manages the NSStatusBar item: icon with progress ring, popover, and menu actions.
final class MenuBarController: NSObject {

    // MARK: Properties

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var hydrationManager: HydrationManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    init(hydrationManager: HydrationManager) {
        self.hydrationManager = hydrationManager
        super.init()
        setupStatusItem()
        setupPopover()
        observeChanges()
    }

    // MARK: Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }

        updateIcon()
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize   = CGSize(width: 220, height: 260)
        popover.behavior      = .transient
        popover.animates      = true

        let content = MenuBarPopoverView(
            hydrationManager: hydrationManager,
            closeAction: { [weak self] in self?.closePopover() }
        )
        popover.contentViewController = NSHostingController(rootView: content)
        self.popover = popover
    }

    private func observeChanges() {
        hydrationManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIcon()
            }
            .store(in: &cancellables)
    }

    // MARK: Icon Drawing

    /// Redraws the status bar icon with a coloured progress ring.
    func updateIcon() {
        guard let button = statusItem?.button else { return }

        let size = CGSize(width: 22, height: 22)
        let progress = Double(hydrationManager.glassesCount) / Double(max(1, hydrationManager.dailyGoal))  // 0.0 – 1.0
        let ringColor = iconColor(for: progress)

        let image = NSImage(size: size, flipped: false) { rect in
            // Background drop icon
            if let symbol = NSImage(systemSymbolName: "drop.fill",
                                    accessibilityDescription: nil) {
                let cfg = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
                let themed = symbol.withSymbolConfiguration(cfg)
                let tinted = themed?.tinted(with: NSColor(ringColor).withAlphaComponent(0.25))
                tinted?.draw(in: CGRect(x: 4, y: 3, width: 14, height: 16))
            }

            // Progress ring
            let lineWidth: CGFloat = 2.2
            let padding:   CGFloat = lineWidth / 2
            let ringRect = rect.insetBy(dx: padding, dy: padding)

            // Track
            let track = NSBezierPath(ovalIn: ringRect)
            NSColor.white.withAlphaComponent(0.15).setStroke()
            track.lineWidth = lineWidth
            track.stroke()

            // Arc
            if progress > 0 {
                let arc = NSBezierPath()
                let startAngle: CGFloat = 90                            // 12 o'clock
                let endAngle:   CGFloat = 90 - CGFloat(progress * 360)
                arc.appendArc(
                    withCenter: CGPoint(x: rect.midX, y: rect.midY),
                    radius:     ringRect.width / 2,
                    startAngle: startAngle,
                    endAngle:   endAngle,
                    clockwise:  true
                )
                NSColor(ringColor).setStroke()
                arc.lineWidth    = lineWidth
                arc.lineCapStyle = .round
                arc.stroke()
            }

            return true
        }

        image.isTemplate = false
        button.image = image
    }

    /// Colour shifts gray → blue → green based on progress.
    private func iconColor(for progress: Double) -> Color {
        if progress < 0.5 {
            // gray → blue
            let t = progress / 0.5
            return Color(
                red:   0.5 * (1 - t) + 0.31 * t,
                green: 0.5 * (1 - t) + 0.76 * t,
                blue:  0.5 * (1 - t) + 0.97 * t
            )
        } else {
            // blue → green
            let t = (progress - 0.5) / 0.5
            return Color(
                red:   0.31 * (1 - t) + 0.30 * t,
                green: 0.76 * (1 - t) + 0.69 * t,
                blue:  0.97 * (1 - t) + 0.31 * t
            )
        }
    }

    // MARK: Click Handling

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        guard let popover else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let logItem = NSMenuItem(
            title: "Log a sip 💧",
            action: #selector(logSip),
            keyEquivalent: ""
        )
        logItem.target = self
        menu.addItem(logItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Sip",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil  // Remove so left-click works normally next time
    }

    @objc private func logSip() {
        hydrationManager.logDrink()
    }

    @objc private func openSettings() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Sip Settings"
        win.center()
        win.contentView = NSHostingView(
            rootView: SettingsView().environmentObject(hydrationManager)
        )
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - NSImage Tint Helper

private extension NSImage {
    func tinted(with color: NSColor) -> NSImage? {
        guard let copy = self.copy() as? NSImage else { return nil }
        copy.lockFocus()
        color.set()
        NSRect(origin: .zero, size: copy.size).fill(using: .sourceAtop)
        copy.unlockFocus()
        return copy
    }
}

// MARK: - MenuBarPopoverView

struct MenuBarPopoverView: View {
    @ObservedObject var hydrationManager: HydrationManager
    let closeAction: () -> Void

    private var timeSinceLastDrink: String {
        guard let last = hydrationManager.lastDrinkTime else { return "—" }
        let mins = Int(Date().timeIntervalSince(last) / 60)
        if mins < 1  { return "Just now" }
        if mins < 60 { return "\(mins) min ago" }
        return "\(mins / 60)h \(mins % 60)m ago"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("💧")
                    .font(.title2)
                Text("Sip")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(.primary)
                Spacer()
            }

            Divider()

            // Progress
            VStack(alignment: .leading, spacing: 6) {
                Text("Today's progress")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)

                HStack {
                    Text("\(hydrationManager.glassesCount) of \(hydrationManager.dailyGoal) glasses 💧")
                        .font(.system(.body, design: .rounded).bold())
                    Spacer()
                    Text("\(Int(Double(hydrationManager.glassesCount) / Double(max(1, hydrationManager.dailyGoal)) * 100))%")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: Double(hydrationManager.glassesCount) / Double(max(1, hydrationManager.dailyGoal)))
                    .tint(Color(hex: "4FC3F7"))
            }

            // Last drink
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text("Last drink: \(timeSinceLastDrink)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Buttons
            VStack(spacing: 8) {
                Button {
                    hydrationManager.logDrink()
                    closeAction()
                } label: {
                    Label("Log a sip 💧", systemImage: "")
                        .font(.system(.body, design: .rounded).bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(hex: "4FC3F7"), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    Button("Settings...") {
                        closeAction()
                        // Open settings sheet via notification
                        NotificationCenter.default.post(name: .openSettings, object: nil)
                    }
                    .font(.system(.caption, design: .rounded))
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button("Quit Sip") {
                        NSApp.terminate(nil)
                    }
                    .font(.system(.caption, design: .rounded))
                    .buttonStyle(.plain)
                    .foregroundStyle(.red.opacity(0.8))
                }
            }
        }
        .padding(16)
        .frame(width: 220)
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let openSettings = Notification.Name("OpenSettings")
}
