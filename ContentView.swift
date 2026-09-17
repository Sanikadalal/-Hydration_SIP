import SwiftUI
import SceneKit

enum MascotState {
    case hidden
    case stretching
    case peeking
    case hanging
    case pouring
    case poured
    case celebrating
}

struct ContentView: View {
    @State private var state: MascotState = .hidden
    
    // Explicit animation values
    @State private var notchHeight: CGFloat = 54
    @State private var mascotOffset: CGFloat = -200
    
    let messages = [
        "Hehe… paani pilo 💧",
        "One sip? 🥺",
        "Hydration check 👀",
        "Your bottle is waiting."
    ]
    @State private var activeMessage = "Hehe… paani pilo 💧"
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background to simulate desktop wallpaper
            LinearGradient(
                colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            if state == .hidden {
                VStack {
                    Spacer()
                    Button("Simulate Time to Drink") {
                        startHydrationSequence()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .padding(.bottom, 50)
                }
                .transition(.opacity)
            }
            
            // 🐒 THE CHARACTER LAYER
            VStack(spacing: -10) {
                // Procedural 3D Mascot!
                Interactive3DMascot(state: state)
                    .rotationEffect(
                        .degrees(state == .hanging || state == .pouring || state == .poured || state == .celebrating ? 4 : -4),
                        anchor: .top
                    )
                    .animation(
                        .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                        value: state
                    )
                
                // 💧 Pouring droplet animation
                if state == .pouring {
                    Text("💧")
                        .font(.system(size: 24))
                        .offset(y: -10)
                        .transition(.scale(scale: 0.1).combined(with: .opacity).combined(with: .move(edge: .top)))
                }

                // 🥛 Glass & UI Container
                if state == .poured || state == .celebrating {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            Text("🥛")
                                .font(.system(size: 42))
                                .offset(y: state == .celebrating ? -25 : 0)
                                .scaleEffect(state == .celebrating ? 1.15 : 1.0)
                                .animation(.spring(response: 0.35, dampingFraction: 0.5), value: state)
                            
                            // Premium Frosted Chat Bubble
                            Text(activeMessage)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.regularMaterial) // Frosted glass!
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                        }
                        .transition(.scale(scale: 0.5).combined(with: .opacity).combined(with: .move(edge: .top)))
                        
                        // Interaction Buttons
                        if state == .poured {
                            HStack(spacing: 20) {
                                Button("Snooze") {
                                    snooze()
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .buttonStyle(.plain)
                                
                                Button("Drank 💧") {
                                    drinkConfirmed()
                                }
                                .font(.system(size: 15, weight: .bold))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .buttonStyle(.plain)
                                .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
                            }
                            .padding(.top, 5)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
            }
            .offset(y: mascotOffset)
            .zIndex(1) 
            
            // ⬛️ THE NOTCH PORTAL
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black)
                .shadow(color: .black.opacity(state != .hidden ? 0.4 : 0), radius: 15, x: 0, y: 10)
                .frame(width: 170, height: notchHeight)
                .padding(.top, -20)
                .zIndex(2)
        }
        .ignoresSafeArea(.all)
    }
    
    // MARK: - State Logic
    
    func startHydrationSequence() {
        activeMessage = messages.randomElement() ?? messages[0]
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            notchHeight = 110 // Opens portal
            state = .stretching
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                mascotOffset = 60
                state = .peeking
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                notchHeight = 54 
                mascotOffset = 25 
                state = .hanging
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { state = .pouring }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { state = .poured }
        }
    }
    
    func drinkConfirmed() {
        withAnimation { state = .celebrating }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeIn(duration: 0.3)) { mascotOffset = -200 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    notchHeight = 54
                    state = .hidden
                }
            }
        }
    }
    
    func snooze() {
        withAnimation(.easeIn(duration: 0.2)) { mascotOffset = -200 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                notchHeight = 54
                state = .hidden
            }
        }
    }
}

// MARK: - Procedural 3D Mascot using SceneKit!
struct Interactive3DMascot: View {
    var state: MascotState
    
    @State private var scene = SCNScene()
    @State private var mascotNode = SCNNode()
    
    var body: some View {
        SceneView(
            scene: scene,
            options: [.autoenablesDefaultLighting]
        )
        .frame(width: 140, height: 140)
        .onAppear {
            setupScene()
        }
        // Respond to app states by changing 3D animations
        .onChange(of: state) { newState in
            updateAnimation(for: newState)
        }
    }
    
    func setupScene() {
        // Transparent background
        scene.background.contents = CGColor(gray: 0, alpha: 0)
        
        // --- 1. Construct the 3D Monkey head ---
        
        mascotNode = SCNNode()
        
        // Base Face
        let headGeo = SCNBox(width: 1.8, height: 1.5, length: 1.5, chamferRadius: 0.6)
        headGeo.firstMaterial?.diffuse.contents = CGColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0)
        headGeo.firstMaterial?.specular.contents = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        headGeo.firstMaterial?.shininess = 30
        let head = SCNNode(geometry: headGeo)
        
        // Eyes
        let eyeGeo = SCNSphere(radius: 0.18)
        eyeGeo.firstMaterial?.diffuse.contents = CGColor(gray: 0.1, alpha: 1.0)
        
        let leftEye = SCNNode(geometry: eyeGeo)
        leftEye.position = SCNVector3(-0.35, 0.1, 0.8)
        let rightEye = SCNNode(geometry: eyeGeo)
        rightEye.position = SCNVector3(0.35, 0.1, 0.8)
        
        // Cute Blushes
        let blushGeo = SCNSphere(radius: 0.15)
        blushGeo.firstMaterial?.diffuse.contents = CGColor(red: 1.0, green: 0.4, blue: 0.5, alpha: 0.9)
        let leftBlush = SCNNode(geometry: blushGeo)
        leftBlush.position = SCNVector3(-0.6, -0.25, 0.75)
        let rightBlush = SCNNode(geometry: blushGeo)
        rightBlush.position = SCNVector3(0.6, -0.25, 0.75)
        
        // Ears
        let earGeo = SCNCylinder(radius: 0.35, height: 0.2)
        earGeo.firstMaterial?.diffuse.contents = CGColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0)
        let leftEar = SCNNode(geometry: earGeo)
        leftEar.position = SCNVector3(-0.95, 0, 0)
        leftEar.eulerAngles = SCNVector3(Float.pi/2, 0, 0)
        
        let rightEar = SCNNode(geometry: earGeo)
        rightEar.position = SCNVector3(0.95, 0, 0)
        rightEar.eulerAngles = SCNVector3(Float.pi/2, 0, 0)
        
        // Assemble
        head.addChildNode(leftEye)
        head.addChildNode(rightEye)
        head.addChildNode(leftBlush)
        head.addChildNode(rightBlush)
        head.addChildNode(leftEar)
        head.addChildNode(rightEar)
        mascotNode.addChildNode(head)
        
        // Start Idle Animation
        updateAnimation(for: state)
        
        scene.rootNode.addChildNode(mascotNode)
        
        // --- 2. Setup Camera ---
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 4)
        scene.rootNode.addChildNode(cameraNode)
    }
    
    func updateAnimation(for state: MascotState) {
        mascotNode.removeAllActions()
        
        if state == .celebrating {
            // Happy Spin + Bounce
            let spin = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 0.8)
            let bounceUp = SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 0.25)
            bounceUp.timingMode = .easeOut
            let bounceDown = SCNAction.moveBy(x: 0, y: -0.3, z: 0, duration: 0.25)
            bounceDown.timingMode = .easeIn
            
            let jump = SCNAction.sequence([bounceUp, bounceDown])
            mascotNode.runAction(SCNAction.group([spin, SCNAction.repeatForever(jump)]))
        } else {
            // Default Breathing (Subtle squish & stretch)
            let scaleUp = SCNAction.scale(to: 1.02, duration: 1.2)
            scaleUp.timingMode = .easeInEaseOut
            let scaleDown = SCNAction.scale(to: 0.98, duration: 1.2)
            scaleDown.timingMode = .easeInEaseOut
            
            mascotNode.runAction(SCNAction.repeatForever(SCNAction.sequence([scaleUp, scaleDown])))
        }
    }
}


