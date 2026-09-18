import SwiftUI
import SceneKit

struct NotchContentView: View {
    @EnvironmentObject var hydrationManager: HydrationManager
    @State private var isExpanded: Bool = false
    @State private var floatOffset: CGFloat = 5
    
    let animationTrigger = NotificationCenter.default.publisher(for: NSNotification.Name("TriggerAnimation"))

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // The hanging stem
                stem
                    .transition(.move(edge: .top))
                    .zIndex(1)
                
                // The main portal / ring
                mainPortal
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.2, anchor: .top).combined(with: .opacity),
                        removal: .scale(scale: 0.2, anchor: .top).combined(with: .opacity)
                    ))
                    .zIndex(0)
                    
                // Optional UI controls below the ring
                if hydrationManager.isOnboarded && !hydrationManager.showVictory {
                    uiControls
                        .padding(.top, 16)
                        .transition(.opacity)
                }
            }
        }
        .frame(width: 400, height: 600, alignment: .top)
        .ignoresSafeArea() // This fixes the gap between the notch and UI!
        .onReceive(animationTrigger) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0)) {
                isExpanded = true
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0)) {
                    isExpanded = true
                }
            }
        }
    }
    
    var stem: some View {
        Rectangle()
            .fill(Color.black)
            .frame(width: 40, height: 40)
            .offset(y: -5)
            .padding(.bottom, -5)
    }
    
    var mainPortal: some View {
        ZStack {
            if !hydrationManager.isOnboarded {
                onboardingView
            } else if hydrationManager.showVictory {
                victoryView
            } else {
                mascotView
            }
        }
    }
    
    var mascotView: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .frame(width: 250, height: 250)
            
            // Try loading a 3D model first (.usdz or .scn)
            if let usdzUrl = Bundle.module.url(forResource: "monkey", withExtension: "usdz") ?? Bundle.module.url(forResource: "monkey", withExtension: "scn") {
                SceneView(
                    scene: try? SCNScene(url: usdzUrl, options: nil),
                    options: [.autoenablesDefaultLighting, .allowsCameraControl],
                    preferredFramesPerSecond: 60,
                    antialiasingMode: .multisampling4X
                )
                .frame(width: 250, height: 250)
                .clipShape(Circle())
            } 
            // Fallback to our new gorgeous 2D mascot
            else if let url = Bundle.module.url(forResource: "mascot2d", withExtension: "jpg"),
               let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 250, height: 250)
                    .clipShape(Circle())
                    .offset(y: floatOffset)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            floatOffset = -5
                        }
                    }
            } else {
                Circle().fill(Color.gray).frame(width: 250, height: 250)
            }
            
            // Glowing border
            Circle()
                .strokeBorder(Color.white, lineWidth: 6)
                .frame(width: 250, height: 250)
                .shadow(color: Color.blue.opacity(0.8), radius: 15, x: 0, y: 0)
        }
    }
    
    var victoryView: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .frame(width: 250, height: 250)
            
            if let url = Bundle.module.url(forResource: "victory", withExtension: "jpg"),
               let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 250, height: 250)
                    .clipShape(Circle())
            }
            
            Circle()
                .strokeBorder(Color.yellow, lineWidth: 6)
                .frame(width: 250, height: 250)
                .shadow(color: Color.orange.opacity(0.8), radius: 15, x: 0, y: 0)
                
            VStack {
                Spacer()
                Text("Goal Reached! 🏆")
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                    .padding(.bottom, 8)
                
                Button("Reset for tomorrow") {
                    withAnimation {
                        hydrationManager.resetDaily()
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.7))
                .cornerRadius(16)
                .padding(.bottom, 20)
            }
            .frame(width: 250, height: 250)
        }
    }
    
    var onboardingView: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: 320, height: 320)
            
            Circle()
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 4)
                .frame(width: 320, height: 320)
                
            VStack(spacing: 16) {
                Text("Let's Get Started!")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                HStack {
                    Text("Weight (kg):")
                        .foregroundColor(.white)
                    TextField("60", value: $hydrationManager.weightKg, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity Level:")
                        .foregroundColor(.white)
                        .font(.caption)
                    Picker("", selection: $hydrationManager.activityLevel) {
                        Text("Low").tag(1)
                        Text("Medium").tag(2)
                        Text("High").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 150)
                }
                
                Button(action: {
                    withAnimation {
                        hydrationManager.completeOnboarding()
                    }
                }) {
                    Text("Save & Start")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
            }
            .padding()
            .frame(width: 280, height: 280)
        }
    }
    
    var uiControls: some View {
        VStack(spacing: 12) {
            Text(hydrationManager.currentMessage)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .shadow(radius: 5)
            
            HStack(spacing: 16) {
                Button(action: hideMascot) {
                    Text("Snooze")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Button(action: completeHydration) {
                    Text("Drank it 💧")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: .white.opacity(0.3), radius: 5, x: 0, y: 0)
                }
                .buttonStyle(.plain)
            }
            
            ProgressView(value: Double(hydrationManager.totalDrankMl), total: Double(hydrationManager.dailyGoalMl))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(width: 200)
                .padding(.top, 8)
                
            Text("\(hydrationManager.totalDrankMl) / \(hydrationManager.dailyGoalMl) ml")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private func completeHydration() {
        hydrationManager.hydrate(amount: 250)
        if !hydrationManager.showVictory {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                hideMascot()
            }
        }
    }
    
    private func hideMascot() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
            isExpanded = false
        }
    }
}

