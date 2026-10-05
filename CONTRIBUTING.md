# Contributing to QLColorCode

Thanks for helping keep source previews useful on modern macOS. Small, well-tested
changes are welcome. The project is a development preview; a build target or a
screenshot is not proof of release compatibility.

## Find a useful first contribution

| Contribution | What makes it useful |
| --- | --- |
| Test on Sequoia, Tahoe or Intel | Record the OS/build, chip, source revision, signing setup and actual companion/Finder result |
| Report a file-type conflict | Include the extension and `mdls` content type, plus a tiny public or synthetic sample |
| Add a language fixture | Show the bug before the change and the expected source/selection behavior afterward |
| Check accessibility | Describe keyboard or VoiceOver steps and the exact observed behavior |
| Improve a confusing instruction | Follow it from a clean clone and explain where the path breaks |

Use the [issue forms](https://github.com/masonjames/QLColorCode/issues/new/choose)
for bugs and compatibility results. Open a scoped issue before redesigning the
renderer, adding dependencies, broadening file-type claims or changing distribution.
Never include credentials, client code, personal paths or private files in a report.

## Make a change

1. Fork the repository, clone your fork, and create a short-lived branch.
2. Follow [DEVELOPMENT.md](docs/DEVELOPMENT.md) to build the checked-in Xcode project.
3. Keep the change focused. New application code belongs in `modern/`; the root
   Objective-C project is historical.
4. Run the checks relevant to your change. For renderer or app changes:

   ```sh
   bash scripts/test-modern.sh
   bash scripts/test-preview-layout.sh
   bash scripts/build-modern.sh
   ```

5. Open a pull request explaining the problem, resulting behavior and actual checks.
   Say which tests you could not run. Screenshots help with visual changes; never
   substitute them for source, selection or platform checks.

Docs-only changes need link and instruction checks, not a rebuild of the app.
If you change `modern/project.yml`, regenerate the project with XcodeGen and commit
both files. Ordinary builds do not need XcodeGen.

## Review bar

- Is this the smallest change that achieves the outcome?
- Would you be comfortable walking a colleague through every line?
- Are source text, indentation and copy/selection preserved?
- Does the failure path remain readable and safe?

Previewed source is data. Do not execute it, evaluate it as JavaScript, send it over
the network, or add runtime grammar downloads. Keep read limits, sandboxing and
clear truncation. New source should have a GPL-3.0-or-later SPDX header; keep existing
notices. Confirm the license and provenance of any dependency or artwork you add.

Treat people respectfully, discuss behavior and evidence, and make room for users
with different experience levels. Maintainers may remove abusive or off-topic
content. Contributing does not require using an AI tool; AI-assisted changes get
the same line-by-line review and verification as any other contribution.
