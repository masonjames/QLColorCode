#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/tests/Parser/Contents/Helpers build/tests/Parser/Contents/Resources
xcrun swiftc -swift-version 6 -warnings-as-errors -module-cache-path build/tests/module-cache \
  modern/Core/HighlightRequest.swift modern/Highlighter/HighlighterMain.swift \
  -o build/tests/Parser/Contents/Helpers/QLColorCodeHighlight
cp modern/Resources/highlight.min.js build/tests/Parser/Contents/Resources/
