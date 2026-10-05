# Review and verification evidence

Date: October 4, 2026. Baseline: upstream `18765d8f0dacc9d0b8f01b5e296004b06b974f8c`.

## Independent review

Mason explicitly approved sending bounded QLColorCode plan/code packets to Anthropic.
Claude CLI 2.1.288 ran Opus 5.5 with tools disabled, an empty strict MCP configuration,
hooks disabled, no setting-source discovery, and session persistence disabled. No
credentials, signing private keys, personal files, or customer data were included.
Actual model identifiers were verified from `modelUsage`, not inferred from an alias.
The reviewer did not run builds, inspect the repository or test the app.

| Packet | Actual model | Input SHA-256 |
| --- | --- | --- |
| plan | `claude-opus-5-5` | `2b0394bfc3c4194d4eb029b8a209a3cae0a1c08bb4f6a01e6bd38ee138d4c08e` |
| implementation | `claude-opus-5-5` | `25e70903fe9d883e1a89e5dce54253903734fee60804e26bb01d7505b66d52ac` |
| followup | `claude-opus-5-5` | `9475c67d94df03293e64dd1b4c21265ad12513a9f0f94bfdd0262aca2cc78426` |
| WebKit startup fix | `claude-opus-5-5` | `20dfe81a67d32080120c2b6e6c6865a64da5529ff4180498cef8451cb47bf440` |

The plan covered the proposed architecture and legacy findings. The implementation
packet covered the Swift reader/renderer/provider/app, XcodeGen specification,
Swift and legacy regression tests, build/test scripts, and dependency provenance.
The follow-up covered the final reader/renderer, project specification, core tests,
bundle verifier, and actual legacy script plus regression. It found no blocker to
local development; it did not approve a public release.

Issues fixed from review: concrete UTI variants, resource packaging verification,
trailing-newline/6,000-line counting, UTF-16 boundary coverage, strict truncated
UTF-8 prefixes, form-feed handling, explicit fallback notice, sticky gutter,
minimum OS metadata, removal of movie-extension claims and HTML/script parent
claims, and removal of reserved-namespace imported YAML/TOML declarations.

The final follow-up's small configuration recommendations were implemented and
checked by the parent agent after that review: explicit universal architecture
settings, explicit minimum system version on the extension, and recording actual
code-signing flags. No claim that those final configuration edits received an
additional independent review is made.

Outstanding review items remain in `REVIVAL-REVIEW.md`: highlighting wall-clock
bound, broader Finder-hosted behavior, dataless/cloud files, older OS
and Intel runtime qualification, encoding policy, UX polish and feature parity.

## Parent verification

- Harmless legacy regression demonstrated execution before the one-line fix, then
  passed after it. The installed generator's script was read back and still has
  the old branch; no installed artifact was replaced.
- 57 core assertions passed, including 14 parser fixtures (about 0.16 seconds on
  the development host). Those timings are for the CLI harness, not a hardened
  or Finder-hosted extension. Full harness process is bounded to 30 seconds.
- Modern app and embedded extension build for arm64 + x86_64 on macOS 27.0.1 /
  Xcode 27.0. Both bundles pass the post-build verifier: exact resource hashes,
  license notices, macOS 15 minimum, preview-extension metadata, architecture
  slices, sandbox entitlements, and strict signatures. The companion app now has
  the network-client entitlement required by WebKit; the extension does not.
  Neither target has network-server, JIT, or disabled-library-validation entitlements.
- Default builds remain ad hoc. With Mason's explicit approval, both bundles were
  also signed locally with Developer ID and verified with hardened runtime enabled.
  These diagnostic builds have no secure timestamp and are not notarized.
- Property lists and entitlements pass `plutil -lint`; `git diff --check` passes.
- UTI lookup in the filesystem sandbox produces dynamic identifiers because its
  Launch Services view is incomplete. A direct read outside the sandbox confirms
  real `.ts` movie and `.tsx` TypeScript identifiers; the two observations are not
  interchangeable.
- Xcode automatically registered the build's app/UTIs with Launch Services. That
  makes the extension discoverable and is a real machine-state side effect.
  The separately approved installed trial below records installation and activation.
- Hosted CI, signed distribution, notarization and Gatekeeper acceptance had not
  run at this stage. No live workflow was configured. The earlier workflow candidate
  was subsequently replaced by the local Dagger release pipeline recorded below.

## Visual / Finder evidence

The initial delegated Computer Use call stalled and was interrupted after approximately
649 seconds without returning state. It supplied no visual evidence. The parent
then opened the app and selected `modern/Core/SourceDocument.swift` through the file
picker. The filename appeared, but the ad hoc build's preview area remained blank.

Mason explicitly approved signing and testing a local Developer ID build, without
installation, notarization or publication. The unchanged source at `b63d6a1` passed
strict signature verification with hardened runtime on both app and extension. Its
companion preview still remained blank. The app process started after signing;
WebKit's matching GPU and Networking helper logs reported: "Application does not
have permission to communicate with network resources. rc=1 : errno=34". Signing
alone did not fix the failure.

The bounded WebKit fix adds the network-client entitlement only to the companion
app. Before loading local HTML it installs a block-all-resource content rule;
JavaScript remains disabled, storage is nonpersistent, CSP remains in the generated
document, and navigation allows only the synthetic main-frame `about:blank` load.
Quick Look's separate host renderer relies on the escaped HTML and CSP, not these
companion-only WebKit controls. No actual network-traffic capture has been performed.

Opus reviewed the app/view, renderer, preview provider, project specification and
bundle verifier. It correctly identified a Swift 6 optional-delegate signature
mismatch, confirmed in the build log. The parent switched to the async delegate,
made Swift warnings fatal, added private-content-free diagnostic logging, a
10-second WebKit-load watchdog, completion tracking, visible failure states and
stale-document clearing, and asserted hardened runtime for non-ad-hoc signatures.
The watchdog bounds WebKit loading only; it does not bound JavaScriptCore parsing.
These review corrections were checked by the parent, not a fifth external review.
The corrected universal signed build passed with no Swift warnings.

The signed companion app then rendered `SourceDocument.swift` with syntax colors,
a line-number gutter and the expected 135-line header. The delegated test observed
vertical scrolling from lines 1–22 to 23–48. The parent inspected the screenshot,
repeated the scroll, and selected both import statements; the accessibility readback
contained the exact source and excluded gutter numbers. Runtime logs confirmed that
the corrected navigation-policy delegate ran and WebKit finished loading. Clipboard
copy and network-traffic isolation have not been independently verified.
A second synthetic fixture showed eight numbered lines, accented text, Japanese,
emoji, and literal script/image/entity markup without interpreting it as HTML.
Horizontal-scroll attempts over the scroll area and long line produced no visible
movement; reaching the long line's end remains unverified and requires follow-up.
This was not a passing automated horizontal-scroll result. During the installed
trial Mason subsequently confirmed that horizontal scrolling works (`user_report`).

Screenshots and a signed bundle hash/entitlement manifest are retained under ignored
`build/evidence/`; signed binaries and personal receipts are not published.

## Approved installed trial

Mason subsequently approved installing this exact verified build in his user
Applications directory and enabling only QLColorCode Preview. The destination was
empty. The copied bundle matched the signed-build manifest byte for byte and
passed strict signature verification. The complete legacy generator bundle's
hashes were recorded before installation and remained unchanged afterward;
Homebrew still reports the old 4.1.0 installation.

The previous extension election was `default`; the trial sets it to `use`.
An initial Finder preview reused a running copy from the build directory. After
closing that preview, the parent unregistered only the development app and stopped
that exact stale extension process. This left a single enabled registration from
the installed app. No global cache reset or unrelated provider change occurred.

Finder then displayed `SourceDocument.swift` with QLColorCode branding, 135 lines,
syntax colors and a gutter. The parent inspected the screenshot and independently
verified the running extension executable came from the installed app. This proves
Finder invocation on this host, not compatibility with every file type or OS.
The private local receipt in `build/evidence/installed-trial.json` records exact
hashes, original registration, selected installed path, and process provenance.

The Finder fixture matrix on this host produced these observed results:

| Input | Observed Finder result |
| --- | --- |
| Swift, Python, JavaScript, TSX, Rust, Go, YAML, C header | QLColorCode header, syntax colors, expected line count and gutter |
| TOML | Colored source and correct line count; header exposes the grammar name `ini`, a polish issue |
| BOM-marked UTF-16 Python | Two highlighted lines, preserving accented text, Japanese and emoji |
| Extensionless Makefile | Highlighted three-line preview via `public.make-source` |
| 68 KB Python fixture | 1,501-line plain-text preview with highlighting-unavailable notice |
| Oversized Python fixture | 5,626-line bounded preview with explicit beginning-of-file and highlighting notices |
| Binary bytes in a `.py` file | Provider error in scoped logs; Finder metadata/thumbnail fallback; subsequent previews still work |
| Unknown `.qlunknown` file | Finder metadata fallback |
| TypeScript `.ts` | Finder metadata fallback; actual content type is still `public.mpeg-2-transport-stream`; compatibility gap remains |

Source selection excluded gutter numbers and vertical scrolling advanced to later
lines. The parent independently exercised the large/truncated/binary/unknown/TS
and Makefile cases and inspected representative delegated screenshots. Horizontal
scrolling is confirmed by Mason, not by the inconclusive automated gestures.
The local `finder-language-results.json` and `finder-edge-results.json` receipts
retain per-file observations and screenshots. Light appearance, clipboard-copy
roundtrip, iCloud/dataless files, cold-start timing, older macOS and Intel execution
remain untested. These checks do not establish a hard highlighting time bound.

No notarization, public binary release, Homebrew cask change, or legacy installed
generator replacement has occurred.

## October 4 polish pass

The next changeset adds automatic wrapping, friendly language labels, and the
Prism Q app icon, subsequently selected by Mason. Logical-line wrappers close and reopen Highlight.js
token spans across newlines. This preserves multiline highlighting, indentation
and literal selectable text while keeping each number beside its original line.
There is no wrapping preference to configure. The identity concepts, exact GPT
image prompts, packaging steps and selection are under `docs/brand/`.

Three additional public-source packets were reviewed through Claude CLI with
tools, MCP servers, hooks and session persistence disabled. All three responses
report actual model `claude-opus-5-5`; screenshots and private trial receipts were
not supplied. The image assets were inspected locally, not by this text reviewer.

| Packet | SHA-256 | Scope |
| --- | --- | --- |
| Polish plan | `9957a6e4816b8178989c4ca43179b35d2433232579564389ccccfb19b1ad4a15` | Per-line HTML, selection, language labels, standard app-icon packaging |
| Polish implementation | `d2f8d5cdd723cf01b0deb01528109cda083e15bd0f50905b5ecd125928b51861` | Renderer, labels, app header, icon catalog metadata, bundle verification and tests |
| Polish follow-up | `b29b02e618b646729dd4b8f0c85e57296a59c9bb146e5cd1e30847091d92aae4` | Unicode-scalar tokenization, literal escaping and strengthened WebKit assertions |

The implementation review identified a real safe-fallback bug: Swift's default
grapheme regex semantics could merge a closing `>` with a following combining
mark. The parent reproduced `keycap.js` losing highlighting, changed both token
regexes to Unicode-scalar semantics, and proved the regression passes. Tests now
reject silent highlighting loss and exercise nested, multiline, multi-class spans.

The follow-up raised a conditional CRLF concern because the packet omitted the
reader's existing newline normalization. The parent verified `SourceDocument.read`
normalizes CRLF and CR before rendering; additional end-to-end core cases prove
CRLF with/without a terminal newline and mixed endings retain the final line.
No reader change was needed. The reviewer did not run builds/tests. Its remaining
observations about full VoiceOver, pasteboard, token colors and icon appearance
are not converted into passing evidence.

Final local gates:

- Legacy regression, pinned-resource checks and 72 core assertions pass, including
  14 rendering fixtures and the CRLF/combining-mark regressions.
- `scripts/test-preview-layout.sh` runs the actual renderer in WebKit: 484 assertions
  over 13 fixtures at 320/960 pixels, in light/dark appearance. DOM text, Range text,
  full and partial selection retain normalized source. Tests check logical-line
  count/contiguity, no horizontal overflow, continued comment tokens, long-token
  wrapping, visible truncation, readable TOML labels, no silent highlighting
  fallback and the actual body background for each appearance. This is selection
  evidence, not an actual pasteboard roundtrip or full accessibility audit.
- Universal Developer ID development builds pass strict signatures, hardened
  runtime, resource, entitlement and icon-bundle checks. The icon is present only
  in the app; the extension has no asset catalog. No timestamp/notarization claim.

The signed companion UI showed the long comment wrapping over eleven visual rows
at its original window width and seven after widening, with all six logical line
numbers aligned. The TOML fixture displayed `TOML · 3 lines` and colored source.
The first header used a cached generic application icon; loading the bundled
`AppIcon` by name fixed it. A rebuilt signed app visibly shows Prism Q and the
2007 credit. The parent inspected the screenshots, rechecked the build gates and
verified the running companion executable came from the development build path.
This final icon lookup is a small parent-reviewed correction after the external
packets. The installed modern app and legacy generator still match their original
trial manifests (19 and 498 files respectively).

Private receipts and screenshots remain in ignored `build/evidence/`. The earlier
installed Finder trial has not been replaced by this polish build. Finder reflow,
macOS 15/26, Intel execution, VoiceOver and downloaded Gatekeeper qualification
remain separate gates. Hosted CI has not run; the WebKit step is added only to the
existing manual workflow template.

## Community presentation and local release pipeline

October 4, 2026: Mason selected **Prism Q**. The README now uses the selected icon
and an actual companion screenshot of the public `examples/Palette.swift` fixture.
Build/contribution guides, structured bug/compatibility forms, a security policy,
roadmap and successor preparation notes are included. GitHub private vulnerability
reporting was enabled and read back as enabled. No predecessor or Homebrew
maintainer was contacted, and no successor designation is claimed.

The workflow candidate was removed at Mason's request. Local Dagger 0.21.10 runs
portable checks in a digest-pinned official Python container; native macOS performs
Swift/WebKit checks, universal Release builds and DMG packaging. GitHub reported
**zero workflows and zero Actions runs**. Nothing depends on a hosted runner.

The parent executed the final reviewed rehearsal on macOS 27.0.1 (26A434), arm64,
Xcode 27.0 (27A266a):

- Dagger: 17 release-boundary regression tests and vendored-resource hashes passed.
- Native: legacy regression, 72 core assertions / 14 fixtures, and 484 WebKit
  assertions / 13 fixtures passed.
- Fresh universal Release app and extension passed resource, entitlement, icon,
  strict signature and both Mach-O slices' macOS 15.0 deployment-target checks.
- A 2.4 MB compressed DMG was created, verified and mounted read-only. The mounted
  bundle, Applications shortcut, install note and license passed verification;
  the image was detached without launching or installing it.
- The [sanitized rehearsal receipt](releases/2026-10-04-rehearsal.json) records the
  exact DMG and source-snapshot hashes, base commit, dirty-tree status and toolchain.
  The filename is marked `LOCAL-ONLY`; its ad hoc signature is **not** notarization.
- The installed app's 19 files and legacy generator's 498 files remained identical
  to their earlier manifests. Only the installed preview provider remained registered.
- Local documentation links, issue-form YAML, the Swift example, generated cask
  Ruby syntax and `git diff --check` passed. No tap install/audit/fetch is claimed.

Three additional explicit public-source packets received tool-disabled Opus review:

| Packet | Actual model | Input SHA-256 |
| --- | --- | --- |
| Release plan | `claude-opus-5-5` | `0284f4ae61d1bee17c8430eceabcdaf72d7d7f001328a1532d9b35ad7e3653e8` |
| Release implementation and community docs | `claude-opus-5-5` | `adf8e80a98e7020610d883ef76cf9410ef1cd6c5709072ef1d33a422c2b1d128` |
| Release safeguard follow-up | `claude-opus-5-5` | `a104f9bd4d11bbcfdf055845301fb0dc221a381c17cdf74f09a208e91ff5b459` |

The implementation review led to separate JSON stdout parsing, compiled deployment
checks, a Python-optimization guard, explicit existing-release detection and
Gatekeeper source/status checks. The follow-up found no blocker to publishing
**development source and docs**, conditional on the final 17-test rehearsal; the
parent subsequently confirmed that complete pass. The reviewer ran no commands.

The qualified signing/notarization/draft-upload path has not run end to end. Its
[readiness gates](release-readiness.json) remain false. No public DMG, live tap,
notarization, fresh-download Gatekeeper trial or broader runtime compatibility is
claimed. The next release work is parser cancellation/deadline, platform and
accessibility/install qualification, and an authenticated notarization trial.

## First beta subprocess attempt (October 4, 2026)

The initial attempt used a stoppable executable with inherited sandbox. It passed
companion and CLI checks, but **failed the installed Finder trial**: Quick Look
rejected direct child-process creation. This implementation is superseded by the
XPC correction below and is not release qualification.

Tool-disabled Anthropic review used **claude-opus-5-5** for the plan and explicit
implementation packet. No account data, credentials or private files were supplied.

| Review | Packet SHA256 | Coverage |
| --- | --- | --- |
| beta-plan | `4e4442db351606888c0f347d12f2f821f5c7b8997a5747a8870dde7ef323dd05` | Parser process boundary and separate beta/stable release policy |
| beta-implementation | `52d4b40f4d6c98edb5374e0349d72e99d46f50fb6786f7c7490f0e4b6b0f5bdc` | Parser/client, cancellation, project specification, tests, signing verification and release policy |

The review found no code blocker and approved a signed local trial. Publication
remains conditional on a final committed-build rerun, actual installed Finder
highlighting near the input limit, upgrade/rollback, notarization, and testing the
draft's downloaded artifact before publishing. The generated project and unchanged
reader were outside this packet; native builds and prior reviews cover them.

Initial implementation checks passed: 72 core assertions / 14 fixtures, 12 parser
boundary checks (including an auto-reaping host), orphan exit after parent death,
and 484 WebKit assertions / 13 fixtures. Local Dagger passed 18 release-policy
tests and vendor hashes. The signed universal Release bundle has hardened runtime,
secure timestamps and exactly sandbox/inherit entitlements on its helper. The
first 11 parser checks, core and orphan test also passed as x86_64 under Rosetta;
that is not Intel hardware qualification. Final install and release evidence will
be recorded separately. macOS 15/26, Intel hardware and VoiceOver remain unverified.

## XPC correction and current qualification

Actual Finder testing caught a platform restriction missed by the subprocess plan.
Apple DTS describes this restriction in the
[Swift Forums discussion](https://forums.swift.org/t/running-a-script-from-within-swift-app-qlextension/70226).
The correction uses a native embedded XPC service, the same mechanism used by
[SourceCodeSyntaxHighlight](https://github.com/sbarex/SourceCodeSyntaxHighlight).
It has only the App Sandbox entitlement, no inherited user-file/network grants.
The pipe/spawn implementation and its descriptor probes were removed.

The corrected service initializes JavaScriptCore on its main thread. CLI hosts
using real sandboxed, hardened XPC services pass the 72 core assertions and
16 XPC boundary checks,
including timeout, cancellation, exception, bounds, contention, alarm disarming
and recovery. A separate test
asserts the service is alive before killing its host, then verifies termination.
The recovery test allows launchd's restart delay; individual previews still stop
waiting after one second. Ad hoc test services use their own bundle identifiers.

The final XPC implementation passed the same core, 16 parser, orphan-termination
and 484 WebKit checks as both arm64 and x86_64 under Rosetta on macOS 27.0.1.
Rosetta is not physical Intel qualification. The Developer ID-signed universal
candidate passed both embedded service identifiers, pinned resources, macOS 15.0
deployment targets, exact sandbox entitlements, hardened runtime, secure timestamp
and expected-team checks. Local Dagger passed all 18 release-policy tests and
vendor hashes; the full local-only DMG rehearsal passed before the final bounded
lock and service-identifier assertion were added. The qualified release pipeline
must rerun those checks against its final source tag.

Three tool-disabled reviews used `claude-opus-5-5`; only public source and sanitized
test outcomes were included:

| Review | Packet SHA256 | Coverage |
| --- | --- | --- |
| XPC plan | `350b1c3732c58333757743738527d3333c6ecff140cfadd41acead6a65aa49bf` | Native service boundary, sandbox and runtime proof |
| XPC implementation | `248972e04345c25e4ce1eee2870e676ba144fea0dbc8441e4731d2b774da9588` | Client, service, packaging, tests and release verification |
| XPC final addendum | `3996c7dda74df9b46cfd7d77bff806f97fe30dbe4936176ab5800814cb5a95e4` | Bounded contention, alarm disarming, architecture test target and service identifier assertion |

The final review found no code blocker in its four-file packet. Its requested
current-code Rosetta rerun and real Developer ID signature checks subsequently
passed. Finder, rollback and notarized-artifact checks remain separate gates.

A signed disposable host and the installed companion returned/displayed actual
colored Swift. Earlier Finder checks were inconclusive: blank/disappearing previews were observed,
and concurrent Finder use contaminated a later diagnostic. They are superseded by
the coordinated qualification below; no failure was counted as a pass.


## Coordinated signed Finder and rollback qualification (October 4, 2026)

The installed universal build 3 from source
`7ba8f302640bed351680d3e01fecdedddd070258` matched all 23 candidate file hashes.
Only the installed extension was registered. On macOS 27.0.1 / Apple Silicon,
freshly verified Finder selections produced:

- `Palette.swift`: actual syntax colors, Swift header and 23 logical lines.
- A 32,430-byte Swift fixture: actual colors and 1,410 logical lines.
- A 34,500-byte fixture: readable, explicitly labelled plain text and 1,500 lines.
- Returning to Palette: normal syntax colors recovered.

The parent inspected the screenshots independently. The saved original signed
build 1 was restored byte-for-byte (19 files), re-registered and exercised in
Finder; it also rendered Palette with actual syntax colors. The verified build 3
was then restored. All 498 legacy-generator files remained unchanged. No global
Quick Look reset, quarantine removal or security bypass was used.

The coordinated trial did not test rapid-browsing stress, VoiceOver or physical
Intel. Earlier WebKit checks cover wrapping and selection; this trial is specific
to installed Finder highlighting, fallback/recovery and reversible installation.
The beta source/runtime gates now pass. Stable platform/accessibility gates remain
open, and notarization plus the downloaded draft artifact still need verification.


## Public beta distribution (October 4, 2026)

[5.0.0-beta.1](https://github.com/masonjames/QLColorCode/releases/tag/v5.0.0-beta.1)
is built from `117e205dfcb388d779a9b43c38c1342c97a8f923` (app build 3).
The tagged pipeline reran local Dagger, all native core/parser/WebKit checks,
and a fresh signed universal build. Apple accepted the app ZIP and DMG without
issues. Both tickets were stapled; the mounted and installed app and DMG passed
Gatekeeper as **Notarized Developer ID** with assessments enabled.

The GitHub draft assets downloaded and matched. A browser download retained
quarantine; its installed app matched all 24 artifact files. The companion ran
under normal macOS App Translocation and showed actual syntax colors. Finder
rendered a new copy of the Swift fixture with actual colors, avoiding an earlier
preview's cache. The parent inspected both screenshots and verified the running
app's executable hash. No quarantine or security setting was removed.

After publication, a download without GitHub authentication matched the tested
DMG SHA256:
`51db8c79aabb31a7e7b4b252b66f8bb024dc145f6bdb5f07038b684feb41fe33`.
The attached `release.json` and `SHA256SUMS` provide the source/tag, toolchain,
notary submission identifiers and immutable artifact hashes.
A fresh browser download from the public release also matched, retained
quarantine, validated its stapled ticket and passed Gatekeeper.

The [custom tap](https://github.com/masonjames/homebrew-tap) pins that same DMG.
Homebrew `7.0.7-103-ga57af19` style, audit and fetch passed, followed by an actual cask installation
to the maintainer's user Applications folder. All 24 installed files matched the
tested artifact, Homebrew quarantine remained present, and signatures, stapling
and Gatekeeper passed again. The earlier manual app was preserved. All 498 files
of the legacy generator remained unchanged; its old cask was not removed.
A fresh-URL Finder preview of the Homebrew-installed app showed actual Swift
colors and 23 lines; the parent inspected its screenshot. A future-version
Homebrew upgrade and clean-machine trial remain unverified.

The tap cask has one style correction from the tagged generator output:
`depends_on macos: :sequoia` replaces `">= :sequoia"`. This Homebrew version
parses the symbol with the `>=` comparator, preserving the minimum requirement.
The generator and its existing test now emit the accepted shorthand. The DMG,
release tag and checksum are unchanged.

This is a prerelease, not GitHub's latest stable release. macOS 15/26, physical
Intel and VoiceOver qualification remain open. No Homebrew central-cask acceptance
or predecessor endorsement is claimed.

Both the app repository and custom tap had **zero GitHub Actions runs** after
publication; local Dagger and native macOS performed the build and verification.

The public-download documentation and cask correction received a tool-disabled
Claude CLI review using **`claude-opus-5-5`**, packet SHA256
`bffc4ee771ad6981691b6d01f519e5127d35807b1b6931434f7dbf6023a8d8b8`.
It found no release blocker. Its pending Finder condition subsequently passed;
the parent clarified Rosetta coverage, the first-tap upgrade limitation and the
cask correction above. The 18 release-policy tests and local documentation links
passed. Review covered the explicit packet, not independent access to runtime
evidence or this follow-up receipt.
