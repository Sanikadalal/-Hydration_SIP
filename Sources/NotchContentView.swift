import SwiftUI
import AppKit

// MARK: - Mascot State


// MARK: - Panel Size Helper

extension MascotState {
    /// The notch-pill panel size for each mascot state.
    var panelSize: CGSize {
        switch self {
        case .hidden:      return CGSize(width: 220, height: 0)
        case .peeking:     return CGSize(width: 126, height: 80)
        case .hanging:     return CGSize(width: 220, height: 170)
        case .pouring:     return CGSize(width: 220, height: 200)
        case .waiting:     return CGSize(width: 260, height: 220)
        case .celebrating: return CGSize(width: 260, height: 220)
        case .retreating:  return CGSize(width: 126, height: 80)
        }
    }

    var isVisible: Bool { self != .hidden }
}

// MARK: - NotchContentView

struct NotchContentView: View {
    @EnvironmentObject var hydrationManager: HydrationManager

    @State private var mascotState: MascotState = .hidden
    @State private var contentOpacity: Double   = 0
    @State private var contentScale: Double     = 0.8

    /// Notification posted by HydrationManager / AppDelegate when it's time to show.
    let animationTrigger = NotificationCenter.default.publisher(
        for: NSNotification.Name("TriggerAnimation")
    )

    private let spring = Animation.spring(response: 0.55, dampingFraction: 0.72)

    // MARK: Body

    var body: some View {
        ZStack(alignment: .top) {
            notchPill

            if mascotState != .hidden {
                contentStack
                    .opacity(contentOpacity)
                    .scaleEffect(contentScale, anchor: .top)
            }
        }
        // Animate the outer frame with the panel size
        .frame(
            width:  mascotState.panelSize.width,
            height: max(mascotState.panelSize.height, 1),
            alignment: .top
        )
        .animation(spring, value: mascotState)
        .onReceive(animationTrigger) { _ in startSequence() }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                startSequence()
            }
        }
    }

    // MARK: - Notch Pill Background

    private var notchPill: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.black)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.12)
            )
            .frame(
                width:  mascotState.panelSize.width,
                height: max(mascotState.panelSize.height, 1)
            )
            .animation(spring, value: mascotState)
    }

    // MARK: - Content Stack

    @ViewBuilder
    private var contentStack: some View {
        VStack(spacing: 0) {
            // Mascot body — height varies per state
            MascotView(state: mascotState)
                .frame(height: mascotContentHeight)
                .clipped()

            // Waiting → show action buttons
            if mascotState == .waiting {
                actionButtons
                    .padding(.top, 6)
                    .padding(.bottom, 12)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal:   .opacity
                    ))
            }

            // Celebrating → show progress & streak
            if mascotState == .celebrating {
                celebrationInfo
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.top, 8)
    }

    private var mascotContentHeight: CGFloat {
        switch mascotState {
        case .hidden:                return 0
        case .peeking, .retreating:  return 56
        case .hanging:               return 140
        case .pouring:               return 155
        case .waiting, .celebrating: return 155
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button { snooze() } label: {
                Text("Snooze 😴")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.13), in: Capsule())
            }
            .buttonStyle(.plain)

            Button { confirmDrank() } label: {
                Text("Drank 💧")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(hex: "4FC3F7"), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Celebration Info

    private var celebrationInfo: some View {
        VStack(spacing: 3) {
            let done  = hydrationManager.glassesCount
            let total = hydrationManager.dailyGoal

            Text("🎉 \(done)/\(total) glasses!")
                .font(.system(.caption, design: .rounded).bold())
                .foregroundStyle(.white)

            if hydrationManager.streak > 1 {
                Text("🔥 \(hydrationManager.streak) day streak!")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.yellow)
            }
        }
    }

    // MARK: - State Sequence

    private func startSequence() {
        // Only start from a resting state
        guard mascotState == .hidden || mascotState == .retreating else { return }

        transition(to: .peeking, after: 0.0)
        transition(to: .hanging, after: 0.7)
        transition(to: .pouring, after: 1.5)
        transition(to: .waiting, after: 3.2)
    }

    private func transition(to state: MascotState, after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(spring) {
                mascotState    = state
                contentOpacity = 1
                contentScale   = 1
            }
        }
    }

    private func confirmDrank() {
        hydrationManager.logDrink()
        withAnimation(spring) { mascotState = .celebrating }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { retreat() }
    }

    private func snooze() {
        hydrationManager.snooze(minutes: 10)
        retreat()
    }

    private func retreat() {
        withAnimation(spring) { mascotState = .retreating }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(spring) {
                mascotState    = .hidden
                contentOpacity = 0
                contentScale   = 0.8
            }
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Preview

#Preview {
    NotchContentView()
        .environmentObject(HydrationManager.shared)
        .frame(width: 300, height: 300)
        .background(Color.gray.opacity(0.3))
}
