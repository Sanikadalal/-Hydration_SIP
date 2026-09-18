import re

# Fix Previews
files_with_previews = ['Sources/NotchContentView.swift', 'Sources/SettingsView.swift']
for file in files_with_previews:
    with open(file, 'r') as f:
        content = f.read()
    content = content.replace('HydrationManager()', 'HydrationManager.shared')
    with open(file, 'w') as f:
        f.write(content)

# Fix onChange
mascot_file = 'Sources/MascotView.swift'
with open(mascot_file, 'r') as f:
    content = f.read()
content = re.sub(r'\.onChange\(of:\s*isActive\)\s*\{\s*\_,\s*active\s*in', '.onChange(of: isActive) { active in', content)
content = re.sub(r'\.onChange\(of:\s*state\)\s*\{\s*\_,\s*newState\s*in', '.onChange(of: state) { newState in', content)
with open(mascot_file, 'w') as f:
    f.write(content)

print("Fixes applied.")
