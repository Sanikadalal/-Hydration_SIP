import SwiftUI

// MARK: - Particle

private struct Particle: Identifiable {
    let id: Int
    let angle: Double          // radians
    let distance: CGFloat      // max travel
    let size: CGFloat          // diameter
    let color: Color
    let delay: Double          // stagger
}

// MARK: - SparkleView

/// Burst of 10 coloured particles that radiate from center, fade, and disappear.
/// Overlay this on top of the mascot during the `.celebrating` state.
struct SparkleView: View {

    private static let colors: [Color] = [
        Color(hex: "4FC3F7"),  // sky blue
        Color(hex: "26C6DA"),  // teal
        Color(hex: "FFEB3B"),  // yellow
        Color(hex: "F48FB1"),  // pink
        Color(hex: "A5D6A7"),  // mint green
        Color(hex: "FF8A65"),  // orange
    ]

    private let particles: [Particle] = {
        let count = 11
        return (0..<count).map { i in
            Particle(
                id:       i,
                angle:    Double(i) * (2 * .pi / Double(count)),
                distance: CGFloat.random(in: 28...52),
                size:     CGFloat.random(in: 4...10),
                color:    SparkleView.colors[i % SparkleView.colors.count],
                delay:    Double(i) * 0.04
            )
        }
    }()

    @State private var triggered = false

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                ParticleView(particle: p, triggered: triggered)
            }
        }
        .onAppear { trigger() }
    }

    private func trigger() {
        triggered = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            triggered = true
        }
    }
}

// MARK: - ParticleView

private struct ParticleView: View {
    let particle: Particle
    let triggered: Bool

    @State private var scale:   CGFloat = 0
    @State private var offset:  CGSize  = .zero
    @State private var opacity: Double  = 0

    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .scaleEffect(scale)
            .offset(offset)
            .opacity(opacity)
            .onChange(of: triggered) { isOn in
                if isOn { burst() } else { reset() }
            }
            .onAppear {
                if triggered { burst() }
            }
    }

    private func burst() {
        reset()
        let dx = CGFloat(cos(particle.angle)) * particle.distance
        let dy = CGFloat(sin(particle.angle)) * particle.distance

        DispatchQueue.main.asyncAfter(deadline: .now() + particle.delay) {
            // Appear + expand
            withAnimation(.easeOut(duration: 0.35)) {
                scale   = 1.0
                offset  = CGSize(width: dx, height: dy)
                opacity = 1.0
            }
            // Fade out
            withAnimation(.easeIn(duration: 0.45).delay(0.35)) {
                scale   = 0.3
                opacity = 0
            }
        }
    }

    private func reset() {
        scale   = 0
        offset  = .zero
        opacity = 0
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
        SparkleView()
            .frame(width: 120, height: 120)
    }
    .frame(width: 200, height: 200)
}
