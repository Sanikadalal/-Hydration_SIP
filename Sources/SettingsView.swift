import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var hydrationManager: HydrationManager
    @ObservedObject var settings = SettingsStore.shared
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section("Hydration") {
                Picker("Reminder every", selection: Binding(
                    get: { Int(settings.reminderInterval / 60) },
                    set: { settings.reminderInterval = TimeInterval($0 * 60) }
                )) {
                    Text("15 min").tag(15)
                    Text("30 min").tag(30)
                    Text("45 min").tag(45)
                    Text("60 min").tag(60)
                }
                .onChange(of: settings.reminderInterval) { _ in
                    hydrationManager.startTimer()
                }

                Stepper("Daily goal: \(settings.dailyGoal) glasses", value: $settings.dailyGoal, in: 4...16)

                Picker("Glass size", selection: $settings.glassSizeMl) {
                    Text("Small (150 ml)").tag(150)
                    Text("Medium (200 ml)").tag(200)
                    Text("Standard (250 ml)").tag(250)
                    Text("Large (350 ml)").tag(350)
                }
            }

            Section("Schedule") {
                Picker("Active from", selection: $settings.activeHoursStart) {
                    ForEach(0..<24) { hour in
                        Text("\(hour):00").tag(hour)
                    }
                }
                Picker("Active until", selection: $settings.activeHoursEnd) {
                    ForEach(0..<24) { hour in
                        Text("\(hour):00").tag(hour)
                    }
                }
            }

            Section("Mascot") {
                Picker("Theme", selection: $settings.mascotTheme) {
                    Text("Monkey 🐵").tag("monkey")
                }
                TextField("Custom Message", text: $settings.customMessage)
            }

            Section("Accessibility") {
                Toggle("Reduce motion", isOn: $settings.reduceMotion)
            }

            Section("App") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { val in
                        if val {
                            try? SMAppService.mainApp.register()
                        } else {
                            try? SMAppService.mainApp.unregister()
                        }
                    }

                Button("Reset today's count") {
                    hydrationManager.resetDaily()
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 450)
    }
}

#Preview {
    SettingsView()
        .environmentObject(HydrationManager.shared)
}
