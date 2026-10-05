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

The latest modern beta and development branch are the focus of this fork. There
is no stable modern release yet. Please report security issues in the published
beta through the private form above. The old
4.1.0 generator is not a supported binary from this fork; a legacy reader fix in
this repository does not patch an already installed 4.1.0 generator.

The architecture uses bounded reads, escaped HTML and sandboxed app/extension
bundles. Grammar execution runs in an embedded XPC service with its own App Sandbox,
no network or user-file entitlements, a one-second caller budget and a two-second
service alarm. Source text and language cross IPC as strings; source is never
executed. Timeout, cancellation, invalid output and parser failure fall back to
escaped plain text. macOS may briefly delay restarting a terminated service;
previews stay readable during that interval. See the [roadmap](docs/ROADMAP.md).
