#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/build-test-helper.sh
xcrun swiftc -swift-version 6 -warnings-as-errors -module-cache-path build/tests/module-cache \
  modern/Core/*.swift Tests/PreviewLayoutTests.swift -o build/tests/preview-layout-tests
python3 - <<'PY'
import subprocess
subprocess.run(["build/tests/preview-layout-tests"], check=True, timeout=30)
PY
