#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v xcodegen >/dev/null || { echo "Install XcodeGen to generate the modern Xcode project." >&2; exit 1; }
xcodegen generate --spec modern/project.yml
xcodebuild -project modern/QLColorCodeModern.xcodeproj -scheme QLColorCode \
  -configuration Debug -derivedDataPath build/modern \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO build "$@"
python3 scripts/verify-bundle.py
