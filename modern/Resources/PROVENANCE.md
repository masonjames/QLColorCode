# Bundled highlighter

Highlight.js 11.12.0, the official browser common-language distribution.

- Source: https://github.com/highlightjs/highlight.js/tree/f7f7d3803bd898e37c017ffb881317f0cde04a70
- Distribution: https://github.com/highlightjs/cdn-release/tree/dce7a3dab8f3fd586138ba6c5f29ecc19c02db9f/build
- `highlight.min.js` SHA-256: `8ab71eb09c51f501e5e25157d9cff100e46cc29bcbfc744d0b746d451fca7f53`
- `highlight-LICENSE` SHA-256: `6c081431591d9df696c82dc598fe1423765b8a299b200ed00b281afd0f64c490`
- License: BSD-3-Clause, reproduced in `highlight-LICENSE`.

No runtime download or package installation is required. Source files are passed
as string arguments to the bundled parser; they are never evaluated as JavaScript.
The legacy generator uses André Simon's Highlight, a different engine. Its theme
names, command-line options, and language plugins do not apply to this prototype.
