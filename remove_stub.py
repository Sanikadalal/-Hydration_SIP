file_path = 'Sources/NotchWindowController.swift'
with open(file_path, 'r') as f:
    content = f.read()

import re
content = re.sub(r'// Thin SwiftUI wrapper that reads HydrationManager and renders MascotView.*', '', content, flags=re.DOTALL)
with open(file_path, 'w') as f:
    f.write(content)
