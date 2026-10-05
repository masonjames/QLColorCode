"""The actual helper must exit even after its parent is killed. No parent timer."""
from pathlib import Path
import os
import shutil
import signal
import subprocess
import sys
import tempfile
import time

with tempfile.TemporaryDirectory(prefix="qlcolorcode-orphan-") as directory:
    root = Path(directory)
    shutil.copytree("build/tests/Parser", root / "Parser")
    (root / "Parser/Contents/Resources/highlight.min.js").write_text("while (true) {}")
    helper = root / "Parser/Contents/Helpers/QLColorCodeHighlight"
    # This intermediary supplies input and remains alive until this test kills it.
    code = '''import json, subprocess, sys, time
child = subprocess.Popen([sys.argv[1]], stdin=subprocess.PIPE, stdout=subprocess.DEVNULL)
child.stdin.write(json.dumps({"source":"let x = 1", "language":"swift"}).encode())
child.stdin.close()
print(child.pid, flush=True)
time.sleep(30)
'''
    parent = subprocess.Popen([sys.executable, "-c", code, str(helper)], stdout=subprocess.PIPE, text=True)
    pid = int(parent.stdout.readline())
    exited = False
    try:
        time.sleep(0.2)
        parent.kill()
        parent.wait(timeout=2)
        deadline = time.monotonic() + 3
        while time.monotonic() < deadline:
            status = subprocess.run(["ps", "-p", str(pid), "-o", "stat="], capture_output=True, text=True)
            if status.returncode or status.stdout.strip().startswith("Z"):
                exited = True
                break
            time.sleep(0.05)
        else:
            raise AssertionError("Orphaned parser did not self-terminate")
        print("PASS: actual helper self-terminates after its parent is killed")
    finally:
        if not exited:
            # A failing watchdog test must not leave its deliberately spinning helper.
            try:
                os.kill(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
        if parent.poll() is None:
            parent.kill()
            parent.wait()
