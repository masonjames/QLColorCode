# QLColorCode revival review — October 4, 2026

## Conclusion

Revival is feasible, but current macOS support requires a modern app extension.
Recompiling the old `.qlgenerator` cannot restore the removed generator API.
A small Swift companion app plus a sandboxed preview extension is the proposed
replacement. The first implementation is a development spike, not a stable release.

## Lineage and historical review

GitHub's fork graph is `n8gray → derzzle → anthonygelibert → masonjames`.
This checkout preserves the 292 commits reachable from Anthony's current HEAD,
`18765d8f0dacc9d0b8f01b5e296004b06b974f8c`.

| Period | Relevant evolution |
| --- | --- |
| November–December 2007 | Nathaniel Gray's initial import (`5a70003`), then replacement of Pygments with André Simon's Highlight (`23ea6d8`). |
| 2008–2009 | Preferences, language definitions, size limits, filename escaping, 64-bit builds, and the Xcode preview conflict workarounds. |
| 2012–2013 | Derzzle's Xcode 4 build changes; Anthony's continuation restructures sources and integrates external Highlight. |
| 2014–2018 | Expanded formats, shell dispatch and plugins, Highlight discovery, GNU GPL v3 license-file update (`d40faac`, March 2016), optional RTF rendering. |
| 2020 | More languages, Mojave appearance support, Big Sur work, bundled Highlight/Lua, final published 4.1.0 release on December 17. |
| 2021 / 2024 | Current HEAD was authored July 7, 2021 but committed December 7, 2024. The change is a README typo, not a new release. |
| 2025–2026 | Homebrew deprecated old generators, then disabled this cask September 27, 2026. |

I fetched and compared the original and intermediate branches. The original's
unmerged `eea6f82` changes only the old Xcode project. Derzzle's unmerged changes
include Xcode 4 workspace state and `4148cdc`, a build shim for externally installed
Highlight. They do not provide a modern preview extension and should not be blindly
merged into the new architecture. GitHub lineage does not mean every later commit
from every ancestor was merged.

The open upstream issue inventory includes Apple Silicon failures, bundled Highlight
crashes, signing/Gatekeeper trouble, settings regressions, TypeScript dispatch, and
Homebrew disablement. PR #91 proposes Apple Silicon build settings; it does not
migrate the legacy API. Public recent forks inspected did not reveal a completed
modern extension in this fork network. This was a scoped survey, not proof that no
other implementation exists.

## Findings in the existing source

| Severity | Finding | Evidence / disposition |
| --- | --- | --- |
| P1 | Legacy preview API is unsuitable for the target OS. | `GeneratePreviewForURL.m`, `main.c`, and the `.qlgenerator` bundle configuration. Replaced by a separate `QLPreviewProvider` extension in the prototype. |
| P1 | Header detection executes executable `.h` / `.pch` files. | `src/colorize.sh:98` uses command process substitution instead of file input. Introduced by `2a97cc5` in 2014. Harmless marker regression fails before the patch and passes after quoted direct `grep`. Installed 4.1.0 has not been patched by editing source. |
| P2 | Unbounded subprocess output / missing timeout and cancellation. | `Common.m:39` reads to EOF and waits; `maxFileSize` defaults to empty; `CancelPreviewGeneration` is empty. The new reader has finite byte/line limits; a strict highlighting deadline remains open. |
| P2 | Thumbnail path reads the complete source merely to detect encoding. | `GenerateThumbnailForURL.m:22`; thumbnail cancellation occurs after that read. Modern thumbnails are intentionally deferred. |
| P2 | Failed legacy generation is reported as success. | `GeneratePreviewForURL.m:23–28` does not propagate child status and returns `noErr`. Modern provider throws read/encoding errors. |
| P2 | Documentation exceeds actual settings support. | README still advertises `rtfRender`, `webkitTextEncoding`, `hlThumbTheme`; current preview/thumbnail code does not implement those behaviors. Legacy docs are now labeled historical. |
| P2 | Packaging / CI cannot support a maintained modern release as written. | Travis workflow; `Package` phase copies absent `ReadMe.txt`, `LICENSE.txt`, `ChangeLog.txt`; old submodule/toolchain assumptions. Modern build is independent and resources are pinned. |
| P2 | File-type claims are inconsistent and overly broad. | Dynamic `dyn.*` identifiers and `public.text` in old `Info.plist`; `.ts` collision is documented upstream. Modern concrete declarations need Finder evidence. |

The installed 4.1.0 generator and its `highlight` helper are both x86_64 binaries.
The historical Highlight and Lua submodules are pinned but uninitialized locally;
this review did not audit all vendored engine code. No full vulnerability assessment
of either highlighting engine is claimed.

## Design decision and tradeoffs

The prototype uses a self-contained Swift app with a data-based Quick Look extension
and a pinned highlight.js common-language bundle running in JavaScriptCore. User
source is passed as strings, not evaluated. Generated HTML escapes source and names;
CSP blocks scripts/resources, inline CSS is allowed, and the companion web view has
JavaScript disabled. Both targets are sandboxed with read-only user-selected-file
access and no network entitlement.

Replacing André Simon's Highlight avoids carrying the old shell/C++/Lua integration
into a modern extension, but loses theme/flag/plugin parity and some language coverage.
That is an explicit prototype tradeoff, not an invisible compatibility claim. A release
must decide whether to complete this route or embed a current native Highlight library.

An existing maintained alternative is
[Syntax Highlight](https://github.com/sbarex/SourceCodeSyntaxHighlight), which credits
QLColorCode as inspiration and already targets modern extensions. Its latest release
observed was 2.1.32 on September 16, 2026. It is a useful benchmark and a possible
collaboration destination if maintaining another implementation proves unnecessary.
No maintainer was contacted.

## Verification and release gates

The working host is macOS 27.0.1, build 26A434, Apple Silicon, Xcode 27.0 (27A266a).
A normal sandboxed identity check showed zero identities; a direct authorized check
confirmed an existing Developer ID Application identity. No certificate was created,
exported, or used to sign this development build.

Evidence currently established:

- The legacy execution regression passes after the one-line fix.
- Swift core tests cover UTF-8/UTF-16 BOMs, incomplete UTF-8 boundaries, empty files,
  CRLF, invalid encodings, binary content, FIFO/directory rejection, symlinks,
  missing files, HTML injection, executable source, truncation, language selection,
  missing-parser fallback, and a timed language corpus.
- Universal arm64/x86_64 app and extension build successfully; embedded resources
  and BSD/GPL notices are present. `codesign --verify --deep --strict` passes for
  the ad hoc development bundle. Xcode disables hardened runtime for this ad hoc
  build, so this does not validate the eventual hardened release.
- Xcode automatically registered the app/UTI declarations from the build directory
  with Launch Services. No manual extension activation or Applications installation
  is implied by that registration.
- Real Launch Services metadata confirms `.ts` is a movie and `.tsx` uses
  `com.microsoft.typescript`. The extension does not claim the movie UTI.
- Opus 5.5 independently reviewed an explicit plan and implementation packet with
  tools disabled. Scope and follow-up are recorded in `REVIEW-EVIDENCE.md`.

Required before stable release:

1. Prove the extension itself is invoked by Finder on Golden Gate, with screenshots
   and registration evidence; companion rendering alone does not count.
2. Add a reliable highlighting deadline / process isolation, cancellation, and
   pathological-input testing. Input size caps alone are not a time bound.
3. Qualify language/file-type behavior with other editors installed, including
   TypeScript's video collision. Avoid broadly claiming `public.data` or video UTIs.
4. Decide supported grammar breadth, theme/font settings and encoding policy;
   make any migration explicit. Preserve literal source and clear truncation.
5. Verify accessibility, keyboard/text selection, copy, scrolling, light/dark mode,
   cold-start latency, repeated preview stability, and actual macOS 15/26 runtimes.
   Intel execution needs Intel hardware or a suitable verified environment.
6. Build a release with Developer ID, hardened runtime, notarization and stapling;
   verify Gatekeeper on a freshly downloaded artifact. Archive source, license
   notices, checksums and the exact toolchain with the release.
7. Test installation, upgrade, coexistence and rollback using the personal tap
   before proposing a Homebrew cask change.

## Homebrew route

There is no private ownership of a cask to take over. We can maintain an upstream
release and contribute a reviewed change to `Homebrew/homebrew-cask`.

The live cask source has `deprecate!` dated 2025-09-22 and `disable!` dated
2026-09-27. The public formula page still labels it deprecated; the dated cask source
and commit history are more precise. Issue #103 quotes an earlier disable date of
September 22; the final source says September 27.

Recommended sequence:

1. Finish a tested signed/notarized `.app` release with an immutable archive/checksum.
2. Offer a clearly named personal tap, for example `masonjames/tap/qlcolorcode`,
   with `app "QLColorCode.app"` and the actual supported OS/architectures. No tap
   or placeholder downloadable release has been published yet.
3. Prepare a short successor proposal and ask the prior maintainer for public
   designation when authorized. Preserve credits, history, GPL obligations and
   the old-release rollback path.
4. Submit a Homebrew PR once its criteria are met. Their shared policy allows
   replacement when the original author designates the fork, or at least two major
   distributions use it as replacement. The cask-specific policy also permits an
   overwhelming-adoption exception. A separate fork cask needs a vendor-prefixed
   token and normal acceptance criteria; a fresh fork does not inherit all of the
   original's eligibility. Acceptance remains the maintainers' decision.

Sources checked on October 4, 2026:

- [Original repository](https://github.com/n8gray/QLColorCode)
- [Intermediate fork](https://github.com/derzzle/QLColorCode)
- [Current continuation](https://github.com/anthonygelibert/QLColorCode)
- [Release 4.1.0](https://github.com/anthonygelibert/QLColorCode/releases/tag/release-4.1.0)
- [Apple's macOS 15 release notes](https://developer.apple.com/documentation/macos-release-notes/macos-15-release-notes)
- [Apple Quick Look UI](https://developer.apple.com/documentation/QuickLookUI)
- [Cask source](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/q/qlcolorcode.rb)
- [Disable commit](https://github.com/Homebrew/homebrew-cask/commit/fd096d79d91e41c3d1e0bdeb59fc12cd0c5f6d98)
- [Acceptable Casks](https://docs.brew.sh/Acceptable-Casks)
- [Package Acceptance Policy](https://docs.brew.sh/Package-Acceptance-Policy)
