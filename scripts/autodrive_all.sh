#!/bin/bash

# ============================================================================
# The done gate for all 15 games: each one headless, its bot playing through
# the real view, --quit-on-finish. Exit 0 only if every game is won.
#   scripts/autodrive_all.sh [seed] [game ...]
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
readonly SPEED="${SPEED:-16}"

all_games() {
    local concept perspective
    for concept in anomaly stalker wrong_place found_footage blind_nav; do
        for perspective in fps topdown text; do
            echo "$concept/$perspective"
        done
    done
}

main() {
    local seed="${1:-1}"
    shift || true
    local games=("$@")
    if [[ ${#games[@]} -eq 0 ]]; then
        mapfile -t games < <(all_games)
    fi
    local failed=0 game line code
    for game in "${games[@]}"; do
        set +e
        line="$(timeout 300 godot --headless --audio-driver Dummy --path "$REPO_ROOT" -- \
            --game="$game" --seed="$seed" --autodrive --quit-on-finish --speed="$SPEED" 2>&1 \
            | grep -E '^RESULT|SCRIPT ERROR' | head -3)"
        code=${PIPESTATUS[0]}
        set -e
        printf '%-24s exit=%s  %s\n' "$game" "$code" "${line//$'\n'/ / }"
        if [[ "$code" -ne 0 || "$line" == *"SCRIPT ERROR"* ]]; then
            failed=1
        fi
    done
    if [[ "$failed" -ne 0 ]]; then
        echo "autodrive: FAILED" >&2
        exit 1
    fi
    echo "autodrive: all ${#games[@]} won"
}

main "$@"
