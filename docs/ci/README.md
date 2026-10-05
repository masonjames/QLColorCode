# Local verification

QLColorCode uses local Dagger checks and native macOS tooling. There is no GitHub
Actions dependency or enabled workflow. The former workflow candidate has been
removed in favor of the [local release pipeline](../RELEASING.md).

For an ordinary contribution, run the three commands in
[DEVELOPMENT.md](../DEVELOPMENT.md#build-and-check). For packaging and release
receipts, run `python3 scripts/release.py rehearse`. Dagger verifies portable
release boundaries and vendored resources; the Mac runs Swift, WebKit and bundle
checks. Logs identify which environment ran each stage.

Use observed receipts in review. Do not add a green CI badge or claim Sequoia/Intel
runtime coverage from a Golden Gate/Apple Silicon run.
