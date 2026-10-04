# QLColorCode

Source-code previews for Finder's Quick Look, revived for modern macOS.

This fork continues [Nathaniel Gray's original project](https://github.com/n8gray/QLColorCode)
and [Anthony Gelibert's continuation](https://github.com/anthonygelibert/QLColorCode),
including their Git history and contributor credits.

**Status: development prototype, not a published replacement for 4.1.0.** The modern
app targets macOS Sequoia 15 and newer. It has been built on Golden Gate 27.0.1;
older OS runtime compatibility and Finder registration still need qualification.
The existing Homebrew `qlcolorcode` cask installs the obsolete generator and was
disabled on September 27, 2026. It does not install this fork.

## Modern preview

The new Swift app embeds a sandboxed Quick Look preview extension. Its renderer
provides selectable source, line numbers, horizontal scrolling, and automatic
light/dark colors. Highlighting runs offline through a pinned copy of
[highlight.js](modern/Resources/PROVENANCE.md). It does not execute source files,
invoke a shell, download grammars, or require a runtime Homebrew dependency.

The app also offers **Choose a file…** to exercise the renderer independently of
Finder. This is useful when diagnosing file-type registration conflicts.

This is a new engine: André Simon's Highlight options, plugins, and theme names
from the old generator are not compatible. Existing preferences are not changed.
There is no preferences migration or thumbnail extension in this prototype.

## Build and check

Requires full Xcode with a Swift 6 compiler and XcodeGen. The checked-in modern
Xcode project can also be opened directly in Xcode.

```sh
bash scripts/test-modern.sh
bash scripts/build-modern.sh
```

The development app is written to:

```text
build/modern/Build/Products/Debug/QLColorCode.app
```

The build produces Apple Silicon and Intel slices and uses ad hoc signing. Xcode
automatically registers the build's app and file-type declarations with Launch
Services. It does not copy the app into Applications, manually enable its extension,
alter the old generator, or use a Developer ID certificate. A passing build is not a Gatekeeper or notarization
result. The old Xcode project remains at the repository root for historical use;
new development belongs in `modern/`.

## Known limits

- The reader accepts regular UTF-8 or BOM-marked UTF-16 files, reads at most 256 KiB
  plus one lookahead byte, and displays at most 6,000 lines. A notice identifies
  partial previews. Binary and unsupported encodings return an explicit error.
- Highlighting is limited to 32 KiB and lines of at most 2,000 UTF-8 bytes. Larger
  previews fall back to escaped plain text with a notice. These input limits do
  **not** guarantee a parser execution deadline; a hard timeout is a release gate.
- Only the bundled common grammars are available. Unknown languages display plain
  text in the companion app. Finder additionally requires a supported concrete UTI.
- On the development Mac, `.ts` resolves to `public.mpeg-2-transport-stream`.
  TypeScript can be previewed in the companion app, but `.ts` Finder support is
  unresolved. The extension deliberately does not claim the movie type.
- Extensionless Makefiles and shell dotfiles can be previewed in the companion;
  Finder routing for extensionless files is not claimed.
- `.tsx`, Rust, Go, YAML, TOML, and other mappings must be tested with different
  editors installed. Imported file-type declarations do not guarantee precedence.
- Binary plist conversion, compiled-script decompilation, configurable fonts/themes,
  and legacy feature parity are deferred. Intel compilation is not an Intel runtime test.

See the [repository review and roadmap](docs/REVIVAL-REVIEW.md) and
[local trial procedure](docs/LOCAL-TRIAL.md) for evidence and remaining gates.
The previous documentation is preserved in [LEGACY.md](docs/LEGACY.md).

## Community and distribution

We intend to produce a signed, notarized app, prove the Finder experience, and
publish a versioned release before offering a personal Homebrew tap. Replacing
Homebrew's existing `qlcolorcode` token depends on their successor/fork criteria
and maintainer review. This fork does not claim an upstream handover or endorsement.

## License and credits

The current upstream source includes GNU GPL v3 in [COPYING](COPYING); retain its
copyright notices and the original authors' credit. The original project shipped
GPL v2 and Anthony's branch changed its license file in 2016; history is preserved.
New Swift contributions are GPL-3.0-or-later. The bundled highlight.js library is
BSD-3-Clause, with its [notice](modern/Resources/highlight-LICENSE) included in both
application bundles. Its source revision and checksums are recorded alongside it.
