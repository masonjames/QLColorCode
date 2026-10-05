"""Exercise the legacy reader without launching the bundled highlighter."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "src/colorize.sh"


class LegacyReaderTests(unittest.TestCase):
    def test_header_is_read_and_never_executed(self):
        with tempfile.TemporaryDirectory(prefix="qlcolorcode-") as directory:
            root = Path(directory)
            marker = root / "executed"
            header = root / "header ' $ % spaces.h"
            header.write_text(f"#!/bin/sh\ntouch '{marker}'\n# @interface Sample\n")
            header.chmod(0o700)
            highlighter = root / "highlight-stub"
            highlighter.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\ncat\n')
            highlighter.chmod(0o700)
            result = subprocess.run(
                ["/bin/zsh", "-f", str(SCRIPT), directory, str(header), "0"],
                env={**os.environ, "pathHL": str(highlighter)},
                text=True, capture_output=True, timeout=5,
            )
            self.assertFalse(marker.exists(), "Previewing the header executed it")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("--syntax=objc", result.stdout)
            self.assertIn("# @interface Sample", result.stdout)


if __name__ == "__main__":
    unittest.main()
