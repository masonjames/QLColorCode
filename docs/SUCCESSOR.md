# Successor readiness

We want QLColorCode to be useful and maintainable again, and eventually suitable
for Homebrew. This fork is not currently designated as the official successor.
This document is a preparation record, not a submission or endorsement.

## Policy checked October 4, 2026

Homebrew's [shared acceptance policy](https://docs.brew.sh/Package-Acceptance-Policy)
requires active maintenance, public presence and public interest. For replacement,
it recognizes public successor designation by the original project/author or use
as the replacement by at least two major distributions. Other acceptance criteria
still apply. Its [cask policy](https://docs.brew.sh/Acceptable-Casks) also allows an
overwhelming-adoption exception and requires a vendor-prefixed token/filename for
forks packaged alongside the original.

A new GitHub package normally needs 30 forks, 30 watchers or 75 stars; owner
self-submissions have higher thresholds of 90/90/225. Repositories under 30 days
old are normally ineligible. Metrics apply to the canonical upstream, not an
unendorsed mirror. Our fork was created October 4, 2026 and currently has no
independent adoption evidence. We will not manufacture popularity or call this
an official continuation without a public basis.

For a macOS cask, the declared OS/architecture combinations must work, and the
artifact must pass Gatekeeper without bypasses. Downloads must come from the
developer or an endorsed source. The final decision belongs to Homebrew's maintainers.

## Evidence packet

| Requirement | Current state | Next proof |
| --- | --- | --- |
| Clear public project | Branded README, build/contribution guides, history and selected icon | Keep the default branch and documentation current |
| Maintained source | Modern implementation, review records and local tests | Repeatable local Dagger receipts and a dependable review/release process |
| Preserved lineage | Original history, credits and licenses retained | Continue crediting predecessors; no unilateral handover claim |
| Supported runtime | Local Golden Gate / Apple Silicon evidence | Sequoia, Tahoe, Intel and Finder/lifecycle qualification |
| Safe distribution | Notarized beta DMG, stable URL/checksum and quarantined-download trial | Repeat the release process for future versions |
| User migration | Legacy generator preserved; local beta install/rollback verified | Keep collecting migration and future-version upgrade reports |
| Successor status | No designation; nobody contacted | A public, voluntary statement from an appropriate prior maintainer/project |
| Independent interest | Not established | Real user reports and community contributions over time |

[The roadmap](ROADMAP.md) orders the technical work. Homebrew's
[upstream guidance](https://docs.brew.sh/Working-with-Homebrew-as-an-Upstream-Project)
favors stable release URLs, checksums and public, constructive packaging discussions.
The [third-party tap](https://github.com/masonjames/homebrew-tap) is the initial distribution route.
Do not file an official cask replacement before there is a reviewable artifact.

## Maintainer outreach draft — not sent

The existing [upstream disablement discussion](https://github.com/anthonygelibert/QLColorCode/issues/103)
is useful context. A first message should ask for technical/maintenance feedback,
not assume a transfer. Send only with the maintainer's explicit approval:

> Hi Nathaniel and Anthony — I'm working on a modern macOS revival of QLColorCode
> at https://github.com/masonjames/QLColorCode. It preserves the project's history
> and credits, and adds a Swift companion with a sandboxed Quick Look extension.
> A notarized beta is available; the repository documents its tested behavior and
> remaining compatibility work. I'd value your feedback on the direction and how best to
> continue the project responsibly. If the implementation and maintenance plan
> earn your confidence, would you be open to discussing public successor
> designation? There is no assumption of a handover or request for credentials.

Before sending, refresh the repository and release status, pick the appropriate
public channel, and replace any stale detail. Public designation is a discussion,
not a condition we can satisfy ourselves. No maintainer has been contacted.
