"""Inspect the artifact actually built, including the embedded extension."""
import hashlib
from pathlib import Path
import plistlib
import subprocess
import sys

if sys.flags.optimize:
    raise SystemExit("Bundle verification requires Python assertions; do not use -O or PYTHONOPTIMIZE.")

def verify_executable(executable):
    architectures = subprocess.check_output(["lipo", "-archs", str(executable)], text=True).split()
    assert set(architectures) == {"arm64", "x86_64"}, architectures
    for architecture in architectures:
        load_commands = subprocess.check_output(["xcrun", "vtool", "-show-build", "-arch", architecture, str(executable)], text=True)
        minimum_versions = [line.split()[1] for line in load_commands.splitlines() if line.strip().startswith("minos ")]
        assert minimum_versions == ["15.0"], (executable, architecture, minimum_versions)


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
    verify_executable(executable)
    signed = subprocess.run(["codesign", "-d", "--entitlements", "-", "--xml", str(bundle)], capture_output=True, check=True)
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
helper = extension / "Contents/Helpers/QLColorCodeHighlight"
verify_executable(helper)
helper_entitlements = plistlib.loads(subprocess.check_output(
    ["codesign", "-d", "--entitlements", "-", "--xml", str(helper)], stderr=subprocess.DEVNULL))
assert helper_entitlements == {"com.apple.security.app-sandbox": True, "com.apple.security.inherit": True}, helper_entitlements
subprocess.run(["codesign", "--verify", "--strict", str(helper)], check=True)
with (extension / "Contents/Info.plist").open("rb") as stream:
    settings = plistlib.load(stream)["NSExtension"]
assert settings["NSExtensionPointIdentifier"] == "com.apple.quicklook.preview"
assert settings["NSExtensionAttributes"]["QLIsDataBasedPreview"] is True
assert not {"public.data", "public.text", "public.movie", "public.mpeg-2-transport-stream", "public.html"}.intersection(settings["NSExtensionAttributes"]["QLSupportedContentTypes"])
subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
print("PASS: app, parser helper and embedded extension resources, architectures, metadata, sandbox entitlements, signatures")
