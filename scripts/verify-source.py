"""Verify the exact vendored grammar and license bytes without network access."""
import hashlib
from pathlib import Path

expected = {
    "highlight.min.js": "8ab71eb09c51f501e5e25157d9cff100e46cc29bcbfc744d0b746d451fca7f53",
    "highlight-LICENSE": "6c081431591d9df696c82dc598fe1423765b8a299b200ed00b281afd0f64c490",
}
for name, digest in expected.items():
    actual = hashlib.sha256((Path("modern/Resources") / name).read_bytes()).hexdigest()
    if actual != digest:
        raise SystemExit(f"Resource checksum mismatch: {name}")
print("PASS: vendored resource checksums")
