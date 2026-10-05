#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/tests
python3 Tests/test_legacy_reader.py
python3 scripts/verify-source.py
xcrun swiftc -swift-version 6 -module-cache-path build/tests/module-cache \
  modern/Core/*.swift Tests/ModernCoreTests.swift -o build/tests/modern-core-tests
# Bound the entire test process as well as checking normal corpus timings.
python3 - <<'PY'
import subprocess
subprocess.run(["build/tests/modern-core-tests"], check=True, timeout=30)
PY
