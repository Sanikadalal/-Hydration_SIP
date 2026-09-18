import SwiftUI
import AppKit

// MARK: - WaterDropShape

/// A teardrop / water-drop path shape.
struct WaterDropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = rect.midX

        // Start at the pointy bottom tip
        path.move(to: CGPoint(x: cx, y: h))
        // Left curve up to top
        path.addCurve(
            to: CGPoint(x: cx, y: 0),
            control1: CGPoint(x: cx - w * 0.9, y: h * 0.7),
            control2: CGPoint(x: cx - w * 0.5, y: 0)
        )
        // Right curve back down
        path.addCurve(
            to: CGPoint(x: cx, y: h),
            control1: CGPoint(x: cx + w * 0.5, y: 0),
            control2: CGPoint(x: cx + w * 0.9, y: h * 0.7)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Smile Path Shape

struct SmilePath: Shape {
    /// 0 = small O/surprised, 0.5 = open smile, 1 = big grin
    var smileAmount: Double

    var animatableData: Double {
        get { smileAmount }
        set { smileAmount = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let inset = w * (1.0 - smileAmount) * 0.3

        // Mouth is an arc from left to right
        path.move(to: CGPoint(x: inset, y: h * 0.2))
        path.addQuadCurve(
            to: CGPoint(x: w - inset, y: h * 0.2),
            control: CGPoint(x: w * 0.5, y: h * (0.6 + smileAmount * 0.6))
        )
        return path
    }
}

// MARK: - MonkeyFaceView

struct MonkeyFaceView: View {
    let state: MascotState

    // Pupil offset target per state
    private var pupilOffset: CGSize {
        switch state {
        case .peeking:   return CGSize(width: 0, height: -3)
        case .pouring:   return CGSize(width: 2, height: 1)
        default:         return .zero
        }
    }

    private var eyeSquint: Bool { state == .pouring || state == .celebrating }

    private var smileAmount: Double {
        switch state {
        case .peeking:                  return 0.0  // O shape
        case .hanging:                  return 0.4
        case .pouring:                  return 0.7
        case .waiting:                  return 0.5
        case .celebrating:              return 1.0
        case .retreating, .hidden:      return 0.3
        }
    }

    // Mouth open height based on state
    private var mouthOpenness: Double {
        switch state {
        case .peeking:     return 1.0
        case .pouring:     return 0.7
        case .celebrating: return 0.8
        default:           return 0.3
        }
    }

    var body: some View {
        ZStack {
            // Head circle — tan
            Ellipse()
                .fill(Color(hex: "D4A04A"))
                .frame(width: 62, height: 58)

            // Ear: left
            earShape(flip: false)
                .offset(x: -28, y: 4)
            // Ear: right
            earShape(flip: true)
                .offset(x: 28, y: 4)

            // Muzzle (lighter oval)
            Ellipse()
                .fill(Color(hex: "E8C070"))
                .frame(width: 30, height: 22)
                .offset(y: 10)

            // Left eye
            eyeView(pupilOffset: pupilOffset, squint: eyeSquint)
                .offset(x: -12, y: -4)
            // Right eye
            eyeView(pupilOffset: CGSize(width: -pupilOffset.width, height: pupilOffset.height), squint: eyeSquint)
                .offset(x: 12, y: -4)

            // Nose
            Capsule()
                .fill(Color(hex: "8B6914").opacity(0.6))
                .frame(width: 10, height: 5)
                .offset(y: 6)

            // Mouth
            mouthView
                .offset(y: 16)
        }
    }

    // MARK: Ear

    private func earShape(flip: Bool) -> some View {
        Ellipse()
            .fill(Color(hex: "8B6914"))
            .frame(width: 14, height: 16)
            .overlay(
                Ellipse()
                    .fill(Color(hex: "D4A04A").opacity(0.5))
                    .frame(width: 8, height: 10)
            )
    }

    // MARK: Eye

    private func eyeView(pupilOffset: CGSize, squint: Bool) -> some View {
        ZStack {
            // Sclera
            Ellipse()
                .fill(.white)
                .frame(width: squint ? 14 : 13, height: squint ? 7 : 12)

            // Pupil
            Circle()
                .fill(.black)
                .frame(width: 6, height: 6)
                .offset(pupilOffset)

            // Shine
            Circle()
                .fill(.white)
                .frame(width: 2.5, height: 2.5)
                .offset(x: pupilOffset.width + 1.5, y: pupilOffset.height - 1.5)
        }
    }

    // MARK: Mouth

    @ViewBuilder
    private var mouthView: some View {
        if state == .peeking {
            // Surprised O
            Ellipse()
                .fill(.black)
                .frame(width: 10, height: 10)
                .offset(y: -2)
        } else {
            ZStack {
                // Smile outline
                SmilePath(smileAmount: smileAmount)
                    .stroke(Color(hex: "7A3B00"), lineWidth: 1.5)
                    .frame(width: 24, height: 14)

                // Teeth on pouring / celebrating
                if state == .pouring || state == .celebrating {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white)
                        .frame(width: 16, height: 6)
                        .offset(y: 2)
                }
            }
        }
    }
}

// MARK: - MonkeyBodyView

struct MonkeyBodyView: View {
    let state: MascotState

    // Right arm raise angle (radians)
    private var armRaise: Double {
        state == .pouring ? -1.1 : (state == .celebrating ? -0.5 : 0.1)
    }

    // Glass tilt (radians)
    private var glassTilt: Double {
        state == .pouring ? -1.3 : 0.0
    }

    // Water level in glass (0–1)
    private var waterLevel: Double {
        switch state {
        case .pouring:     return 0.2
        case .celebrating: return 0.0
        default:           return 0.7
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Body oval — warm brown
            Ellipse()
                .fill(Color(hex: "8B6914"))
                .frame(width: 52, height: 44)

            // Belly (lighter)
            Ellipse()
                .fill(Color(hex: "C89830").opacity(0.55))
                .frame(width: 32, height: 28)
                .offset(y: 2)

            // Left arm (passive)
            leftArm

            // Right arm + glass
            rightArmWithGlass
        }
    }

    private var leftArm: some View {
        RoundedRectangle(cornerRadius: 7)
            .fill(Color(hex: "8B6914"))
            .frame(width: 12, height: 28)
            .rotationEffect(.degrees(18))
            .offset(x: -28, y: 6)
    }

    private var rightArmWithGlass: some View {
        ZStack(alignment: .bottom) {
            // Arm
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(hex: "8B6914"))
                .frame(width: 12, height: 28)

            // Glass of water
            glassView
                .offset(y: -24)
        }
        .rotationEffect(.radians(armRaise), anchor: .top)
        .offset(x: 28, y: 6)
        .animation(.spring(response: 0.55, dampingFraction: 0.72), value: armRaise)
    }

    // MARK: Glass

    private var glassView: some View {
        ZStack(alignment: .bottom) {
            // Glass body
            RoundedRectangle(cornerRadius: 3)
                .fill(.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(.white.opacity(0.5), lineWidth: 1)
                )
                .frame(width: 14, height: 20)

            // Water inside
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "4FC3F7").opacity(0.82))
                .frame(width: 12, height: 20 * waterLevel)
                .animation(.spring(response: 0.55, dampingFraction: 0.72), value: waterLevel)
        }
        .rotationEffect(.radians(glassTilt), anchor: .bottom)
        .animation(.spring(response: 0.55, dampingFraction: 0.72), value: glassTilt)
    }
}

// MARK: - NotchGripView

/// Two small hands gripping the top edge.
struct NotchGripView: View {
    var body: some View {
        HStack(spacing: 44) {
            grip(flip: false)
            grip(flip: true)
        }
    }

    private func grip(flip: Bool) -> some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(Color(hex: "8B6914"))
            .frame(width: 12, height: 9)
            .overlay(
                // Knuckle lines
                VStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule()
                            .fill(Color(hex: "6B4F10").opacity(0.5))
                            .frame(width: 8, height: 1)
                    }
                }
            )
            .scaleEffect(x: flip ? -1 : 1)
    }
}

// MARK: - WaterDropsView

private struct FallingDrop: Identifiable {
    let id: Int
    let xOffset: CGFloat
    let delay: Double
    let size: CGFloat
}

struct WaterDropsView: View {
    let isPouring: Bool

    private let drops: [FallingDrop] = [
        FallingDrop(id: 0, xOffset: -6,  delay: 0.00, size: 7),
        FallingDrop(id: 1, xOffset:  2,  delay: 0.10, size: 5),
        FallingDrop(id: 2, xOffset: -2,  delay: 0.20, size: 6),
        FallingDrop(id: 3, xOffset:  7,  delay: 0.30, size: 4),
    ]

    var body: some View {
        ZStack {
            ForEach(drops) { drop in
                SingleDropView(drop: drop, isActive: isPouring)
            }
        }
        .frame(width: 30, height: 40)
    }
}

private struct SingleDropView: View {
    let drop: FallingDrop
    let isActive: Bool

    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double  = 0

    var body: some View {
        WaterDropShape()
            .fill(Color(hex: "4FC3F7").opacity(0.9))
            .frame(width: drop.size, height: drop.size * 1.4)
            .offset(x: drop.xOffset, y: yOffset)
            .opacity(opacity)
            .onChange(of: isActive) { active in
                if active {
                    DispatchQueue.main.asyncAfter(deadline: .now() + drop.delay) {
                        withAnimation(.easeIn(duration: 0.5)) {
                            yOffset  = 36
                            opacity  = 0
                        }
                        opacity = 0.9
                    }
                } else {
                    yOffset = 0
                    opacity = 0
                }
            }
            .onAppear {
                if isActive { triggerDrop() }
            }
    }

    private func triggerDrop() {
        yOffset = 0
        opacity = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + drop.delay) {
            opacity = 0.9
            withAnimation(.easeIn(duration: 0.5)) {
                yOffset = 36
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.25)) {
                opacity = 0
            }
        }
    }
}

// MARK: - MascotView

struct MascotView: View {
    let state: MascotState

    // Vertical reveal offset — peeking shows only the top of the head
    private var verticalOffset: CGFloat {
        switch state {
        case .hidden:                return -80
        case .peeking, .retreating:  return 34   // head peeks over top edge
        case .hanging, .pouring,
             .waiting, .celebrating: return 0
        }
    }

    // Whether to show hands gripping the notch top
    private var showGrip: Bool {
        state == .hanging || state == .waiting || state == .pouring || state == .celebrating
    }

    // Whether drops should animate
    private var isPouring: Bool { state == .pouring }

    // Celebrate wiggle
    @State private var wiggle: Double = 0

    var body: some View {
        ZStack(alignment: .top) {
            // Notch grip hands at very top
            if showGrip {
                NotchGripView()
                    .transition(.opacity)
                    .zIndex(2)
                    .offset(y: 2)
            }

            VStack(spacing: -8) {
                // Head
                MonkeyFaceView(state: state)
                    .frame(width: 68, height: 64)
                    .zIndex(1)

                // Body (only when fully hanging or beyond)
                if state == .hanging || state == .pouring ||
                   state == .waiting || state == .celebrating {
                    MonkeyBodyView(state: state)
                        .frame(width: 60, height: 52)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal:   .move(edge: .top).combined(with: .opacity)
                        ))
                        .zIndex(0)
                        .overlay(
                            // Water drops pour out of the glass
                            WaterDropsView(isPouring: isPouring)
                                .offset(x: 28, y: -6),
                            alignment: .topTrailing
                        )

                    // Sparkle overlay during celebration
                    if state == .celebrating {
                        SparkleView()
                            .frame(width: 120, height: 120)
                            .transition(.opacity)
                    }
                }
            }
            .offset(y: verticalOffset)
            .animation(.spring(response: 0.55, dampingFraction: 0.72), value: state)
            .rotationEffect(.degrees(wiggle))
            .onChange(of: state) { newState in
                if newState == .celebrating {
                    startWiggle()
                } else {
                    wiggle = 0
                }
            }
        }
        .clipped()
    }

    private func startWiggle() {
        withAnimation(.easeInOut(duration: 0.12).repeatCount(6, autoreverses: true)) {
            wiggle = 5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            wiggle = 0
        }
    }
}

// MARK: - Preview

#Preview("Waiting") {
    ZStack {
        Color.gray
        MascotView(state: .waiting)
            .frame(width: 160, height: 200)
    }
}

#Preview("Pouring") {
    ZStack {
        Color.gray
        MascotView(state: .pouring)
            .frame(width: 160, height: 200)
    }
}
