<p align="center">
  <img src="modern/App/Assets.xcassets/AppIcon.appiconset/icon-256.png" width="112" height="112" alt="Prism Q: colored code strokes forming a magnifying glass around code brackets">
</p>
<h1 align="center">QLColorCode</h1>
<p align="center"><strong>A closer look at your code.</strong><br>Source previews since 2007. Rebuilt for modern macOS.</p>
<p align="center">
  <a href="#download">Get started</a> ·
  <a href="CONTRIBUTING.md">Contribute</a> ·
  <a href="docs/ROADMAP.md">Roadmap</a> ·
  <a href="https://github.com/masonjames/QLColorCode/issues/new/choose">Report a bug</a>
</p>

Select a source file in Finder, press **Space**, and read it in color. QLColorCode
brings syntax highlighting, original line numbers and automatic wrapping to
Quick Look, with a small companion app for trying previews and setting up the extension.

> **Public beta — 5.0.0-beta.1.** Free, signed and notarized. Targets **macOS
> Sequoia 15 and newer**; tested on Golden Gate 27.0.1 / Apple Silicon. Automated
> tests also passed under Rosetta. Sequoia, Tahoe, physical Intel and VoiceOver
> still need qualification.
> This is an independent maintained fork, not the official Homebrew successor.

![QLColorCode beta companion showing the public Swift palette example with syntax colors and line numbers](docs/images/preview.jpg)

*An actual preview from the downloaded, notarized beta using the
[Palette.swift](examples/Palette.swift) fixture. Finder uses the same renderer.*

## Small utility, thoughtful defaults

- **Read the source.** Syntax colors, selectable text and original line numbers.
- **Let long lines wrap.** The gutter follows logical lines as the window changes size.
- **Match your Mac.** Automatic light and dark colors; no theme setup required.
- **Keep previews local.** Bundled grammars, no content downloads or source execution.
- **Know when a preview is partial.** Large files have bounded previews with a visible notice.

## Download

**[Download QLColorCode 5.0.0-beta.1.dmg](https://github.com/masonjames/QLColorCode/releases/download/v5.0.0-beta.1/QLColorCode-5.0.0-beta.1.dmg)**
— universal for Apple Silicon and Intel. [Release notes, checksums and build receipt](https://github.com/masonjames/QLColorCode/releases/tag/v5.0.0-beta.1).

Open the DMG, drag QLColorCode to Applications, then open it once. Enable
**QLColorCode Preview** in System Settings → General → Login Items & Extensions →
Quick Look. Select a source file in Finder and press **Space**.

Or install the same notarized DMG through our [Homebrew tap](https://github.com/masonjames/homebrew-tap):

```sh
brew install --cask masonjames/tap/masonjames-qlcolorcode
```

If you already installed this app manually, keep a backup and move that copy aside
before using Homebrew. The cask does not remove the legacy generator or enable
extensions automatically. The old `brew install --cask qlcolorcode` package does
not install this fork. See [release and migration details](docs/RELEASING.md).

## Build from source

You'll need a Mac with **macOS 15+**, **full Xcode with Swift 6**, and its command-line
tools selected. No package manager or XcodeGen is needed for an ordinary build.
The current toolchain verified by this fork is Xcode 27; older toolchains still
need qualification.

```sh
git clone https://github.com/masonjames/QLColorCode.git
cd QLColorCode
bash scripts/test-modern.sh
bash scripts/test-preview-layout.sh
bash scripts/build-modern.sh
```

The app is built at `build/modern/Build/Products/Debug/QLColorCode.app`. You can also
open `modern/QLColorCodeModern.xcodeproj` in Xcode. See the
[development guide](docs/DEVELOPMENT.md) for tool selection, signing and local trials.

**A successful build is not an install.** The default build uses ad hoc signing;
macOS may refuse to run its extension. Finder testing needs a suitably signed app
and an enabled Quick Look extension. Follow the [local-trial guide](docs/LOCAL-TRIAL.md)
without disabling Gatekeeper or changing unrelated providers. In a working
companion app, choose `examples/Palette.swift` to start with a safe sample.

## What works, and what needs help

| Area | Current evidence |
| --- | --- |
| Renderer | Core and real WebKit checks cover Unicode, wrapping, selection, multiline tokens, large files and safe fallback |
| Golden Gate 27.0.1 / Apple Silicon | Notarized downloaded app and Finder previews tested; local upgrade/rollback verified |
| Sequoia 15 / Tahoe 26 / Intel | Build targets are present; runtime qualification is still needed |
| TypeScript | Companion can render it; `.tsx` worked in the Finder trial, while `.ts` conflicts with a macOS video type |
| Distribution | Notarized universal DMG and checksum-pinned custom tap; no official successor designation |
| Release automation | Local Dagger checks and native macOS packaging; no GitHub Actions dependency |

The [release roadmap](docs/ROADMAP.md) tracks the remaining work. The
[verification record](docs/REVIEW-EVIDENCE.md) separates builds, runtime tests,
installed versions and untested cases.

The modern renderer currently uses a pinned [highlight.js](modern/Resources/PROVENANCE.md)
bundle. Legacy Highlight themes, flags, plugins and thumbnails are not carried
forward. Reads are capped at 256 KiB and 6,000 lines; highlighting has tighter
limits and a one-second parser budget, then falls back to plain text. See [architecture and limitations](docs/DEVELOPMENT.md#architecture-and-limits).

## Help keep a useful little project alive

A clear bug report, a small fixture, a macOS compatibility check, or a focused
pull request all help. Start with [CONTRIBUTING.md](CONTRIBUTING.md). You don't need
to tackle the whole revival to contribute something useful.

For a security concern, use the [private reporting instructions](SECURITY.md).
For the path toward Homebrew, see the [successor readiness notes](docs/SUCCESSOR.md).

## History since 2007, preserved

This fork continues [Nathaniel Gray's original QLColorCode](https://github.com/n8gray/QLColorCode),
[Derzzle's build work](https://github.com/derzzle/QLColorCode), and
[Anthony Gelibert's continuation](https://github.com/anthonygelibert/QLColorCode).
Their Git history and contributor credits remain intact. The modern Swift work
is maintained here by [Mason James](https://github.com/masonjames).

Read the [historical review](docs/REVIVAL-REVIEW.md) or the
[preserved legacy documentation](docs/LEGACY.md). Prism Q is our new identity;
it does not imply endorsement by previous maintainers, Apple or Homebrew.

## License

[GNU GPL v3](COPYING); new Swift contributions are GPL-3.0-or-later. The original
project used GPL v2 before the upstream license-file change in 2016. Existing
copyright notices are retained. The bundled highlight.js library is BSD-3-Clause,
and its [license](modern/Resources/highlight-LICENSE) ships with both app bundles.
