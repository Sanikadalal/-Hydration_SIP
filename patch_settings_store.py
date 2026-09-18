import re
file_path = 'Sources/SettingsView.swift'
with open(file_path, 'r') as f:
    content = f.read()

# Replace AppStorage with direct use of SettingsStore.shared
# First, remove the AppStorage declarations
content = re.sub(r'@AppStorage\([^)]+\)\s+private var \w+:\s*[A-Za-z]+\s*=\s*[^;\n]+', '', content)

# Inject SettingsStore as ObservedObject (or we can just use @ObservedObject var settings = SettingsStore.shared)
content = content.replace('@EnvironmentObject var hydrationManager: HydrationManager', 
                          '@EnvironmentObject var hydrationManager: HydrationManager\n    @ObservedObject var settings = SettingsStore.shared')

# Replace variables with settings.var
content = content.replace('$reminderInterval', 'Binding(get: { Int(settings.reminderInterval / 60) }, set: { settings.reminderInterval = TimeInterval($0 * 60) })')
content = content.replace('$dailyGoalGlasses', '$settings.dailyGoal')
content = content.replace('$glassSizeMl', '$settings.glassSizeMl')
content = content.replace('$activeStartHour', '$settings.activeHoursStart')
content = content.replace('$activeEndHour', '$settings.activeHoursEnd')
content = content.replace('$mascotTheme', '$settings.mascotTheme')
content = content.replace('$customMessage', '$settings.customMessage')
content = content.replace('$reduceMotion', '$settings.reduceMotion')

content = content.replace('dailyGoalGlasses', 'settings.dailyGoal')
content = content.replace('reminderInterval', 'settings.reminderInterval')
content = content.replace('activeStartHour', 'settings.activeHoursStart')
content = content.replace('activeEndHour', 'settings.activeHoursEnd')

content = content.replace('.onChange(of: settings.reminderInterval) { _ in\n                    hydrationManager.startTimer()\n                }', '')
content = content.replace('.onChange(of: settings.dailyGoal) { val in\n                    hydrationManager.settings.dailyGoal = val\n                }', '')
content = content.replace('.onChange(of: settings.dailyGoal) { val in\n                    hydrationManager.dailyGoalGlasses = val\n                }', '')

with open(file_path, 'w') as f:
    f.write(content)

# We must add @Published to SettingsStore properties
store_path = 'Sources/SettingsStore.swift'
with open(store_path, 'r') as f:
    ss = f.read()

ss = re.sub(r'(\s+)var ([a-zA-Z0-9_]+):', r'\1@Published var \2:', ss)
with open(store_path, 'w') as f:
    f.write(ss)

