# Develop QLColorCode

## Requirements

Use macOS 15 or newer and full Xcode with a Swift 6 compiler. The local reference
toolchain is Xcode 27 on macOS 27.0.1 / Apple Silicon; compatibility with older
Xcode versions has not been established. Apple's standalone Command Line Tools
are not enough to build the app.

Check the selected tools before building:

```sh
xcode-select -p
xcodebuild -version
xcrun swiftc --version
```

If they point at the standalone tools, choose full Xcode in **Xcode → Settings →
Locations → Command Line Tools**. Finish Xcode's first-launch setup when prompted.

## Build and check

From a clone of this repository:

```sh
bash scripts/test-modern.sh
bash scripts/test-preview-layout.sh
bash scripts/build-modern.sh
```

The first command checks bounded file reading, syntax rendering, hostile input,
Unicode, source escaping and the legacy header-execution regression. The second
runs the renderer in real WebKit and verifies wrapping, full/partial selection and
appearance. It needs a logged-in macOS session with WebKit available. The last
builds both Apple Silicon and Intel slices and inspects the actual bundles.

The checked-in project is the build input. XcodeGen is only needed after changing
`modern/project.yml`:

```sh
xcodegen generate --spec modern/project.yml
```

Commit the YAML and generated project together. Do not regenerate the historical
root Xcode project. No JavaScript package manager, grammar download or global
highlighter installation is part of this build.

## Try the app

The product is `build/modern/Build/Products/Debug/QLColorCode.app`. Open the modern
project in Xcode to inspect or run it, or use the built companion when your signing
setup permits. Choose `examples/Palette.swift` as a small public fixture.

The default build is ad hoc signed. This is sufficient for bundle checks, but it
does not establish that macOS will allow the extension to run. Our local runtime
trial used a Developer ID signed build. You can contribute core and WebKit test
results without installing or enabling a Quick Look extension.

Xcode may register the development app and its file types with Launch Services
automatically. It does not copy the app into Applications. Do not confuse a running
extension from `build/` with one from an installed app. Follow
[LOCAL-TRIAL.md](LOCAL-TRIAL.md) for signature checks, provider inspection and
reversible installation. Do not remove quarantine, disable Gatekeeper or reset all
Quick Look providers to make a development build run.

## Architecture and limits

| Location | Responsibility |
| --- | --- |
| `modern/Core/SourceDocument.swift` | Regular-file reads, encoding, newline normalization, size/line limits and language identification |
| `modern/Core/PreviewRenderer.swift` | Pinned grammar execution and escaped, wrapped HTML with logical line numbers |
| `modern/Preview/PreviewProvider.swift` | Data-based Quick Look preview extension |
| `modern/App/` | Companion UI, bundled icon and restricted local WebKit display |
| `modern/Resources/` | Pinned highlight.js distribution, license and provenance |
| `Tests/` | Reader/security regressions and real WebKit layout/selection checks |

The reader accepts UTF-8 or BOM-marked UTF-16, reads at most 256 KiB plus one
lookahead byte, and displays at most 6,000 logical lines. Highlighting is limited
to 32 KiB and source lines of at most 2,000 UTF-8 bytes. Larger previews remain
escaped plain text and show a notice. These limits are not a hard parser deadline.

The companion needs outgoing-network permission for WebKit helper startup. Before
loading local HTML it installs a block-all-resource rule, disables page JavaScript
and rejects external navigation. The extension has no network entitlement. These
are separate facts: application-level resource blocking does not mean the
companion's sandbox prohibits networking.

Legacy Highlight theme/flag/plugin compatibility, thumbnails, binary plist
conversion and compiled-script decompilation are not implemented. The `.ts`
filename extension can resolve to a movie UTI; do not claim `public.movie` or
`public.data` to work around that collision.

## Record evidence precisely

A universal build proves two compiled slices, not two tested architectures.
A companion preview does not prove Finder invocation. A Developer ID signature
does not prove notarization or Gatekeeper acceptance of a downloaded release.

Include the source commit, macOS build, chip, Xcode version and which surface you
tested. Use public/synthetic fixtures and app-only screenshots. Keep local signing
identities, paths, raw logs and binary artifacts out of pull requests. See the
[verification record](REVIEW-EVIDENCE.md) for current results.
