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
bound, real Finder-hosted hardened-runtime behavior, dataless/cloud files, older OS
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
  No manual extension activation or Applications installation is claimed.
- Hosted CI, signed distribution, notarization and Gatekeeper acceptance have not
  run. A manual-only CI template is provided in `docs/ci/verify-modern.yml`; no live workflow is configured. GitHub rejected the first push because the existing OAuth credential lacks workflow scope, so no credential permissions were expanded.

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
This is an outstanding UI check, not a passing horizontal-scroll result.

Screenshots and a signed bundle hash/entitlement manifest are retained under ignored
`build/evidence/`; signed binaries and personal receipts are not published.

Read-only PlugInKit inspection found the new preview extension registered from the
build directory. Finder invocation remains unverified. No manual extension
activation, Applications installation, notarization, public binary release or
installed-generator replacement has occurred.
