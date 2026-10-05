"""Build a bundle-shaped CLI test host with real, sandboxed XPC services."""
from pathlib import Path
import plistlib
import platform
import shutil
import subprocess
import sys

name = sys.argv[1]
if name not in {"ModernCoreTests", "ParserTests", "PreviewLayoutTests"}:
    raise SystemExit("Unknown native test host")
architecture = sys.argv[2] if len(sys.argv) > 2 else platform.machine()
if architecture not in {"arm64", "x86_64"}:
    raise SystemExit("Use arm64 or x86_64")
root = Path(__file__).resolve().parents[1]
app = root / "build/tests" / f"{name}.app"
contents = app / "Contents"
if app.exists():
    shutil.rmtree(app)
(contents / "MacOS").mkdir(parents=True)
(contents / "XPCServices").mkdir()
compiler = ["xcrun", "swiftc", "-O", "-swift-version", "6", "-warnings-as-errors",
            "-target", f"{architecture}-apple-macos15.0",
            "-module-cache-path", str(root / "build/tests/module-cache")]
subprocess.run([*compiler, *map(str, sorted((root / "modern/Core").glob("*.swift"))),
                str(root / "Tests" / f"{name}.swift"), "-o", str(contents / "MacOS" / name)], check=True)
(contents / "Info.plist").write_bytes(plistlib.dumps({
    "CFBundleIdentifier": f"org.masonjames.QLColorCode.Tests.{name}",
    "CFBundleExecutable": name, "CFBundlePackageType": "APPL", "CFBundleVersion": "1", "LSUIElement": True,
}))
service_binary = root / "build/tests/QLColorCodeHighlight"
subprocess.run([*compiler, str(root / "modern/Core/HighlighterProtocol.swift"),
                str(root / "modern/Highlighter/HighlighterMain.swift"), "-o", str(service_binary)], check=True)
for kind in ("Highlight", "Fixture"):
    service = contents / "XPCServices" / f"{kind}.xpc"
    (service / "Contents/MacOS").mkdir(parents=True)
    (service / "Contents/Resources").mkdir()
    shutil.copy2(service_binary, service / "Contents/MacOS/QLColorCodeHighlight")
    library = root / ("modern/Resources/highlight.min.js" if kind == "Highlight" else "Tests/ParserFixture.js")
    shutil.copy2(library, service / "Contents/Resources/highlight.min.js")
    (service / "Contents/Info.plist").write_bytes(plistlib.dumps({
        "CFBundleIdentifier": f"org.masonjames.QLColorCode.Tests.{kind}",
        "CFBundleExecutable": "QLColorCodeHighlight", "CFBundlePackageType": "XPC!",
        "CFBundleVersion": "1", "XPCService": {"ServiceType": "Application"},
    }))
    subprocess.run(["codesign", "--force", "--sign", "-", "--options", "runtime", "--entitlements",
                    str(root / "modern/Highlighter/QLColorCodeHighlight.entitlements"), str(service)], check=True)
subprocess.run(["codesign", "--force", "--sign", "-", "--options", "runtime", str(app)], check=True)
print(f"Test host ({architecture}, macOS 15 target): {app}")
