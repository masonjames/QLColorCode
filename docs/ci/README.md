# Manual verification workflow template

`verify-modern.yml` is intentionally a template, not an enabled GitHub workflow.
The current GitHub CLI OAuth credential cannot create workflow files. The source
can be published without changing its permissions.

To enable CI later with appropriate repository/workflow authority, move the YAML
file to `.github/workflows/verify-modern.yml`, publish that source change, then
manually dispatch it. It builds and verifies a development artifact; it does not
sign with Developer ID, upload releases, notarize, install, or deploy anything.

The same verification is available locally through the scripts in `scripts/`.
No hosted CI result is currently claimed.
