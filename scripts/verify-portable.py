"""Run portable release checks in the local Dagger engine; no SDK dependency."""
import base64
import json
import os
from pathlib import Path
import urllib.request
import urllib.error

from release import DAGGER_IMAGE


def query(document, variables):
    # Use Dagger's documented loopback API. Nested CLI failed with a protocol
    # error in our local 0.21.10 run; this path needs no SDK dependency.
    port = int(os.environ["DAGGER_SESSION_PORT"])
    auth = base64.b64encode((os.environ["DAGGER_SESSION_TOKEN"] + ":").encode()).decode()
    request = urllib.request.Request(
        f"http://127.0.0.1:{port}/query",
        data=json.dumps({"query": document, "variables": variables}).encode(),
        headers={"Content-Type": "application/json", "Authorization": f"Basic {auth}"},
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    try:
        with opener.open(request, timeout=600) as response:
            payload = json.load(response)
    except urllib.error.HTTPError as error:
        raise RuntimeError(error.read().decode()) from None
    if payload.get("errors"):
        raise RuntimeError(payload["errors"])
    return payload["data"]


if __name__ == "__main__":
    if not os.environ.get("DAGGER_SESSION_PORT"):
        raise SystemExit("Run through the release command's local Dagger session.")
    source = query('''query($path: String!) {
      host { directory(path: $path, include: [
        "scripts/release.py", "scripts/verify-source.py", "scripts/verify-bundle.py", "Tests/test_release.py",
        "modern/Resources/highlight.min.js", "modern/Resources/highlight-LICENSE"
      ]) { id } }
    }''', {"path": str(Path(__file__).resolve().parents[1])})["host"]["directory"]["id"]
    result = query('''query($source: ID!, $image: String!) {
      container { from(address: $image) {
        withMountedDirectory(path: "/src", source: $source) {
          withWorkdir(path: "/src") {
            withExec(args: ["python3", "scripts/verify-source.py"]) {
              withExec(args: ["python3", "-m", "unittest", "discover", "-s", "Tests", "-p", "test_release.py"]) {
                stdout
                stderr
              }
            }
          }
        }
      } }
    }''', {"source": source, "image": DAGGER_IMAGE})
    step = result["container"]["from"]["withMountedDirectory"]["withWorkdir"]["withExec"]["withExec"]
    print(step["stdout"] + step["stderr"], end="")
    print(f"PASS: local Dagger portable checks ({DAGGER_IMAGE})")
