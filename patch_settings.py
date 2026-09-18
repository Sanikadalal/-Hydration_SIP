import re
file_path = 'Sources/SettingsView.swift'
with open(file_path, 'r') as f:
    content = f.read()

content = content.replace('hydrationManager.rescheduleTimer()', 'hydrationManager.startTimer()')
content = re.sub(r'\.onChange\(of:\s*([a-zA-Z0-9_]+)\)\s*\{\s*\_,\s*\_?\s*in', r'.onChange(of: \1) { _ in', content)

# Check if there are other new onChange syntaxes
content = re.sub(r'\.onChange\(of:\s*([a-zA-Z0-9_]+)\)\s*\{\s*\_,\s*([a-zA-Z0-9_]+)\s*in', r'.onChange(of: \1) { \2 in', content)

with open(file_path, 'w') as f:
    f.write(content)
