// SPDX-License-Identifier: GPL-3.0-or-later
// Test-only resource. Release verification requires the real pinned grammar hash.
var hljs = {
  getLanguage: () => true,
  highlight: source => {
    if (source === "loop") { while (true) {} }
    if (source === "error") throw new Error("Synthetic parser failure");
    return { value: source === "oversize" ? "x".repeat(1024 * 1024 + 1) : "recovered" };
  }
};
