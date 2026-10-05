#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/build-test-host.py PreviewLayoutTests "${1:-$(uname -m)}"
python3 - <<'PYTEST'
import subprocess
subprocess.run(["build/tests/PreviewLayoutTests.app/Contents/MacOS/PreviewLayoutTests"], check=True, timeout=30)
PYTEST
