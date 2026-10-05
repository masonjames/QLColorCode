# Test the downloaded beta

You do not need Xcode or a developer account. A report from an ordinary Mac is
especially useful for Sequoia 15, Tahoe 26 and physical Intel hardware. Use the
[compatibility form](https://github.com/masonjames/QLColorCode/issues/new?template=compatibility_report.yml)
and mark each result **pass**, **fail** or **not tested**. A failure is useful evidence.

## Current matrix

This table covers **5.0.0-beta.1, app build 3**. The minimum target is macOS 15;
the table records observed results, not a promise that untested systems work.

| macOS | Apple Silicon | Physical Intel |
| --- | --- | --- |
| Sequoia 15 | Not tested | Not tested |
| Tahoe 26 | Not tested | Not tested |
| Golden Gate 27 | 27.0.1: companion, Finder, download and tap installation passed; focus navigation, clipboard roundtrip and VoiceOver pending | Not applicable: Apple supports Apple Silicon only |

Apple's [Golden Gate compatibility list](https://support.apple.com/en-us/127255)
defines the last row. Automated x86_64 tests under Rosetta on the maintainer's
Apple Silicon Mac passed; they do not qualify an Intel Mac. The detailed
[evidence record](REVIEW-EVIDENCE.md) separates each check.

## Install and identify the build

1. If you already have a modern QLColorCode app, save it before replacing it. Keep any old
   `QLColorCode.qlgenerator` and unrelated Quick Look providers intact. For a
   clean-install report, say whether this Mac had any QLColorCode version before.
2. Download the DMG from the [versioned release](https://github.com/masonjames/QLColorCode/releases/tag/v5.0.0-beta.1)
   in a browser, or use the [custom tap](https://github.com/masonjames/homebrew-tap).
   Record which method you used. For a manual-to-Homebrew change, move your saved
   manual app aside first; do not force Homebrew to overwrite it.
3. For the DMG, compare its SHA256 with the release's `SHA256SUMS`. For beta.1:

   ```sh
   shasum -a 256 ~/Downloads/QLColorCode-5.0.0-beta.1.dmg
   ```

   Expected: `51db8c79aabb31a7e7b4b252b66f8bb024dc145f6bdb5f07038b684feb41fe33`.
   Adjust the filename if your browser added a suffix. Keep quarantine intact.
4. Install and open QLColorCode, then enable **QLColorCode Preview** in System
   Settings → General → Login Items & Extensions → Quick Look. If macOS refuses
   to open it, stop and report the exact message; do not bypass Gatekeeper.
   The settings wording may differ on Sequoia and Tahoe; report what you find.
5. Record the version/build from **QLColorCode → About QLColorCode**, macOS
   version/build from **About This Mac** (click the version to reveal the build),
   and chip family. Do not include a
   serial number. A virtual machine report should name the guest OS and say VM.

## Exercise the two preview surfaces

Use [Palette.swift](../examples/Palette.swift) from the release source archive,
or your own small public/synthetic sample. Never attach private source code.

| Check | Expected result |
| --- | --- |
| Companion: Choose a file or Command-O, then open Palette.swift | Syntax colors and 23 logical lines; opening/cancelling the file picker stays usable |
| Finder: select the same file and press Space | QLColorCode header and syntax colors; a companion-only result does not count |
| Narrow/widen the preview and read a long source line | Text wraps, indentation remains readable, numbers identify original lines |
| Select and copy part of the code into a temporary plain-text document | Exact source, including tabs and Unicode, without line numbers or extra text |
| Close/reopen, then move between several source files | The preview updates to the selected file; no blank or stale result |
| Test `.py`, `.js`, `.tsx`, `.rs`, `.go`, `.yaml`, `.toml` and `.h` samples | Record the actual result for each; leave untested extensions untested |
| Open a larger synthetic source file, then return to Palette.swift | Readable plain fallback or truncation notice as appropriate; small-file colors recover |

For a source file over 32 KiB, highlighting intentionally falls back to plain
text; a source line over 2,000 UTF-8 bytes also triggers fallback. Reads stop at
256 KiB or 6,000 lines. Record approximate size and the visible
notice. A stuck parser may briefly delay later highlighting while macOS restarts
its service; record that delay rather than treating plain text as a color pass.

`.ts` can resolve to a movie type on macOS. Report the observed behavior separately;
do not change system file associations to make it pass. If another preview app
handles a file, report a provider conflict rather than counting its output.

## Keyboard and accessibility

Check the companion and Finder separately. Restore any settings you change.
In the beta companion, Command-A visibly selects the preview header as well as
code. Select the desired source range for the copy check; clipboard roundtrip
and full keyboard traversal remain open qualification items.

- Use the keyboard to open/cancel the file picker, reach the preview, navigate
  source text and return to the app controls. Note any focus trap.
- With VoiceOver, verify control names, reading order, source content and the
  fallback/truncation notice. Decorative line numbers should not pollute source
  reading. An accessibility-tree inspection alone is not a VoiceOver result.
- Check light and dark appearance, readable wrapped lines and selected text.
  Report your settings; do not infer one appearance from the other.

## Upgrade, rollback and reporting

The first tap version has no earlier tap release to upgrade from. Mark that case
**not tested**. When a later beta exists, test upgrading from the prior version,
verify its app build and Finder output, and keep the previous app for rollback.
Follow [the local rollback procedure](LOCAL-TRIAL.md#rollback); restoring an app
manually is separate from testing Homebrew's upgrade behavior.

Submit the exact release/build, installation method, OS/build, chip and observed
results through the form. Include a minimal fixture and app-only screenshot for
failures. Remove personal paths and unrelated desktop content. Maintainers review
reports before updating this matrix; an untested item is never a pass.
