#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/build-test-helper.sh
python3 Tests/test_legacy_reader.py
python3 scripts/verify-source.py
xcrun swiftc -swift-version 6 -module-cache-path build/tests/module-cache \
  modern/Core/*.swift Tests/ModernCoreTests.swift -o build/tests/modern-core-tests
xcrun clang -Wall -Wextra -Werror Tests/parser-probe.c -o build/tests/parser-probe
xcrun swiftc -swift-version 6 -warnings-as-errors -module-cache-path build/tests/module-cache \
  modern/Core/*.swift Tests/ParserTests.swift -o build/tests/parser-tests
# Bound the entire test process as well as checking normal corpus timings.
python3 - <<'PY'
import subprocess
subprocess.run(["build/tests/modern-core-tests"], check=True, timeout=30)
subprocess.run(["build/tests/parser-tests"], check=True, timeout=10)
subprocess.run(["python3", "Tests/test_parser_orphan.py"], check=True, timeout=10)
PY
