# Security policy

QLColorCode previews files that may come from untrusted sources. Source execution,
network requests, sandbox escapes, parser hangs and unsafe file handling are
security-relevant reports.

## Report privately

Use GitHub's [Report a vulnerability](https://github.com/masonjames/QLColorCode/security/advisories/new)
form for this repository. Do not open a public issue with exploit details or post
private source files. Include the affected revision/build, macOS version, a minimal
synthetic reproducer and the observed impact. Never include credentials or personal data.

The maintainer will coordinate investigation and disclosure through the private
report. No response-time promise is made while this is a small volunteer project.

## Supported scope

The modern development branch is the focus of this fork. There is no stable
modern release yet and no security guarantee for development builds. The old
4.1.0 generator is not a supported binary from this fork; a legacy reader fix in
this repository does not patch an already installed 4.1.0 generator.

The architecture uses bounded reads, escaped HTML and sandboxed app/extension
bundles. Grammar execution runs in a killable child with a one-second parent
budget and a two-second self-termination alarm if the host dies. The child inherits
its parent's sandbox; this contains parser hangs and crashes, not privileges.
Timeout, cancellation, invalid output and parser failure fall back to escaped plain
text. Source text is passed as data, never executed. See the [roadmap](docs/ROADMAP.md).
