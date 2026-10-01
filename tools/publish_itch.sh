#!/bin/bash

# ============================================================================
# Publish the browser build to https://kuhyx.itch.io/dread-grid (channel
# "html5"): export, prove it plays in headless Chromium, then butler push.
# The upload is versioned with the git commit so itch shows which build is live.
#   tools/publish_itch.sh [--dry-run]
# Needs a one-time `butler login` (browser OAuth). Installs butler if missing.
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
readonly TARGET="kuhyx/dread-grid:html5"
readonly BUTLER_URL="https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default"
readonly BIN_DIR="$HOME/.local/bin"
readonly OUT="$REPO_ROOT/../dread-grid_binaries/web"
DRY_RUN=0

ensure_butler() {
    command -v butler >/dev/null 2>&1 && return
    echo "Installing butler into $BIN_DIR..."
    local tmp
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/butler.zip" "$BUTLER_URL"
    unzip -q "$tmp/butler.zip" -d "$tmp"
    mkdir -p "$BIN_DIR"
    install -m 755 "$tmp/butler" "$BIN_DIR/butler"
    rm -rf "$tmp"
    butler --version
}

main() {
    [[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1
    ensure_butler
    if [[ -n "$(git -C "$REPO_ROOT" status --porcelain --untracked-files=no)" ]]; then
        echo "Error: uncommitted changes; publish a committed build only." >&2
        exit 1
    fi
    "$REPO_ROOT/scripts/export_web.sh" "$OUT"
    "$REPO_ROOT/.venv/bin/python" "$REPO_ROOT/tests/web_smoke.py" "$OUT" "$OUT/../web_smoke.png"
    local version
    version="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "dry run: would push $OUT to $TARGET as $version"
        return
    fi
    butler push "$OUT" "$TARGET" --userversion "$version"
    butler status "$TARGET"
}

main "$@"
