import re

file_path = 'Sources/MenuBarController.swift'
with open(file_path, 'r') as f:
    content = f.read()

# Replace property accesses
content = content.replace('hydrationManager.progressFraction', 'Double(hydrationManager.glassesCount) / Double(max(1, hydrationManager.dailyGoal))')
content = content.replace('hydrationManager.hydrate(amount: hydrationManager.glassSizeMl)', 'hydrationManager.logDrink()')
content = content.replace('hydrationManager.lastDrinkDate', 'hydrationManager.lastDrinkTime')
content = content.replace('hydrationManager.dailyGoalGlasses', 'hydrationManager.dailyGoal')
# Also glassSizeMl inside logSip if any (already handled above)

with open(file_path, 'w') as f:
    f.write(content)
