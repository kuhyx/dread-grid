"""Boot the exported web build in headless Chromium and prove it plays.

Serves the export over HTTP (the wasm loader refuses file://), waits for the
launcher's "LAUNCHER ready" console line, opens the first game with Enter,
then goes back and opens a text game with the arrow keys -- the same keys a
player uses. Fails on any page error or GDScript error, a missing START line,
or a blank frame. Exit 0 on success.
"""

from __future__ import annotations

import http.server
import statistics
import sys
import threading
from functools import partial
from pathlib import Path

from playwright.sync_api import Page, sync_playwright

DEFAULT_DIST = Path(__file__).resolve().parents[2] / "dread-grid_binaries" / "web"
PORT = 8766
BOOT_TIMEOUT_MS = 90_000
MIN_PIXEL_STDDEV = 8.0


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    """SimpleHTTPRequestHandler without per-request logging."""

    def log_message(self, *_args: object) -> None:
        return


def serve(dist: Path) -> http.server.ThreadingHTTPServer:
    """Serve the export on PORT in a daemon thread."""
    handler = partial(QuietHandler, directory=str(dist))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", PORT), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server


def wait_for_line(page: Page, lines: list[str], needle: str, count: int = 1) -> None:
    """Block until `needle` has appeared in the console `count` times."""
    for _ in range(BOOT_TIMEOUT_MS // 250):
        if sum(needle in line for line in lines) >= count:
            return
        page.wait_for_timeout(250)
    msg = f"never saw {needle!r} x{count}; last console lines: {lines[-8:]}"
    raise TimeoutError(msg)


def frame_stddev(png: bytes) -> float:
    """Spread of the screenshot's bytes; a blank canvas is a flat line."""
    sample = png[len(png) // 4 : len(png) // 4 + 20_000]
    return statistics.pstdev(sample)


def play(page: Page, lines: list[str], shot: Path) -> float:
    """Open anomaly/fps, walk, go back, open anomaly/text; return frame spread."""
    page.goto(f"http://127.0.0.1:{PORT}/index.html")
    wait_for_line(page, lines, "LAUNCHER ready")
    page.locator("canvas").first.focus()
    page.keyboard.press("Enter")
    wait_for_line(page, lines, "START game=anomaly/fps")
    for _ in range(3):
        page.keyboard.press("w")
        page.wait_for_timeout(400)
    page.wait_for_timeout(1500)
    page.screenshot(path=str(shot))
    spread = frame_stddev(shot.read_bytes())
    page.keyboard.press("Escape")
    wait_for_line(page, lines, "LAUNCHER ready", 2)
    page.keyboard.press("ArrowRight")
    page.keyboard.press("ArrowRight")
    page.keyboard.press("Enter")
    wait_for_line(page, lines, "START game=anomaly/text")
    return spread


def main() -> int:
    """Run the smoke test; non-zero exit means the web build is broken."""
    dist = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_DIST
    shot = Path(sys.argv[2]) if len(sys.argv) > 2 else dist / "smoke.png"
    if not (dist / "index.html").exists():
        print(f"missing {dist}/index.html: run scripts/export_web.sh first", file=sys.stderr)
        return 2
    server = serve(dist)
    lines: list[str] = []
    errors: list[str] = []
    try:
        with sync_playwright() as playwright:
            browser = playwright.chromium.launch(args=["--use-gl=angle", "--use-angle=swiftshader"])
            page = browser.new_page(viewport={"width": 1280, "height": 720})
            page.on("console", lambda msg: lines.append(msg.text))
            page.on("pageerror", lambda err: errors.append(str(err)))
            spread = play(page, lines, shot)
            browser.close()
    finally:
        server.shutdown()
    script_errors = [line for line in lines if "SCRIPT ERROR" in line]
    print(f"web smoke: frame stddev={spread:.1f}, page errors={len(errors)}, "
          f"script errors={len(script_errors)}, shot={shot}")
    for problem in errors + script_errors:
        print(f"  {problem}", file=sys.stderr)
    if errors or script_errors or spread < MIN_PIXEL_STDDEV:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
