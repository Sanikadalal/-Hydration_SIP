import SwiftUI

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
    // notchHeight 54 with -20 top padding = 34 visible height
    @State private var notchHeight: CGFloat = 54
    @State private var mascotOffset: CGFloat = -200
    
    // Configurable messages
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
            
            // Dummy button to trigger the interaction
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
            
            // 🐒 THE CHARACTER LAYER (Hangs strictly below the notch)
            VStack(spacing: 8) {
                // Mascot
                Text(state == .celebrating ? "🐒✨" : "🐒")
                    .font(.system(size: 65))
                    // Swings like a pendulum from its hands (top anchor)
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
                        .transition(.scale(scale: 0.1).combined(with: .opacity).combined(with: .move(edge: .top)))
                }

                // 🥛 Glass, Message, Buttons
                if state == .poured || state == .celebrating {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            Text("🥛")
                                .font(.system(size: 42))
                                .offset(y: state == .celebrating ? -25 : 0) // Celebratory jump up
                                .scaleEffect(state == .celebrating ? 1.15 : 1.0)
                                .animation(.spring(response: 0.35, dampingFraction: 0.5), value: state)
                            
                            // Chat bubble
                            Text(activeMessage)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
                        }
                        .transition(.scale(scale: 0.5).combined(with: .opacity).combined(with: .move(edge: .top)))
                        
                        // Interaction Buttons
                        if state == .poured {
                            HStack(spacing: 20) {
                                Button("Snooze") {
                                    snooze()
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.black.opacity(0.6))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .buttonStyle(.plain)
                                
                                Button("Drank 💧") {
                                    drinkConfirmed()
                                }
                                .font(.system(size: 16, weight: .bold))
                                .padding(.horizontal, 22)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .buttonStyle(.plain)
                                .shadow(color: .blue.opacity(0.3), radius: 5, y: 3)
                            }
                            .padding(.top, 5)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
            }
            .offset(y: mascotOffset)
            .zIndex(1) // Keep strictly behind the notch during drops
            
            // ⬛️ THE NOTCH PORTAL
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black)
                .shadow(color: .black.opacity(state != .hidden ? 0.3 : 0), radius: 15, x: 0, y: 10)
                .frame(width: 170, height: notchHeight)
                // Hides the top round corners perfectly off screen
                .padding(.top, -20)
                .zIndex(2) // Flushes over the monkey
        }
        .ignoresSafeArea(.all)
    }
    
    // MARK: - State Logic & Choreography
    
    func startHydrationSequence() {
        activeMessage = messages.randomElement() ?? messages[0]
        
        // 1. Notch extends downward slightly (portal opens)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            notchHeight = 110 // Extends to 90px visible
            state = .stretching
        }
        
        // 2. Monkey peeks out (slides down from behind the notch)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                mascotOffset = 60
                state = .peeking
            }
        }
        
        // 3. Monkey swings body out and grabs the notch. Notch retracts back to normal.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                notchHeight = 54 // Snaps back to 34px visible
                // Top of the monkey is at 25px, safely grasping behind the 34px notch edge
                mascotOffset = 25 
                state = .hanging
            }
        }
        
        // 4. Pouring water
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation {
                state = .pouring
            }
        }
        
        // 5. Catch water in glass, show UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                state = .poured
            }
        }
    }
    
    func drinkConfirmed() {
        // Celebrate
        withAnimation {
            state = .celebrating
        }
        
        // Retract
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeIn(duration: 0.3)) {
                mascotOffset = -200
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    notchHeight = 54
                    state = .hidden
                }
            }
        }
    }
    
    func snooze() {
        withAnimation(.easeIn(duration: 0.2)) {
            mascotOffset = -200
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                notchHeight = 54
                state = .hidden
            }
        }
    }
}


