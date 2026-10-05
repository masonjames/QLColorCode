# Road to a first modern release

The immediate milestone is a reproducible development preview that people can
understand, build and help qualify. A public beta comes after the runtime and
release gates below. No release date is promised.

## Established locally

- Modern Swift companion and sandboxed Quick Look preview extension.
- Universal builds, pinned grammar resources and preserved license notices/history.
- Automatic wrapping, logical line numbers, Unicode selection and light/dark colors.
- Prism Q identity, selected by the maintainer.
- Signed companion checks and an earlier installed Finder fixture trial on
  Golden Gate 27.0.1 / Apple Silicon. The polish build has not replaced that
  installed trial.

[Detailed evidence](REVIEW-EVIDENCE.md) records what each check actually covered.

## Before a public beta

| Priority | Outcome | Evidence needed |
| --- | --- | --- |
| 1 | A stuck grammar cannot hold a preview indefinitely | A stoppable execution boundary, cancellation, and pathological-input tests; input caps alone do not satisfy this |
| 2 | Repeatable local verification | Dagger receipts plus native core, WebKit and universal-bundle checks; Sequoia and Intel runtime results collected separately |
| 3 | Finder is qualified on declared platforms | Exact source/artifact receipts, extension path, representative UTIs, repeated previews, wrapping, copy and failure recovery on macOS 15/26/27 where hardware supports them |
| 4 | Accessible reading | Keyboard and VoiceOver checks, selection/copy roundtrip, light/dark contrast and readable truncation/error states |
| 5 | A trustworthy downloadable app | Developer ID release signing, secure timestamp, notarization, stapling, immutable archive/checksum and Gatekeeper verification after a fresh download |
| 6 | Predictable install, upgrade and rollback | A tested local trial and a separate personal-tap trial, preserving unrelated providers and settings |

The [local release pipeline](RELEASING.md) uses Dagger and native macOS tools.
It has no GitHub Actions dependency. A rehearsal DMG is local evidence, not a
notarized download or a passing compatibility matrix.

## Good bounded contributions

- Follow the build guide from a clean clone and improve any unclear step.
- Supply a minimal `.tsx`, TOML, Makefile or editor-conflict fixture with observed UTI.
- Report a real Sequoia/Tahoe/Intel test using the compatibility form.
- Check keyboard navigation or VoiceOver on the companion before changing code.

Discuss parser isolation, new dependencies and broader file-type claims in an issue
before starting a large implementation. Keep each pull request focused.

## After beta qualification

Publish a versioned release and maintainer-owned tap; then collect real usage and
compatibility reports. Prepare the [successor proposal](SUCCESSOR.md) with the
previous maintainers and Homebrew's public criteria. No reputation metric or
endorsement is inherited simply by creating a fork.
