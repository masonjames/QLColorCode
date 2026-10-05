# Road to a stable modern release

The [first public beta](https://github.com/masonjames/QLColorCode/releases/tag/v5.0.0-beta.1)
is available as a notarized DMG and through the custom tap. The next milestone is
runtime and accessibility qualification across the intended support matrix. A public beta requires the bounded parser, observed local runtime/install trial and
notarized distribution gates in [the release policy](RELEASING.md). The complete
platform and accessibility matrix below remains a requirement for a stable release. No release date is promised.

## Established locally

- Modern Swift companion and sandboxed Quick Look preview extension.
- Universal builds, pinned grammar resources and preserved license notices/history.
- Automatic wrapping, logical line numbers, Unicode selection and light/dark colors.
- Prism Q identity, selected by the maintainer.
- Notarized downloaded companion and Finder previews on Golden Gate 27.0.1 /
  Apple Silicon, with local install and rollback verified.
- Bounded sandboxed XPC parsing, cancellation/recovery checks, and native/Rosetta tests.

[Detailed evidence](REVIEW-EVIDENCE.md) records what each check actually covered.

## Qualification roadmap

| Priority | Outcome | Evidence needed |
| --- | --- | --- |
| 1 | A stuck grammar cannot hold a preview indefinitely | Complete for beta: sandboxed XPC service, caller deadline, service alarm, cancellation and recovery tests |
| 2 | Repeatable local verification | Dagger receipts plus native core, WebKit and universal-bundle checks; Sequoia and Intel runtime results collected separately |
| 3 | Finder is qualified on declared platforms | Exact source/artifact receipts, extension path, representative UTIs, repeated previews, wrapping, copy and failure recovery on macOS 15/26/27 where hardware supports them |
| 4 | Accessible reading | Keyboard and VoiceOver checks, selection/copy roundtrip, light/dark contrast and readable truncation/error states |
| 5 | A trustworthy downloadable app | Complete for beta: signed, notarized/stapled DMG, immutable URL/checksum and quarantined-download Gatekeeper trial |
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

Collect real usage and compatibility reports from the versioned beta and
maintainer-owned tap. Prepare the [successor proposal](SUCCESSOR.md) with the
previous maintainers and Homebrew's public criteria. No reputation metric or
endorsement is inherited simply by creating a fork.
