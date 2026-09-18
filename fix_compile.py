import re
import os

app_delegate = 'Sources/AppDelegate.swift'
with open(app_delegate, 'r') as f:
    content = f.read()

content = re.sub(r'let mbc = MenuBarController\(\s*hydrationManager: hydrationManager,\s*notchWindowController: nwc\s*\)',
                 'let mbc = MenuBarController(\n            hydrationManager: hydrationManager\n        )', content)
content = re.sub(r'// -+\n// MARK: - MenuBarController.*', '', content, flags=re.DOTALL)

with open(app_delegate, 'w') as f:
    f.write(content)

hyd_manager = 'Sources/HydrationManager.swift'
with open(hyd_manager, 'r') as f:
    hm = f.read()

hm = hm.replace('import Observation', 'import Combine')
hm = hm.replace('@Observable\nfinal class HydrationManager', 'final class HydrationManager: ObservableObject')
hm = hm.replace('private(set) var mascotState', '@Published private(set) var mascotState')
hm = hm.replace('private(set) var glassesCount', '@Published private(set) var glassesCount')
hm = hm.replace('private(set) var lastDrinkTime', '@Published private(set) var lastDrinkTime')
hm = hm.replace('private(set) var streak', '@Published private(set) var streak')
hm = hm.replace('private(set) var isSnoozed', '@Published private(set) var isSnoozed')
hm = hm.replace('private(set) var snoozeUntil', '@Published private(set) var snoozeUntil')

with open(hyd_manager, 'w') as f:
    f.write(hm)

settings_store = 'Sources/SettingsStore.swift'
if os.path.exists(settings_store):
    with open(settings_store, 'r') as f:
        ss = f.read()
    ss = ss.replace('import Observation', 'import Combine')
    ss = ss.replace('@Observable\nfinal class SettingsStore', 'final class SettingsStore: ObservableObject')
    # Since we are using @AppStorage usually it doesn't need @Published, but if they used standard properties we might.
    with open(settings_store, 'w') as f:
        f.write(ss)

print("Fixes applied.")
