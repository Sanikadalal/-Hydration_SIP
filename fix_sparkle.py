file_path = 'Sources/SparkleView.swift'
with open(file_path, 'r') as f:
    content = f.read()

import re
content = re.sub(r'\.onChange\(of:\s*triggered\)\s*\{\s*\_,\s*isOn\s*in', '.onChange(of: triggered) { isOn in', content)

with open(file_path, 'w') as f:
    f.write(content)
