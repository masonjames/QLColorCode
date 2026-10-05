"""A real XPC parser must not linger after its preview host is killed."""
import os
import signal
import subprocess
import time

host = "build/tests/ParserTests.app/Contents/MacOS/ParserTests"
parent = subprocess.Popen([host, "--orphan"], stdout=subprocess.PIPE, text=True)
pid = None
exited = False
try:
    pid = int(parent.stdout.readline())
    status = subprocess.run(["ps", "-p", str(pid), "-o", "stat="], capture_output=True, text=True, check=True)
    assert status.stdout.strip() and not status.stdout.strip().startswith("Z"), "Parser must be alive before parent death"
    parent.kill()
    parent.wait(timeout=2)
    deadline = time.monotonic() + 3
    while time.monotonic() < deadline:
        status = subprocess.run(["ps", "-p", str(pid), "-o", "stat="], capture_output=True, text=True)
        if status.returncode == 1 or status.stdout.strip().startswith("Z"):
            exited = True
            break
        status.check_returncode()
        time.sleep(0.05)
    assert exited, "Orphaned parser did not terminate"
    print("PASS: live XPC parser terminates after its preview host is killed")
finally:
    if pid and not exited:
        try:
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    if parent.poll() is None:
        parent.kill()
        parent.wait()
