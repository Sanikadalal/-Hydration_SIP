// SettingsStore.swift
// Sip – macOS Menu Bar hydration reminder
//
// Observable singleton that persists all user-facing preferences to
// UserDefaults under the "sip.*" key namespace.

import SwiftUI
import Combine

// ---------------------------------------------------------------------------
// MARK: - UserDefaults key constants
// ---------------------------------------------------------------------------

private enum Defaults {
    static let reminderInterval  = "sip.reminderInterval"
    static let dailyGoal         = "sip.dailyGoal"
    static let glassSizeMl       = "sip.glassSizeMl"
    static let mascotTheme       = "sip.mascotTheme"
    static let reduceMotion      = "sip.reduceMotion"
    static let customMessage     = "sip.customMessage"
    static let activeHoursStart  = "sip.activeHoursStart"
    static let activeHoursEnd    = "sip.activeHoursEnd"
}

// ---------------------------------------------------------------------------
// MARK: - SettingsStore
// ---------------------------------------------------------------------------

/// Persists all user preferences to `UserDefaults`.
/// Observed via the `@Observable` macro so SwiftUI views re-render automatically.
final class SettingsStore: ObservableObject {

    // ------------------------------------------------------------------
    // Singleton
    // ------------------------------------------------------------------

    static let shared = SettingsStore()

    // ------------------------------------------------------------------
    // Stored properties (backed by UserDefaults)
    // ------------------------------------------------------------------

    /// How often (seconds) to show a reminder. Default: 30 minutes.
    @Published var reminderInterval: TimeInterval {
        didSet { UserDefaults.standard.set(reminderInterval, forKey: Defaults.reminderInterval) }
    }

    /// Target number of glasses per day.
    @Published var dailyGoal: Int {
        didSet { UserDefaults.standard.set(dailyGoal, forKey: Defaults.dailyGoal) }
    }

    /// Volume of one glass in millilitres.
    @Published var glassSizeMl: Int {
        didSet { UserDefaults.standard.set(glassSizeMl, forKey: Defaults.glassSizeMl) }
    }

    /// Visual theme key for the mascot (e.g. "monkey").
    @Published var mascotTheme: String {
        didSet { UserDefaults.standard.set(mascotTheme, forKey: Defaults.mascotTheme) }
    }

    /// When `true` the app replaces spring physics with simpler fades/slides.
    @Published var reduceMotion: Bool {
        didSet { UserDefaults.standard.set(reduceMotion, forKey: Defaults.reduceMotion) }
    }

    /// Reminder message shown in the mascot bubble.
    @Published var customMessage: String {
        didSet { UserDefaults.standard.set(customMessage, forKey: Defaults.customMessage) }
    }

    /// First hour of the active-hours window (24-hour clock). Default: 9 am.
    @Published var activeHoursStart: Int {
        didSet { UserDefaults.standard.set(activeHoursStart, forKey: Defaults.activeHoursStart) }
    }

    /// Last hour of the active-hours window (24-hour clock). Default: 9 pm.
    @Published var activeHoursEnd: Int {
        didSet { UserDefaults.standard.set(activeHoursEnd, forKey: Defaults.activeHoursEnd) }
    }

    // ------------------------------------------------------------------
    // Init – read persisted values, fall back to sensible defaults
    // ------------------------------------------------------------------

    private init() {
        let ud = UserDefaults.standard

        // Register factory defaults so `object(forKey:)` always returns a value
        // on first launch.
        ud.register(defaults: [
            Defaults.reminderInterval : 1_800.0,   // 30 min
            Defaults.dailyGoal        : 8,
            Defaults.glassSizeMl      : 250,
            Defaults.mascotTheme      : "monkey",
            Defaults.reduceMotion     : false,
            Defaults.customMessage    : "Hehe… paani pilo 💧",
            Defaults.activeHoursStart : 9,
            Defaults.activeHoursEnd   : 21,
        ])

        reminderInterval  = ud.double(forKey: Defaults.reminderInterval)
        dailyGoal         = ud.integer(forKey: Defaults.dailyGoal)
        glassSizeMl       = ud.integer(forKey: Defaults.glassSizeMl)
        mascotTheme       = ud.string(forKey: Defaults.mascotTheme)  ?? "monkey"
        reduceMotion      = ud.bool(forKey: Defaults.reduceMotion)
        customMessage     = ud.string(forKey: Defaults.customMessage) ?? "Hehe… paani pilo 💧"
        activeHoursStart  = ud.integer(forKey: Defaults.activeHoursStart)
        activeHoursEnd    = ud.integer(forKey: Defaults.activeHoursEnd)
    }

    // ------------------------------------------------------------------
    // MARK: - Helpers
    // ------------------------------------------------------------------

    /// Returns `true` if the current wall-clock hour falls within active hours.
    var isWithinActiveHours: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= activeHoursStart && hour < activeHoursEnd
    }

    /// Human-readable total target volume for today.
    var totalTargetMl: Int { dailyGoal * glassSizeMl }

    /// Resets every setting back to its factory default.
    func resetToDefaults() {
        reminderInterval  = 1_800.0
        dailyGoal         = 8
        glassSizeMl       = 250
        mascotTheme       = "monkey"
        reduceMotion      = false
        customMessage     = "Hehe… paani pilo 💧"
        activeHoursStart  = 9
        activeHoursEnd    = 21
    }
}
