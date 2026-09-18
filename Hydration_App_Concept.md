# 🐵 NotchMascot Hydration App Concept

A playful, native macOS hydration reminder that lives in your notch.

````carousel
![Notch extending as a portal with monkey peeking](/Users/sanika/Documents/Sanika/Projects/sip/assets/notch_peek_concept_1789583968268.jpg)
<!-- slide -->
![Monkey hanging from notch pouring water](/Users/sanika/Documents/Sanika/Projects/sip/assets/monkey_pour_concept_1789583983076.jpg)
<!-- slide -->
![Monkey celebrating after hydration](/Users/sanika/Documents/Sanika/Projects/sip/assets/monkey_celebrate_concept_1789583995885.jpg)
````

## 🎬 Signature Interaction

1. **The Peeking Phase**: The Mac's notch seamlessly extends downward, morphing into a tiny portal. A cute 3D monkey peeks out.
2. **The Swing & Pour**: The monkey grabs the edge, swinging out with a satisfying spring-based motion. It magically produces a tiny jug and pours water into a transparent glass.
3. **The Nudge**: A subtle speech bubble appears: *"Hehe… paani pilo 💧"* (Customizable).
4. **The Celebration**: Once the user clicks **Drank 💧**, the monkey does a little jump, sparkles appear, and it happily climbs back into the notch, which retracts smoothly.

## 🎨 Visual Details & Physics

- **Aesthetic**: Pixar-level 3D charm mixed with premium macOS translucency. The character features soft geometries, slightly oversized head, and soft materials.
- **Physical Attachment**: The notch stretches slightly to accommodate the monkey’s weight.
- **Physics**: Uses natural easing, spring-based swinging (with subtle body swaying), and realistic water droplet simulation.

> [!TIP]
> **Minimal Intrusion:** The interaction is designed to be a "5-second visit." It lives tightly around the menu bar area and avoids obstructing the user's active workspace.

## ⚙️ Technical Architecture (macOS Native)
- **Frameworks**: SwiftUI / AppKit, with SceneKit or Metal for rendering the high-quality 3D mascot.
- **State Machine**: The mascot's states (Idle, Peeking, Pouring, Celebrating, Retreating) will be decoupled from the actual character models.
- **Extensibility**: Laying the foundation for future mascots (Cats, Penguins, Blobs) using a unified animation & physics controller.

```mermaid
stateDiagram-v2
    [*] --> Hidden
    Hidden --> Peeking : Hydration Overdue
    Peeking --> Hanging : Pulls down from notch
    Hanging --> Pouring : Pours water
    Pouring --> Waiting : Displays message/buttons
    Waiting --> Celebrating : User clicks "Drank"
    Waiting --> Retreating : User clicks "Snooze"
    Celebrating --> Retreating : Animation finishes
    Retreating --> Hidden : Retracts into notch
```
