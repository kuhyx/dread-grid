#!/bin/bash

# ============================================================================
# Render one procedural music bed per concept from content/music_beds.json
# into <out_dir>/<concept>.wav, plus MANIFEST.json (recipe + SHA-256).
#
# The toolkit tag is pinned: ~/src/utils music_theory at a moving HEAD would
# silently change the sound. Beds already rendered are kept unless --force.
# The game loads the WAVs at runtime (Sfx.music) and loops them in code, so
# no Godot import sidecar can quietly disable the loop.
#   tools/render_music.sh [out_dir] [--force]
# Requires: python3 (venv), git, jq.
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
readonly TOOLKIT_SPEC="music_theory @ git+https://github.com/kuhyx/utils@music-theory-v0.1.0#subdirectory=music_theory"
readonly RECIPES="$REPO_ROOT/content/music_beds.json"

OUT_DIR="$REPO_ROOT/assets/music"
FORCE=0
WORK_DIR=""

cleanup() {
    if [[ -n "${WORK_DIR:-}" && -d "$WORK_DIR" ]]; then
        rm -rf "$WORK_DIR"
    fi
}

trap cleanup EXIT

parse_args() {
    local arg
    for arg in "$@"; do
        if [[ "$arg" == "--force" ]]; then
            FORCE=1
        else
            OUT_DIR="$arg"
        fi
    done
}

beds() {
    jq -r 'keys[] | select(startswith("_") | not)' "$RECIPES"
}

all_rendered() {
    local bed
    while IFS= read -r bed; do
        [[ -f "$OUT_DIR/$bed.wav" ]] || return 1
    done < <(beds)
}

main() {
    parse_args "$@"
    mkdir -p "$OUT_DIR"
    if [[ "$FORCE" -eq 0 ]] && all_rendered; then
        echo "Music beds already rendered in $OUT_DIR (--force to redo)."
        return
    fi
    WORK_DIR="$(mktemp -d)"
    echo "Installing ${TOOLKIT_SPEC%% *} (pinned tag)..."
    python3 -m venv "$WORK_DIR/venv"
    "$WORK_DIR/venv/bin/pip" install --quiet "$TOOLKIT_SPEC"
    local manifest="$OUT_DIR/MANIFEST.json" bed recipe
    rm -f "$manifest"
    while IFS= read -r bed; do
        recipe="$WORK_DIR/$bed.json"
        jq --exit-status ".${bed}" "$RECIPES" >"$recipe"
        echo "bed $bed: degrade $(jq -r '.degrade' "$recipe")"
        "$WORK_DIR/venv/bin/python" -m music_theory render --recipe "$recipe" \
            --out "$OUT_DIR/$bed.wav" --manifest "$manifest"
    done < <(beds)
    echo "Rendered music beds into $OUT_DIR."
}

main "$@"
