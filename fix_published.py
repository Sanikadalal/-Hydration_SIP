file_path = 'Sources/SettingsStore.swift'
with open(file_path, 'r') as f:
    content = f.read()

content = content.replace('@Published var isWithinActiveHours', 'var isWithinActiveHours')
content = content.replace('@Published var totalTargetMl', 'var totalTargetMl')
with open(file_path, 'w') as f:
    f.write(content)
