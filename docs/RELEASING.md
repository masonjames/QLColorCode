# Release QLColorCode

Every public release should offer one **free, universal DMG**, attached to its
GitHub release. A maintainer-owned Homebrew tap will download those same bytes.
There is no separate brew build, account requirement for downloads, or paid tier.

## Beta and stable qualification

A beta can gather compatibility reports before the complete support matrix is
qualified. It must first pass parser deadline/cancellation/recovery checks and a
signed local app/Finder install, upgrade and rollback trial with real highlighting.
Notarization, stapling, Gatekeeper, checksums and download verification are required
for every distributed build, including betas. Failed parsing must fall back safely;
a preview that is always plain text does not count as successful highlighting.

[release-readiness.json](release-readiness.json) keeps separate beta and stable
evidence. Stable additionally requires the declared macOS/hardware matrix and
accessibility qualification. Unobserved gates stay false. The script selects gates
from the tag: beta evidence cannot authorize a stable version. All prereleases are
marked as such on GitHub and are never marked latest. Notes and the README must
state exactly which platforms were tested and which remain unverified. A deployment
target or universal binary alone proves no runtime compatibility.

Maintainers review evidence before changing gates; nonempty text is not proof.
This policy was reviewed before the first beta implementation. It enables a clearly
labelled test release, not stable support or Homebrew successor acceptance.

## Where work runs

| Stage | Execution |
| --- | --- |
| Vendored resource hashes and release-policy tests | Local Dagger engine, pinned Python image |
| Swift core tests, real WebKit tests, universal Release build | Native macOS host |
| Signing, notarization, DMG creation, mounted-bundle and Gatekeeper checks | Native macOS host and Apple notary service |
| Asset storage | GitHub Releases, uploaded explicitly using `gh` |
| Cask distribution | `masonjames/homebrew-tap`, pointing to the same DMG |

**No GitHub Actions workflow is required or installed.** Dagger's Linux engine
cannot run Xcode or macOS signing tools. The container receives only an explicit public-source
allowlist, with no host environment or secrets imported. The host CLI uses a
credential-free temporary Docker configuration; Cloud/OTEL environment variables
are removed for that subprocess. Signing happens afterward on the Mac; keys stay
in Keychain. An existing `/usr/local/libexec/dagger-ci-host-guard` wraps the Dagger
stage when present; `DAGGER_CI_HOST_GUARD` can select another installed guard.

Requirements: the [development toolchain](DEVELOPMENT.md), Python **3.12+**,
Dagger **0.21.10**, a running local Docker engine, and a logged-in macOS session
for the WebKit checks. Publishing additionally uses `gh` and the maintainer's
Developer ID / notarytool Keychain profile. No SDK packages or DMG helper are needed.

## Rehearse without credentials or installation

```sh
python3 scripts/release.py rehearse
```

This snapshots the modern source and tests, runs Dagger and native checks, builds
an ad hoc signed Release app and creates a compressed HFS+ DMG. It mounts the image
read-only at a private path, checks the app, extension, licenses and Applications
shortcut, then detaches it. It does not launch, install, enable or upload the app.
Xcode may register a build; the script unregisters only its temporary app copies.

Outputs go into a new `build/releases/LOCAL-ONLY-…/` directory:

- `assets/`: clearly named rehearsal DMG, `SHA256SUMS` and `release.json`.
- `logs/`: local Dagger, native test and build output; these may contain host paths.
- `work/`: source snapshot, fresh derived data and staging files for inspection.

The receipt labels dirty source, the source-snapshot digest, pinned container image
and actual test host. The snapshot digest hashes a compact sorted JSON map of
relative file names to SHA256s, before tests generate any output. Rehearsals
snapshot modern build inputs; qualified builds export the full tag. Their snapshot
digests are not directly comparable. The [first rehearsal receipt](releases/2026-10-04-rehearsal.json)
records a successful local packaging run. An arm64-host test plus
a universal build is not an Intel runtime test. Rehearsal images cannot pass the
upload command. Keep them local; they are not downloadable betas.

## Prepare a qualified version

Complete and review the readiness gates for the intended channel first. Update the app version/build in
`modern/project.yml`, regenerate the checked-in project, and use a build number
above the earlier installed development build `1`. Increase the build number for
every beta, release candidate and final release. Commit the complete change,
create an annotated `vX.Y.Z` tag (or `vX.Y.Z-beta.N`), and check out that exact tag.
The worktree must be clean, including untracked files. The build uses a Git archive
of the tag and fresh derived data, so ignored local files cannot enter it.

```sh
python3 scripts/release.py prepare \
  --tag v5.0.0-beta.1 \
  --identity 'Developer ID Application: YOUR NAME (TEAM ID)' \
  --notary-profile QLColorCode
```

The first beta uses this version. Choose a new tag/build for the next release;
never replace published assets. This fork pins its expected signing team in the release script; downstream maintainers must
review that value for their own distribution.

The pipeline verifies the signing team, hardened runtime, secure timestamps and
absence of debugger entitlement. It notarizes a ZIP of the app, checks Apple's
result/log, staples the app, then packages and signs the DMG. It notarizes/staples
the DMG too, verifies the mounted app and both Gatekeeper assessments, and only
then computes the final DMG hash. A rejection or notary issue stops preparation.

Qualified output includes `masonjames-qlcolorcode.rb`, generated from the exact
tag and final DMG checksum. The image contains the app, an Applications shortcut,
a license and a short installation note. There are no installer/postflight scripts.
The cask's update check uses published modern release tags, excluding legacy
`release-4.x` tags and drafts. A prerelease cask also sees published prereleases;
the generated stable cask excludes them. This is separate from release eligibility.

## Create and verify a draft

Write release notes covering changes, tested OS/chip combinations, known limits,
installation, and migration from the legacy generator. Push the reviewed tag to
this fork, then:

```sh
python3 scripts/release.py draft \
  --assets build/releases/5.0.0-beta.1/assets \
  --notes /path/to/release-notes.md
```

The command checks the clean source/tag, the remote tag's commit, all checksums,
actual signatures, stapled tickets, mounted contents and Gatekeeper again. It
creates a **draft** with the DMG, receipt and checksums, downloads all uploaded
assets and compares their bytes. Existing releases, including drafts, are refused;
there is no overwrite option. A failed upload leaves its draft for inspection.
A failed prepare keeps its workspace too: inspect it and move it aside before
retrying that version. Remove a failed draft only after reviewing what was uploaded.
Do not delete or replace a public release's assets; bump the version for a fix.

The GitHub release tag provides the corresponding GPL source archive. Never upload
`logs/`, signing material, Keychain exports or the whole release workspace.

## Publish, then update the tap

1. Review the draft, its source tag, attached evidence, free download and notes.
   Download the draft DMG and verify installed app/Finder highlighting from that
   exact notarized artifact before publishing; an earlier signed trial is insufficient.
   Publish it explicitly in GitHub or with `gh release edit TAG --draft=false`.
   Keep beta/rc releases marked as prereleases.
2. Download the published DMG from its public version URL without authentication.
   Match `SHA256SUMS`; verify the stapled app and DMG, Gatekeeper, and a fresh
   browser-download trial on a test Mac. Do not remove quarantine to pass.
3. Commit the generated cask to `Casks/m/masonjames-qlcolorcode.rb` in
   `masonjames/homebrew-tap`. Review it, run `brew style`, `brew audit --cask` and
   `brew fetch --cask` against the fully qualified cask. A fetch proves the URL/hash;
   it does not prove installation or upgrade behavior.
4. On a qualified test Mac, verify installation, opening the app, its enabled
   Quick Look extension and Finder preview. Preserve other providers. For the
   first tap version, record the initial install and the local app rollback trial;
   a future-version Homebrew upgrade remains unverified. Once a prior tap version
   exists, verify its upgrade and rollback too. Publish the receipt with the exact
   release and environment.
5. Only then add the actual DMG link and
   `brew install --cask masonjames/tap/masonjames-qlcolorcode` to the README.

The [custom tap](https://github.com/masonjames/homebrew-tap) distributes the public
beta. No Homebrew core/cask acceptance or predecessor endorsement is implied.

## Set up notarization once

An existing Developer ID certificate signs the app; a notarytool profile separately
authenticates uploads to Apple. Apple documents the
[Keychain credential workflow](https://developer.apple.com/documentation/technotes/tn3147-migrating-to-the-latest-notarization-tool).
Create an app-specific password in your Apple Account, then run interactively:

```sh
xcrun notarytool store-credentials QLColorCode
```

Enter your Apple ID, team ID and app-specific password at the prompts. Keep the
password out of chat, shell arguments, source and CI. The command validates the
credentials and stores them in Keychain. Confirm with:

```sh
xcrun notarytool history --keychain-profile QLColorCode
```

A working profile does not clear the release-readiness gates. Use the same profile
name with `prepare`; credentials never enter the repository or Dagger container.
