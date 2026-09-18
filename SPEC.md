# 🫧 Sip – Product Specification

> **Tagline:** *"Hehe… paani pilo 💧"*
> The most delightful hydration reminder for macOS.

---

## 1. Product Vision

Sip is a **macOS-native notch companion** that gently reminds you to drink water through an animated mascot that peeks out of your Mac's notch. It's designed to be a **5-second interaction** — joyful, non-intrusive, and instantly dismissible.

---

## 2. Core User Flow

```
[Background Timer] 
    │
    ▼
Notch extends softly ──▶ Monkey peeks with big eyes
    │
    ▼
Monkey hangs from notch, produces water glass
    │
    ▼
Speech bubble: "Hehe… paani pilo 💧"
    │
    ├──[Drank 💧]──▶ Celebration + sparkles + streak++  ──▶ Retract
    └──[Snooze 😴]──▶ Sad wave ──▶ Retract (reminder in N min)
```

---

## 3. Features

### 3.1 Core

| Feature | Description |
|---|---|
| Notch UI | Transparent panel anchored perfectly to the notch area |
| Mascot Animation | Smooth spring-physics monkey with peek → hang → pour states |
| Water Tracking | Track glasses drunk per day (default goal: 8) |
| Reminder Interval | Configurable 15min / 30min / 45min / 60min / custom |
| Snooze | 5 / 10 / 15 minute snooze options |
| Streak | Daily and weekly streak tracker |

### 3.2 Menu Bar

| Feature | Description |
|---|---|
| Progress Ring | Circular progress icon showing daily hydration % |
| Quick Log | Click to log a glass without waiting for reminder |
| Today's Stats | Glasses drunk / goal, time since last drink |
| Open Settings | Quick access to preferences |

### 3.3 Settings

| Setting | Default | Options |
|---|---|---|
| Reminder Interval | 30 min | 15 / 30 / 45 / 60 / Custom |
| Daily Goal | 8 glasses | 4–16 |
| Glass Size | 250ml | 150 / 200 / 250 / 350ml |
| Mascot Theme | Monkey 🐵 | Monkey / Blob / Cat (future) |
| Reminder Sound | Subtle | None / Subtle / Playful |
| Reduce Motion | Off | On / Off |
| Launch at Login | On | On / Off |
| Active Hours | 9am–9pm | Configurable range |
| Message | "Hehe… paani pilo 💧" | Customizable |

---

## 4. Mascot Design

### States

| State | Visuals | Duration |
|---|---|---|
| `hidden` | Nothing visible | — |
| `peeking` | Top of head + eyes peeking above notch edge | 1.5s |
| `hanging` | Full mascot drops down, grips notch edges | 0.8s |
| `pouring` | Arms extend, glass tilts, water droplets animate | 1.2s |
| `waiting` | Idle bobbing, buttons visible | Until user acts |
| `celebrating` | Jump + sparkles + spin | 1.2s |
| `retreating` | Climbs back up, notch retracts | 0.8s |

### Visual Style
- **2D SwiftUI vector** (not SceneKit) for performance & smooth 60fps
- Soft rounded shapes, slightly oversized head
- Color palette: warm browns + cream (monkey), with water in `#4FC3F7`
- Eyes: expressive, animatable (squint when happy, wide when peeking)
- Mouth: customizable speech bubble with rounded tail

---

## 5. Animation Spec

### Spring Parameters
```swift
// Primary transitions
.spring(response: 0.55, dampingFraction: 0.72)

// Bouncy mascot drops
.spring(response: 0.45, dampingFraction: 0.60)

// Notch extension
.spring(response: 0.40, dampingFraction: 0.85)

// Celebration
.spring(response: 0.35, dampingFraction: 0.50)
```

### Notch Extension
- Normal notch: `~126 × 37pt` (MacBook Pro 14")
- Extended (peeking): `~126 × 90pt`
- Extended (hanging): `~200 × 160pt`
- Transition: spring + blur crossfade

### Water Drop Animation
- 3–5 teardrop shapes
- Fall with gravity (easeIn y offset)
- Splash at bottom (scale burst + fade)
- Staggered 80ms between drops

---

## 6. Window & Display

### NSPanel Configuration
```swift
NSPanel(
    contentRect: notchRect,
    styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
    backing: .buffered,
    defer: false
)
panel.level = .statusBar + 1
panel.backgroundColor = .clear
panel.isOpaque = false
panel.hasShadow = false
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
```

### Positioning
- Query notch bounds via `NSScreen.main?.safeAreaInsets`
- Horizontally center on screen
- Y position: `screen.frame.maxY - statusBarHeight`
- Recalculate on `NSApplicationDidChangeScreenParametersNotification`

---

## 7. Persistence Schema

```swift
// UserDefaults keys
"sip.reminderInterval"    // TimeInterval (seconds)
"sip.dailyGoal"           // Int (glasses)
"sip.glassSizeMl"         // Int (ml)
"sip.mascotTheme"         // String ("monkey" | "blob")
"sip.activeHoursStart"    // Int (hour, 0-23)
"sip.activeHoursEnd"      // Int (hour, 0-23)
"sip.customMessage"       // String
"sip.reduceMotion"        // Bool
"sip.launchAtLogin"       // Bool (via SMAppService)

// Daily log (resets at midnight)
"sip.log.YYYY-MM-DD"      // [Date] (timestamps of each drink)
```

---

## 8. Accessibility

- **Reduce Motion**: Skip to final state immediately, no animations
- **VoiceOver**: Panel announced as "Hydration reminder — Sip app"
- **Keyboard**: Space/Return = Drank, Escape = Snooze

---

## 9. Non-Goals (v1)

- ❌ iPhone companion app
- ❌ iCloud sync
- ❌ 3D SceneKit rendering (too heavy, use 2D SwiftUI)
- ❌ Apple Watch support
- ❌ Calendar integration

---

## 10. Success Metrics

- Cold launch → first reminder animation: **< 500ms**
- Animation frame rate: **60fps sustained**
- Memory footprint: **< 30MB**
- App size: **< 5MB**
