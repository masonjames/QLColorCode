# Successor readiness

We want QLColorCode to be useful and maintainable again, and eventually suitable
for Homebrew. This fork is not currently designated as the official successor.
This document is a preparation record, not a submission or endorsement.

## Policy checked October 5, 2026

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

On October 5, GitHub's API reported zero stars, subscribers and forks. Thirty days after
creation falls on November 3, 2026; that date alone does not establish eligibility.
Successor designation does not automatically waive notability or other criteria.

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

## Path to a reviewable replacement

1. **Not yet sent:** invite the prior maintainer to review the published beta in the existing
   [disablement issue](https://github.com/anthonygelibert/QLColorCode/issues/103).
   Ask whether public successor designation would be appropriate after review.
   Preserve the response URL; silence or permission to fork is not designation.
2. Collect reports using the [downloaded-beta checklist](COMPATIBILITY.md),
   including real Sequoia/Tahoe/Intel and accessibility results. Finish the stable
   gates in [the release policy](RELEASING.md) and release the qualified version.
3. Keep the vendor-prefixed tap while gathering independent usage and maintenance
   history. Preserve immutable DMGs and checksums for every release. Do not create
   artificial stars, requests or distribution endorsements.
4. Once there is a public replacement basis and the other criteria are met,
   propose a focused `Homebrew/homebrew-cask` change with the designation,
   qualification evidence and tested modern-app cask.

The current official cask is disabled and still points to Anthony's 4.1.0
generator. We have not submitted a central-cask replacement. If Anthony declines
or does not reply, the custom tap remains the distribution channel; silence is
not approval.

The October 5 `brew audit --new --cask --online` also flags the GitHub prerelease
and the repository's fork status. Those are still open. The same audit originally
found update detection pointing at legacy 4.1.0; the tap's explicit release check
now identifies 5.0.0-beta.1 correctly. A passing tap style/download/install check
does not mean the stricter new-cask audit passes. After designation, discuss the
canonical-repository/fork audit with Homebrew; do not detach history or relabel a
beta as stable to make the audit green. Its fork check runs before notability and
age checks, so the absence of those additional errors is not a pass.

[The roadmap](ROADMAP.md) orders the technical work. Homebrew's
[upstream guidance](https://docs.brew.sh/Working-with-Homebrew-as-an-Upstream-Project)
favors stable release URLs, checksums and public, constructive packaging discussions.
The [third-party tap](https://github.com/masonjames/homebrew-tap) is the initial distribution route.
Do not file an official cask replacement before there is a reviewable artifact.

## Maintainer outreach draft — not sent

The existing [upstream disablement discussion](https://github.com/anthonygelibert/QLColorCode/issues/103)
is useful context. A first message should ask for technical/maintenance feedback,
not assume a transfer. **Not sent. Publish this packet first, then send only after
Mason approves the final text and destination.**

Proposed destination: one comment on Anthony's issue #103, from Mason's account.
No separate notification to Nathaniel or Homebrew is proposed at this stage.

> Hi Anthony — I've published a modern-macOS fork of QLColorCode at
> https://github.com/masonjames/QLColorCode, preserving the original Git history,
> credits and licenses back to Nathaniel Gray's work in 2007.
>
> [5.0.0-beta.1](https://github.com/masonjames/QLColorCode/releases/tag/v5.0.0-beta.1)
> has a free, signed and notarized DMG containing a universal app and a
> [vendor-prefixed Homebrew tap](https://github.com/masonjames/homebrew-tap).
> It uses a modern sandboxed Quick Look extension, automatic wrapping and a
> bounded XPC syntax parser. Installation leaves an existing legacy generator alone.
>
> Actual downloaded-app and Finder tests passed on macOS 27.0.1 / Apple Silicon.
> Sequoia, Tahoe, physical Intel, keyboard/copy and VoiceOver qualification remain open; the
> [test matrix](https://github.com/masonjames/QLColorCode/blob/master/docs/COMPATIBILITY.md)
> and [evidence](https://github.com/masonjames/QLColorCode/blob/master/docs/REVIEW-EVIDENCE.md)
> make those limits explicit. The release process uses local Dagger checks and
> native macOS signing/notarization.
>
> Would you be willing to review the direction and flag anything you'd want
> preserved or changed? If it earns your confidence, would you consider publicly
> designating it as the project's maintained successor? I understand that
> Homebrew's remaining acceptance criteria still apply. I'm not asking for
> credentials or assuming a handover. Thank you for keeping QLColorCode useful.

Before sending, refresh the repository and release status and replace any stale
detail. Public designation is a discussion,
not a condition we can satisfy ourselves. No maintainer has been contacted.
