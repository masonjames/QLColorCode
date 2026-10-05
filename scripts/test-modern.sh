#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 Tests/test_legacy_reader.py
python3 scripts/verify-source.py
python3 scripts/build-test-host.py ModernCoreTests "${1:-$(uname -m)}"
python3 scripts/build-test-host.py ParserTests "${1:-$(uname -m)}"
python3 - <<'PYTEST'
import subprocess
subprocess.run(["build/tests/ModernCoreTests.app/Contents/MacOS/ModernCoreTests"], check=True, timeout=30)
subprocess.run(["build/tests/ParserTests.app/Contents/MacOS/ParserTests"], check=True, timeout=45)
subprocess.run(["python3", "Tests/test_parser_orphan.py"], check=True, timeout=10)
PYTEST
