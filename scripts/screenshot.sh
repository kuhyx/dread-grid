#!/bin/bash

# ============================================================================
# Screenshot one game under Xvfb (never the live display), autodriven.
#   scripts/screenshot.sh <concept/perspective> <out.png> [seconds] [seed]
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT

main() {
    if [[ $# -lt 2 ]]; then
        echo "usage: $0 <concept/perspective> <out.png> [seconds] [seed]" >&2
        exit 1
    fi
    local game="$1" out="$2" at="${3:-6}" seed="${4:-1}"
    xvfb-run -a -s "-screen 0 1280x720x24" godot --audio-driver Dummy --path "$REPO_ROOT" \
        -- --game="$game" --seed="$seed" --autodrive --screenshot="$(realpath -m "$out")" \
        --screenshot-at="$at" --timeout=600 2>&1 | grep -E '^SCREENSHOT|SCRIPT ERROR' || true
    [[ -s "$out" ]]
}

main "$@"
