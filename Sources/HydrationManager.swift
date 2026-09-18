// HydrationManager.swift
// Sip – macOS Menu Bar hydration reminder
//
// Central `@Observable` singleton that:
//  • Tracks hydration progress (glasses logged today, streak, last drink).
//  • Drives the `MascotState` state machine that the SwiftUI views observe.
//  • Manages the repeating reminder timer and snooze logic.
//  • Persists daily stats to UserDefaults under "sip.*" keys.

import Foundation
import Combine

// ---------------------------------------------------------------------------
// MARK: - MascotState
// ---------------------------------------------------------------------------

/// Every distinct visual pose the monkey mascot can be in.
/// The SwiftUI `MascotView` switches its drawing based on this value.
enum MascotState: Equatable {
    /// Fully off-screen / invisible.
    case hidden
    /// Top of the head / eyes peek over the notch edge.
    case peeking
    /// Monkey hangs by its hands from the notch ledge.
    case hanging
    /// Monkey tips a glass of water towards the user.
    case pouring
    /// Monkey waits for the user to acknowledge.
    case waiting
    /// Happy dance after the user logs a drink.
    case celebrating
    /// Slides back up out of sight.
    case retreating
}

// ---------------------------------------------------------------------------
// MARK: - UserDefaults keys (daily stats)
// ---------------------------------------------------------------------------

private enum StatsKey {
    static let glassesCount  = "sip.glassesCount"
    static let lastDrinkDate = "sip.lastDrinkDate"
    static let lastDrinkTime = "sip.lastDrinkTime"
    static let streak        = "sip.streak"
    static let lastResetDate = "sip.lastResetDate"
}

// ---------------------------------------------------------------------------
// MARK: - HydrationManager
// ---------------------------------------------------------------------------

final class HydrationManager: ObservableObject {

    // ------------------------------------------------------------------
    // MARK: Singleton
    // ------------------------------------------------------------------

    static let shared = HydrationManager()

    // ------------------------------------------------------------------
    // MARK: Observable state
    // ------------------------------------------------------------------

    /// Current animation / pose state of the mascot.
    @Published private(set) var mascotState: MascotState = .hidden

    /// Number of glasses logged today.
    @Published private(set) var glassesCount: Int = 0

    /// Daily goal, mirrors SettingsStore for convenience.
    var dailyGoal: Int { SettingsStore.shared.dailyGoal }

    /// Reminder interval, mirrors SettingsStore for convenience.
    var reminderInterval: TimeInterval { SettingsStore.shared.reminderInterval }

    /// Timestamp of the last logged drink, `nil` if none today.
    @Published private(set) var lastDrinkTime: Date?

    /// How many consecutive days the user has met their goal.
    @Published private(set) var streak: Int = 0

    /// `true` while reminders are snoozed.
    @Published private(set) var isSnoozed: Bool = false

    /// When the snooze expires. Non-nil only while `isSnoozed == true`.
    @Published private(set) var snoozeUntil: Date?

    // ------------------------------------------------------------------
    // MARK: Private internals
    // ------------------------------------------------------------------

    /// Fires the periodic reminder.
    private var reminderTimer: Timer?

    /// Tracks temporary state-machine work items so they can be cancelled.
    private var pendingWork: [DispatchWorkItem] = []

    // ------------------------------------------------------------------
    // MARK: Init
    // ------------------------------------------------------------------

    private init() {
        loadFromDefaults()
        scheduleMidnightReset()
    }

    // ------------------------------------------------------------------
    // MARK: - Timer management
    // ------------------------------------------------------------------

    /// Start (or restart) the repeating reminder timer.
    func startTimer() {
        stopTimer()

        let interval = max(reminderInterval, 60) // Floor at 60 s for safety.
        reminderTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            self?.triggerReminder()
        }
    }

    /// Cancel the repeating reminder timer.
    func stopTimer() {
        reminderTimer?.invalidate()
        reminderTimer = nil
    }

    // ------------------------------------------------------------------
    // MARK: - Reminder state machine
    // ------------------------------------------------------------------

    /// Called by the timer. Checks active hours + snooze before animating.
    func triggerReminder() {
        // Respect snooze.
        if isSnoozed, let until = snoozeUntil, Date() < until { return }

        // Respect active hours.
        guard SettingsStore.shared.isWithinActiveHours else { return }

        // Cancel any in-flight state transitions.
        cancelPendingWork()

        // Sequence through the reminder animation states.
        // Timeline (seconds from now):
        //   0.0 s → .peeking
        //   1.5 s → .hanging
        //   2.3 s → .pouring
        //   3.5 s → .waiting   (stays here until user acts)

        transition(to: .peeking, after: 0.0)
        transition(to: .hanging, after: 1.5)
        transition(to: .pouring, after: 2.3)
        transition(to: .waiting, after: 3.5)
    }

    // ------------------------------------------------------------------
    // MARK: - User actions
    // ------------------------------------------------------------------

    /// Log one glass of water. Triggers the celebration sequence.
    func logDrink() {
        cancelPendingWork()

        glassesCount += 1
        lastDrinkTime = Date()
        saveToDefaults()

        // Check streak at end of day rather than here (midnight reset does it).

        // Celebration sequence:
        //   0.0 s → .celebrating
        //   1.2 s → .retreating
        //   2.0 s → .hidden, restart timer

        transition(to: .celebrating, after: 0.0)
        transition(to: .retreating,  after: 1.2)

        schedule(after: 2.0) { [weak self] in
            self?.mascotState = .hidden
            self?.startTimer()
        }
    }

    /// Snooze reminders for `minutes` minutes.
    func snooze(minutes: Int) {
        cancelPendingWork()

        isSnoozed  = true
        snoozeUntil = Date().addingTimeInterval(Double(minutes) * 60)

        // Retreat immediately.
        transition(to: .retreating, after: 0.0)
        schedule(after: 0.8) { [weak self] in
            self?.mascotState = .hidden
        }

        // Re-trigger after the snooze window.
        let delay = Double(minutes) * 60
        schedule(after: delay) { [weak self] in
            guard let self else { return }
            self.isSnoozed   = false
            self.snoozeUntil = nil
            self.triggerReminder()
        }
    }

    // ------------------------------------------------------------------
    // MARK: - Daily reset
    // ------------------------------------------------------------------

    /// Resets today's counter, updates the streak, and persists.
    func resetDaily() {
        // Update streak before resetting count.
        let metGoal = glassesCount >= dailyGoal
        streak = metGoal ? streak + 1 : 0

        glassesCount  = 0
        lastDrinkTime = nil
        saveToDefaults()

        scheduleMidnightReset()
    }

    // ------------------------------------------------------------------
    // MARK: - Persistence
    // ------------------------------------------------------------------

    private func saveToDefaults() {
        let ud = UserDefaults.standard
        ud.set(glassesCount,  forKey: StatsKey.glassesCount)
        ud.set(streak,        forKey: StatsKey.streak)
        ud.set(Date(),        forKey: StatsKey.lastDrinkDate)
        if let t = lastDrinkTime {
            ud.set(t, forKey: StatsKey.lastDrinkTime)
        }
    }

    private func loadFromDefaults() {
        let ud    = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())

        // If the saved date is from a previous day, the counter resets.
        if let saved = ud.object(forKey: StatsKey.lastDrinkDate) as? Date,
           Calendar.current.startOfDay(for: saved) == today {
            glassesCount  = ud.integer(forKey: StatsKey.glassesCount)
            lastDrinkTime = ud.object(forKey: StatsKey.lastDrinkTime) as? Date
        } else {
            glassesCount  = 0
            lastDrinkTime = nil
        }

        streak = ud.integer(forKey: StatsKey.streak)
    }

    // ------------------------------------------------------------------
    // MARK: - Midnight scheduling
    // ------------------------------------------------------------------

    private func scheduleMidnightReset() {
        let now       = Date()
        let calendar  = Calendar.current
        guard let midnight = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) else { return }

        let delay = midnight.timeIntervalSince(now)
        schedule(after: delay) { [weak self] in
            self?.resetDaily()
        }
    }

    // ------------------------------------------------------------------
    // MARK: - Internal helpers
    // ------------------------------------------------------------------

    /// Schedules a `MascotState` transition on the main queue after `delay` seconds.
    private func transition(to state: MascotState, after delay: TimeInterval) {
        schedule(after: delay) { [weak self] in
            self?.mascotState = state
        }
    }

    /// Schedules a closure on the main queue after `delay` seconds,
    /// keeping track of the work item so it can be cancelled.
    @discardableResult
    private func schedule(after delay: TimeInterval, work: @escaping () -> Void) -> DispatchWorkItem {
        let item = DispatchWorkItem(block: work)
        pendingWork.append(item)
        DispatchQueue.main.asyncAfter(
            deadline: .now() + delay,
            execute: item
        )
        return item
    }

    /// Cancels all in-flight state-machine work items.
    private func cancelPendingWork() {
        pendingWork.forEach { $0.cancel() }
        pendingWork.removeAll()
    }
}
