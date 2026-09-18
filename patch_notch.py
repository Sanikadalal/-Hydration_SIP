file_path = 'Sources/NotchContentView.swift'
with open(file_path, 'r') as f:
    content = f.read()

content = content.replace('hydrationManager.dailyGoalGlasses', 'hydrationManager.dailyGoal')
content = content.replace('hydrationManager.hydrate(amount: hydrationManager.glassSizeMl)', 'hydrationManager.logDrink()')
content = content.replace('hydrationManager.snooze()', 'hydrationManager.snooze(minutes: 10)')

with open(file_path, 'w') as f:
    f.write(content)
