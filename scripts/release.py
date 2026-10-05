"""Local Dagger checks and native macOS DMGs. Nothing publishes automatically."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[1]
REPOSITORY = "masonjames/QLColorCode"
DAGGER_VERSION = "v0.21.10"
DAGGER_IMAGE = "python:3.14-slim-bookworm@sha256:c8137f4c460908c8763f281c8f22c431eb5c538514ba9553fc3a89c06b7cfb88"
TEAM = "J5K2J3K4H7"
GATES = {"parser_deadline", "platform_qualification", "accessibility_and_install"}
BETA_GATES = {"parser_deadline", "local_runtime_and_install"}
LSREGISTER = "/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"


def run(*args, cwd=ROOT, timeout=900, merged=False):
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True, timeout=timeout)
    if result.returncode:
        raise subprocess.CalledProcessError(result.returncode, args, result.stdout, result.stderr)
    return (result.stdout + (result.stderr if merged else "")).strip()


def sha256(path):
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def source_digest(directory):
    files = {str(path.relative_to(directory)): sha256(path) for path in sorted(directory.rglob("*")) if path.is_file()}
    return hashlib.sha256(json.dumps(files, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def tag_version(tag):
    match = re.fullmatch(r"v([0-9]+\.[0-9]+\.[0-9]+)(?:-(?:alpha|beta|rc)\.[1-9][0-9]*)?", tag)
    if not match:
        raise ValueError("Use vX.Y.Z or vX.Y.Z-beta.N (alpha/rc also supported).")
    return match[1]


def require_ready(readiness, tag):
    tag_version(tag)
    if set(readiness) != {"stable", "beta"}:
        raise ValueError("Readiness must keep separate stable and beta evidence.")
    prerelease = "-" in tag
    gates = readiness["beta" if prerelease else "stable"]
    required = BETA_GATES if prerelease else GATES
    if set(gates) != required or any(gate.get("passed") is not True or not gate.get("evidence", "").strip() for gate in gates.values()):
        raise ValueError("Public release blocked: complete docs/release-readiness.json with reviewed evidence first.")


def cask(tag, digest):
    tag_version(tag)
    if not re.fullmatch(r"[0-9a-f]{64}", digest):
        raise ValueError("Invalid DMG SHA256")
    return f'''cask "masonjames-qlcolorcode" do
  version "{tag[1:]}"
  sha256 "{digest}"

  url "https://github.com/{REPOSITORY}/releases/download/v#{{version}}/QLColorCode-#{{version}}.dmg"
  name "QLColorCode"
  desc "Syntax-colored Quick Look previews for source code"
  homepage "https://github.com/{REPOSITORY}"

  depends_on macos: :sequoia

  app "QLColorCode.app"

  caveats <<~EOS
    Open QLColorCode once, then enable QLColorCode Preview in System Settings.
    This is Mason James's maintained fork, not the old Homebrew qlcolorcode cask.
  EOS
end
'''


def portable_checks(source, log):
    version = run("dagger", "version")
    if version.split()[1] != DAGGER_VERSION:
        raise ValueError(f"Use Dagger {DAGGER_VERSION}; found {version}")
    endpoint = run("docker", "context", "inspect", "--format", "{{ .Endpoints.docker.Host }}")
    if not endpoint.startswith("unix://"):
        raise ValueError("This release pipeline requires a local Docker engine.")
    # This stage imports an explicit public source allowlist, never host credentials.
    env = {key: value for key, value in os.environ.items() if not key.startswith(("OTEL_", "DAGGER_", "_EXPERIMENTAL_DAGGER_"))}
    env.pop("DOCKER_CONTEXT", None)
    env.pop("DOCKER_AUTH_CONFIG", None)
    env["DOCKER_HOST"] = endpoint
    with tempfile.TemporaryDirectory(prefix="qlcolorcode-docker-") as directory:
        Path(directory, "config.json").write_text('{"auths":{}}\n')
        env["DOCKER_CONFIG"] = directory
        command = ["dagger", "--progress", "plain", "run", sys.executable, "scripts/verify-portable.py"]
        guard = Path(os.environ.get("DAGGER_CI_HOST_GUARD", "/usr/local/libexec/dagger-ci-host-guard"))
        if guard.is_file():
            command = [str(guard), "--", *command]
        with log.open("w") as stream:
            subprocess.run(command, cwd=source, env=env, stdout=stream, stderr=subprocess.STDOUT, check=True, timeout=900)
    return version


def snapshot(destination):
    """Copy only Git-known source, including uncommitted changes for rehearsals."""
    files = run("git", "ls-files", "--cached", "--others", "--exclude-standard", "-z").split("\0")
    for name in filter(None, files):
        if not (name.startswith(("modern/", "scripts/", "Tests/", "examples/")) or name in ("COPYING", "src/colorize.sh", "docs/release-readiness.json")):
            continue  # Historical submodules are not inputs to the modern build.
        source = ROOT / name
        if not source.exists():  # A deleted tracked file is absent in a rehearsal.
            continue
        if source.is_symlink() or not source.is_file():
            raise ValueError(f"Unexpected source entry: {name}")
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)


def signed_release(path, *, app=False):
    signature = run("codesign", "-dv", "--verbose=4", str(path), merged=True)
    if f"TeamIdentifier={TEAM}" not in signature or "Authority=Developer ID Application:" not in signature or "Timestamp=" not in signature:
        raise ValueError(f"Missing expected Developer ID, team or secure timestamp: {path.name}")
    run("codesign", "--verify", "--strict", "--deep", str(path))
    if app:
        for bundle in (path, path / "Contents/PlugIns/QLColorCodePreview.appex",
                       path / "Contents/XPCServices/QLColorCodeHighlight.xpc",
                       path / "Contents/PlugIns/QLColorCodePreview.appex/Contents/XPCServices/QLColorCodeHighlight.xpc"):
            details = run("codesign", "-dv", "--verbose=4", str(bundle), merged=True)
            if f"TeamIdentifier={TEAM}" not in details or "Authority=Developer ID Application:" not in details or "Timestamp=" not in details or "(runtime)" not in details:
                raise ValueError("All executables need the expected team, secure timestamp and hardened runtime.")
            entitlements = subprocess.check_output(["codesign", "-d", "--entitlements", "-", "--xml", str(bundle)], stderr=subprocess.DEVNULL)
            if plistlib.loads(entitlements).get("com.apple.security.get-task-allow"):
                raise ValueError("A release must not allow debugger attachment.")


def notarize(path, profile, logdir):
    result = json.loads(run("xcrun", "notarytool", "submit", str(path), "--keychain-profile", profile,
                            "--wait", "--output-format", "json", timeout=1800))
    (logdir / f"{path.suffix[1:]}-notary.json").write_text(json.dumps(result, indent=2) + "\n")
    report = json.loads(run("xcrun", "notarytool", "log", result["id"], "--keychain-profile", profile))
    (logdir / f"{path.suffix[1:]}-notary-log.json").write_text(json.dumps(report, indent=2) + "\n")
    if result["status"] != "Accepted" or report.get("issues"):
        raise ValueError("Notarization was not accepted without issues; inspect private logs.")
    return result["id"]


def assess(path, kind):
    if run("spctl", "--status", merged=True) != "assessments enabled":
        raise ValueError("Gatekeeper assessments must be enabled.")
    context = ["--context", "context:primary-signature"] if kind == "open" else []
    result = run("spctl", "--assess", "--type", kind, *context, "--verbose=4", str(path), merged=True)
    if "source=Notarized Developer ID" not in result:
        raise ValueError("Gatekeeper did not identify a notarized Developer ID artifact.")


def check_dmg(dmg, source, work, qualified):
    run("hdiutil", "verify", str(dmg))
    mount = work / "mount"
    mount.mkdir()
    run("hdiutil", "attach", "-readonly", "-nobrowse", "-noautoopen", "-mountpoint", str(mount), str(dmg))
    app = mount / "QLColorCode.app"
    try:
        run(sys.executable, "scripts/verify-bundle.py", str(app), cwd=source)
        if not (mount / "Applications").is_symlink() or os.readlink(mount / "Applications") != "/Applications":
            raise ValueError("Missing Applications shortcut")
        if not (mount / "COPYING").is_file() or not (mount / "Read Me.txt").is_file():
            raise ValueError("Missing install instructions or license")
        if qualified:
            signed_release(app, app=True)
            run("xcrun", "stapler", "validate", str(app))
            assess(app, "execute")
    finally:
        # Only undo registration of this temporary copy; never reset all providers.
        subprocess.run([LSREGISTER, "-u", str(app)], capture_output=True, timeout=30)
        run("hdiutil", "detach", str(mount))
        mount.rmdir()
    if qualified:
        signed_release(dmg)
        run("xcrun", "stapler", "validate", str(dmg))
        assess(dmg, "open")


def build(args):
    qualified = args.command == "prepare"
    revision = run("git", "rev-parse", "HEAD")
    dirty = bool(run("git", "status", "--porcelain", "--untracked-files=all"))
    if qualified:
        require_ready(json.loads((ROOT / "docs/release-readiness.json").read_text()), args.tag)
        expected_version = tag_version(args.tag)
        if dirty or run("git", "rev-parse", f"refs/tags/{args.tag}^{{commit}}") != revision:
            raise ValueError("Prepare requires a clean checkout at the exact existing release tag.")
        label = args.tag[1:]
    else:
        label = f"LOCAL-ONLY-{revision[:8]}{'-dirty' if dirty else ''}-{datetime.now(timezone.utc):%Y%m%dT%H%M%SZ}"
    output = ROOT / "build/releases" / label
    output.mkdir(parents=True, exist_ok=False)
    work, assets, logs = [output / name for name in ("work", "assets", "logs")]
    for path in (work, assets, logs):
        path.mkdir()
    source = work / "source"
    source.mkdir()
    if qualified:
        archive = work / "source.tar"
        run("git", "archive", "--format=tar", f"--output={archive}", f"refs/tags/{args.tag}")
        with tarfile.open(archive) as stream:
            stream.extractall(source, filter="data")
    else:
        snapshot(source)
    source_hash = source_digest(source)
    print(f"Release workspace: {output}", flush=True)
    dagger = portable_checks(source, logs / "dagger.log")
    for script in ("test-modern.sh", "test-preview-layout.sh"):
        print(f"Native macOS: {script}", flush=True)
        (logs / f"{script}.log").write_text(run("bash", f"scripts/{script}", cwd=source, merged=True))
    derived = work / "derived"
    app = derived / "Build/Products/Release/QLColorCode.app"
    command = ["xcodebuild", "-project", "modern/QLColorCodeModern.xcodeproj", "-scheme", "QLColorCode",
               "-configuration", "Release", "-derivedDataPath", str(derived), "-disableAutomaticPackageResolution",
               "ARCHS=arm64 x86_64", "ONLY_ACTIVE_ARCH=NO", "CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO"]
    command += ([f"CODE_SIGN_IDENTITY={args.identity}", f"DEVELOPMENT_TEAM={TEAM}", "OTHER_CODE_SIGN_FLAGS=--timestamp"]
                if qualified else ["CODE_SIGN_IDENTITY=-"])
    print("Native macOS: universal Release build", flush=True)
    try:
        (logs / "xcodebuild.log").write_text(run(*command, "build", cwd=source, merged=True))
        (logs / "bundle.log").write_text(run(sys.executable, "scripts/verify-bundle.py", str(app), cwd=source, merged=True))
    finally:
        subprocess.run([LSREGISTER, "-u", str(app)], capture_output=True, timeout=30)
    info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    if qualified and (info["CFBundleShortVersionString"] != expected_version or int(info["CFBundleVersion"]) <= 1):
        raise ValueError("Tag must match app version; increment the build above the installed build 1.")
    notary = {}
    if qualified:
        signed_release(app, app=True)
        archive = work / "QLColorCode.zip"
        run("ditto", "-c", "-k", "--keepParent", str(app), str(archive))
        notary["app"] = notarize(archive, args.notary_profile, logs)
        run("xcrun", "stapler", "staple", str(app))
        run("xcrun", "stapler", "validate", str(app))
    stage = work / "stage"
    stage.mkdir()
    run("ditto", str(app), str(stage / "QLColorCode.app"))
    (stage / "Applications").symlink_to("/Applications")
    shutil.copy2(source / "COPYING", stage / "COPYING")
    instructions = ("Drag QLColorCode.app to Applications. Open it once and follow its Quick Look setup instructions.\n"
                    "Requires macOS 15 or newer. Free software, GPL v3 or later.\n"
                    f"Source and support: https://github.com/{REPOSITORY}\n")
    if not qualified:
        instructions = "LOCAL REHEARSAL ONLY — ad hoc signed, not notarized. Do not distribute or install.\n" + instructions
    (stage / "Read Me.txt").write_text(instructions)
    dmg = assets / f"QLColorCode-{label}.dmg"
    run("hdiutil", "create", "-srcfolder", str(stage), "-volname", "QLColorCode" if qualified else "QLColorCode LOCAL ONLY",
        "-fs", "HFS+", "-format", "UDZO", str(dmg))
    if qualified:
        run("codesign", "--sign", args.identity, "--timestamp", str(dmg))
        notary["dmg"] = notarize(dmg, args.notary_profile, logs)
        run("xcrun", "stapler", "staple", str(dmg))
    check_dmg(dmg, source, work, qualified)
    digest = sha256(dmg)
    manifest = {"schema": 1, "repository": REPOSITORY, "tag": args.tag if qualified else None,
                "source_commit": revision, "working_tree_dirty": dirty, "distribution_ready": qualified,
                "source_snapshot_sha256": source_hash, "dagger_image": DAGGER_IMAGE,
                "version": info["CFBundleShortVersionString"], "build": info["CFBundleVersion"],
                "dmg": dmg.name, "sha256": digest, "architectures": ["arm64", "x86_64"], "minimum_macos": "15.0",
                "host_macos": run("sw_vers", "-productVersion"), "host_build": run("sw_vers", "-buildVersion"),
                "host_architecture": run("uname", "-m"), "xcode": run("xcodebuild", "-version"), "dagger": dagger,
                "checks": {"dagger": ["vendor hashes", "release policy tests"],
                           "native_macos": ["core", "WebKit", "universal bundle", "DMG mount and contents"]},
                "notarization": notary, "created_utc": datetime.now(timezone.utc).isoformat()}
    (assets / "release.json").write_text(json.dumps(manifest, indent=2) + "\n")
    (assets / "SHA256SUMS").write_text(f"{digest}  {dmg.name}\n{sha256(assets / 'release.json')}  release.json\n")
    if qualified:
        (output / "masonjames-qlcolorcode.rb").write_text(cask(args.tag, digest))
    print(f"PASS: {'qualified' if qualified else 'LOCAL-ONLY'} DMG: {dmg}\nSHA256: {digest}")


def validate_manifest(manifest, directory):
    if manifest.get("schema") != 1 or manifest.get("repository") != REPOSITORY or manifest.get("distribution_ready") is not True or manifest.get("working_tree_dirty") is not False:
        raise ValueError("Only a clean, qualified release can be uploaded.")
    version = tag_version(manifest["tag"])
    expected_name = f"QLColorCode-{manifest['tag'][1:]}.dmg"
    if manifest["version"] != version or manifest["dmg"] != expected_name:
        raise ValueError("Release name/version mismatch")
    if not re.fullmatch(r"[0-9a-f]{40}", manifest["source_commit"]) or sha256(directory / expected_name) != manifest["sha256"]:
        raise ValueError("Release revision/hash mismatch")
    return directory / expected_name


def draft(args):
    directory = args.assets.resolve()
    manifest = json.loads((directory / "release.json").read_text())
    dmg = validate_manifest(manifest, directory)
    require_ready(json.loads((ROOT / "docs/release-readiness.json").read_text()), manifest["tag"])
    tag, revision = manifest["tag"], manifest["source_commit"]
    if run("git", "rev-parse", f"refs/tags/{tag}^{{commit}}") != revision or run("git", "rev-parse", "HEAD") != revision or run("git", "status", "--porcelain", "--untracked-files=all"):
        raise ValueError("Draft requires the clean source checkout used to prepare this tag.")
    remote = run("git", "ls-remote", f"https://github.com/{REPOSITORY}.git", f"refs/tags/{tag}", f"refs/tags/{tag}^{{}}")
    refs = dict(line.split()[::-1] for line in remote.splitlines())
    if refs.get(f"refs/tags/{tag}^{{}}", refs.get(f"refs/tags/{tag}")) != revision:
        raise ValueError("Push the exact reviewed tag before creating a draft.")
    releases = json.loads(run("gh", "api", "--paginate", "--slurp", f"repos/{REPOSITORY}/releases?per_page=100"))
    if any(release["tag_name"] == tag for page in releases for release in page):
        raise ValueError("A release or draft already exists for this tag; no assets will be replaced.")
    expected_sums = f"{manifest['sha256']}  {dmg.name}\n{sha256(directory / 'release.json')}  release.json\n"
    if (directory / "SHA256SUMS").read_text() != expected_sums:
        raise ValueError("SHA256SUMS does not describe these assets")
    # Recheck the actual artifact; JSON flags are not a substitute for trust checks.
    with tempfile.TemporaryDirectory(prefix="qlcolorcode-verify-") as temp:
        check_dmg(dmg, ROOT, Path(temp), True)
    assets = [str(directory / name) for name in (dmg.name, "SHA256SUMS", "release.json")]
    command = ["gh", "release", "create", tag, *assets, "--repo", REPOSITORY, "--verify-tag", "--draft",
               "--title", f"QLColorCode {tag[1:]}", "--notes-file", str(args.notes.resolve())]
    if "-" in tag:
        command.extend(["--prerelease", "--latest=false"])
    print(run(*command))
    with tempfile.TemporaryDirectory(prefix="qlcolorcode-download-") as temp:
        run("gh", "release", "download", tag, "--repo", REPOSITORY, "--dir", temp)
        for asset in assets:
            if sha256(Path(temp) / Path(asset).name) != sha256(asset):
                raise ValueError("Uploaded bytes differ; leave the draft unpublished and investigate.")
    print("Draft assets downloaded and matched. Review the draft before publishing; no tap was changed.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("rehearse", help="Build and mount a LOCAL-ONLY DMG; never sign with Developer ID or upload")
    prepare = sub.add_parser("prepare", help="Build a qualified, signed and notarized release locally")
    prepare.add_argument("--tag", required=True)
    prepare.add_argument("--identity", required=True)
    prepare.add_argument("--notary-profile", required=True, help="Existing Keychain profile name, never a password")
    upload = sub.add_parser("draft", help="Verify and upload prepared assets to a GitHub draft release")
    upload.add_argument("--assets", type=Path, required=True)
    upload.add_argument("--notes", type=Path, required=True)
    args = parser.parse_args()
    if sys.version_info < (3, 12):
        parser.error("Use Python 3.12 or newer for release tooling.")
    if sys.platform != "darwin":
        parser.error("The release orchestrator needs native macOS; portable tests run in Dagger.")
    try:
        draft(args) if args.command == "draft" else build(args)
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        print(f"STOP: {error}", file=sys.stderr)
        if isinstance(error, subprocess.CalledProcessError):
            print(((error.output or "") + (error.stderr or ""))[-12000:], file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
