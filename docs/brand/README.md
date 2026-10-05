# QLColorCode identity — October 2026

Keep the QLColorCode name and its history. The mark connects **Quick Look** (a
Q-shaped magnifier), **Color** (syntax-colored strokes), and **Code** (brackets).
The companion's “Source previews since 2007” credit acknowledges the original
project without putting a date into the app name or icon.

Two concepts were generated with the built-in GPT image tool, not the API/CLI.
The tool did not expose a specific model version. Exact prompts are retained in
[PROMPTS.md](PROMPTS.md). Both master PNGs are 1254 × 1254 with alpha.

- [Prism Q](prism-q-v1.png): the selected app identity. A dark tile
  with colored code strokes forming the Q. Its silhouette is distinct at small
  sizes; the interior brackets become an accent at 16 px.
- [Source Sheet](source-sheet-v2.png): an alternative that recalls classic Mac
  document icons. It remains a concept: the generated light edge has stray alpha
  pixels even after one cleanup pass. It is not bundled in the app.

Mason selected Prism Q on October 4, 2026. No upstream endorsement, handover or
Homebrew affiliation is implied by either concept. These assets accompany the
project under its GPL-3.0-or-later terms to the extent rights apply; no third-party
logo or stock artwork was supplied to the image model.

## App asset

The app target's `App/Assets.xcassets/AppIcon.appiconset` contains standard macOS
icon sizes. Only the app bundles the icon. The companion loads the bundled
`AppIcon` by name, so stale Launch Services artwork does not affect its header
and there is no second branding image to maintain.

Each physical size is a direct resampling of `prism-q-v1.png` with Apple's `sips`:

```sh
sips -z 32 32 docs/brand/prism-q-v1.png --out modern/App/Assets.xcassets/AppIcon.appiconset/icon-32.png
```

Repeat for 16, 64, 128, 256, 512 and 1024 pixels. The catalog reuses an image where
a 1× and 2× slot have the same physical dimensions. No color, geometry or alpha
editing is performed during packaging. The checked-in assets require no image
generation service at build time.

Apple's [asset-catalog guidance](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)
requires macOS size variants. A conventional catalog supports the macOS 15
deployment target without adding a layered-icon toolchain to this small utility.
