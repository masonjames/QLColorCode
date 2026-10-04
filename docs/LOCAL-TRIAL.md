# Local trial and rollback

This procedure is a plan, not a record that installation has happened.

## Before changing the installed setup

1. Finish the local build, parser tests, bundle inspection and independent review.
2. Verify the exact app path and checksum. A development build is not the release.
3. Record the existing Homebrew receipt and legacy generator path/version.
   On the review host, 4.1.0 is installed in `~/Library/QuickLook/QLColorCode.qlgenerator`.
4. Keep the old generator and preferences intact. macOS no longer invokes the old
   generator API, but other OS versions or rollback scenarios may need the files.
5. Obtain approval for the concrete signing/install/extension-activation action.
   Do not remove quarantine or weaken Gatekeeper to make the trial pass.

## First trial

- Test the app from the build directory using only repository fixtures first.
  Xcode builds and app opening can register app/UTI declarations with Launch Services. This does
  not establish that the preview extension is enabled or being chosen by Finder.
- For a persistent trial, install the reviewed app at an agreed Applications path.
  Keep a manifest of exactly which file was installed and the prior state there.
- Enable only this app's Quick Look extension under System Settings → General →
  Login Items & Extensions → Quick Look. Record the prior enabled state.
- Use Finder Space on `.swift`, `.py`, `.js`, `.tsx`, `.rs`, `.go`, `.yaml`, `.toml`,
  C headers and an unknown file. Record which extension actually rendered each.
- Test `.ts` separately: the host currently identifies it as MPEG transport stream.
  Never "fix" this by claiming every video file.
- Exercise text selection/copy, arrows between files, scrolling, Unicode/UTF-16,
  long lines, large files, binary content, and rapid repeated previews. Repeat in
  light and dark appearance after an explicitly approved settings change.

## Rollback

- Disable the new preview extension, restoring its recorded previous state.
- Restore the prior app at the agreed install path if there was one; otherwise
  remove only the exact newly installed app after approval.
- Preserve any changed preferences and diagnostic evidence before removal.
- Confirm normal system previews work again. Do not reset all Launch Services or
  Quick Look caches, disable Apple/Xcode components, or uninstall unrelated preview apps.
- The old 4.1.0 source, installed generator, preference domain and Homebrew receipt
  are independent of this new bundle identifier and should remain untouched.
