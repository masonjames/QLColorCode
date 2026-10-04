#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/tests
python3 Tests/test_legacy_reader.py
python3 - <<'PY'
import hashlib
from pathlib import Path
expected = {
    "highlight.min.js": "8ab71eb09c51f501e5e25157d9cff100e46cc29bcbfc744d0b746d451fca7f53",
    "highlight-LICENSE": "6c081431591d9df696c82dc598fe1423765b8a299b200ed00b281afd0f64c490",
}
for name, digest in expected.items():
    assert hashlib.sha256((Path("modern/Resources") / name).read_bytes()).hexdigest() == digest, name
print("PASS: vendored resource checksums")
PY
xcrun swiftc -swift-version 6 -module-cache-path build/tests/module-cache \
  modern/Core/*.swift Tests/ModernCoreTests.swift -o build/tests/modern-core-tests
# Bound the entire test process as well as checking normal corpus timings.
python3 - <<'PY'
import subprocess
subprocess.run(["build/tests/modern-core-tests"], check=True, timeout=30)
PY
