"""Inspect the artifact actually built, including the embedded extension."""
import hashlib
from pathlib import Path
import plistlib
import subprocess
import sys

app = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("build/modern/Build/Products/Debug/QLColorCode.app")
extension = app / "Contents/PlugIns/QLColorCodePreview.appex"
with (app / "Contents/Info.plist").open("rb") as stream:
    app_info = plistlib.load(stream)
assert app_info["CFBundleIconName"] == "AppIcon"
assert app_info["CFBundleIconFile"] == "AppIcon"
assert (app / "Contents/Resources/AppIcon.icns").is_file()
assert not (extension / "Contents/Resources/AppIcon.icns").exists(), "App icon must not be duplicated in the extension"
assert not (extension / "Contents/Resources/Assets.car").exists(), "App assets must not be duplicated in the extension"
for bundle in (app, extension):
    with (bundle / "Contents/Info.plist").open("rb") as stream:
        info = plistlib.load(stream)
    assert info["LSMinimumSystemVersion"] == "15.0", bundle
    for name in ("highlight.min.js", "highlight-LICENSE", "COPYING"):
        actual = bundle / "Contents/Resources" / name
        source = Path("COPYING") if name == "COPYING" else Path("modern/Resources") / name
        assert hashlib.sha256(actual.read_bytes()).digest() == hashlib.sha256(source.read_bytes()).digest(), actual
    executable = bundle / "Contents/MacOS" / info["CFBundleExecutable"]
    architectures = subprocess.check_output(["lipo", "-archs", str(executable)], text=True).split()
    assert set(architectures) == {"arm64", "x86_64"}, architectures
    signed = subprocess.run(["codesign", "-d", "--entitlements", ":-", str(bundle)], capture_output=True, check=True)
    signature = subprocess.run(["codesign", "-dv", str(bundle)], capture_output=True, text=True, check=True)
    flags = [line for line in signature.stderr.splitlines() if line.startswith("CodeDirectory ") or line.startswith("Signature=")]
    print(f"{bundle.name}: {'; '.join(flags)}")
    if "Signature=adhoc" not in flags:
        assert any("(runtime)" in line for line in flags), "Signed builds must enable hardened runtime"
    entitlements = plistlib.loads(signed.stdout)
    assert entitlements.get("com.apple.security.app-sandbox") is True
    assert bool(entitlements.get("com.apple.security.network.client")) == (bundle == app), entitlements
    assert not any(entitlements.get(key) for key in (
        "com.apple.security.network.server",
        "com.apple.security.cs.allow-jit", "com.apple.security.cs.disable-library-validation",
    )), entitlements
with (extension / "Contents/Info.plist").open("rb") as stream:
    settings = plistlib.load(stream)["NSExtension"]
assert settings["NSExtensionPointIdentifier"] == "com.apple.quicklook.preview"
assert settings["NSExtensionAttributes"]["QLIsDataBasedPreview"] is True
assert not {"public.data", "public.text", "public.movie", "public.mpeg-2-transport-stream", "public.html"}.intersection(settings["NSExtensionAttributes"]["QLSupportedContentTypes"])
subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
print("PASS: app and embedded extension resources, architectures, metadata, sandbox entitlements, signatures")
