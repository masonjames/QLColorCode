#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Build the checked-in project. XcodeGen is needed only when project.yml changes.
xcodebuild -project modern/QLColorCodeModern.xcodeproj -scheme QLColorCode \
  -configuration Debug -derivedDataPath build/modern \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO build "$@"
python3 scripts/verify-bundle.py
