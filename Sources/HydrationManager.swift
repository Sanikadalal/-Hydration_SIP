import Foundation
import SwiftUI
import Combine

class HydrationManager: ObservableObject {
    @AppStorage("isOnboarded") var isOnboarded: Bool = false
    @AppStorage("dailyGoalMl") var dailyGoalMl: Int = 2000
    @AppStorage("totalDrankMl") var totalDrankMl: Int = 0
    @AppStorage("weightKg") var weightKg: Double = 60.0
    @AppStorage("activityLevel") var activityLevel: Int = 1 // 1=Low, 2=Med, 3=High
    
    @Published var currentMessage: String = "Pani pilo! 💧"
    @Published var showVictory: Bool = false
    
    private var reminderTimer: Timer?
    private let reminderInterval: TimeInterval = 60 * 30 // 30 minutes
    
    let messages = [
        "Time for a sip! 💧",
        "Keep glowing, drink water ✨",
        "Your body needs water!",
        "Hydration check 👀",
        "Take a break, take a sip.",
        "You've been coding too long.",
        "sudo drink-water"
    ]
    
    init() {
        if isOnboarded {
            startTimer()
        }
    }
    
    func completeOnboarding() {
        // Calculate goal: Weight in kg * 35ml + (Activity Level * 350ml)
        dailyGoalMl = Int(weightKg * 35.0) + (activityLevel * 350)
        isOnboarded = true
        startTimer()
    }
    
    func startTimer() {
        reminderTimer?.invalidate()
        reminderTimer = Timer.scheduledTimer(withTimeInterval: reminderInterval, repeats: true) { [weak self] _ in
            self?.triggerReminder()
        }
    }
    
    func triggerReminder() {
        currentMessage = messages.randomElement() ?? messages[0]
        NotificationCenter.default.post(name: NSNotification.Name("TriggerAnimation"), object: nil)
    }
    
    func hydrate(amount: Int = 250) {
        totalDrankMl += amount
        
        if totalDrankMl >= dailyGoalMl {
            showVictory = true
        }
        
        startTimer()
    }
    
    func resetDaily() {
        totalDrankMl = 0
        showVictory = false
    }
}
