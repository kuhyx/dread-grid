#!/bin/bash

# ============================================================================
# Install everything dread-grid needs: Godot 4.7.2, the Python dev tools
# (gdlint/gdformat, pre-commit) in .venv, GUT, the assets (CC0 samples and
# rendered music beds, outside git in ~/data/dread-grid_binaries), git hooks.
# Idempotent; rerun after a pull.
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT
readonly GUT_TAG="v9.7.1"   # newest stable; not tracked by the freshness gate
readonly VENV="$REPO_ROOT/.venv"
readonly BINARIES="${DREAD_GRID_BINARIES:-$HOME/data/dread-grid_binaries}"

ensure_godot() {
    if ! command -v godot >/dev/null 2>&1; then
        echo "Installing godot..."
        sudo pacman -S --needed --noconfirm godot
    fi
}

ensure_python_tools() {
    # Repo-local venv: Arch's Python is PEP 668 managed.
    if [[ ! -x "$VENV/bin/python" ]]; then
        python3 -m venv "$VENV"
    fi
    "$VENV/bin/python" -m pip install --quiet -r "$REPO_ROOT/requirements-dev.txt"
}

ensure_gut() {
    local gut_dir="$REPO_ROOT/addons/gut"
    if [[ -f "$gut_dir/plugin.cfg" ]] && grep -q "${GUT_TAG#v}" "$gut_dir/plugin.cfg"; then
        return
    fi
    echo "Installing GUT ${GUT_TAG}..."
    rm -rf "$gut_dir"
    local tmp
    tmp="$(mktemp -d)"
    git clone -q --depth 1 --branch "$GUT_TAG" https://github.com/bitwes/Gut "$tmp"
    mkdir -p "$REPO_ROOT/addons"
    mv "$tmp/addons/gut" "$gut_dir"
    rm -rf "$tmp"
}

ensure_assets() {
    # Binaries never live in the repo: `assets` is a gitignored symlink.
    mkdir -p "$BINARIES/assets"
    local target
    target="$(realpath "$BINARIES/assets")"
    # Re-point a link left at an old location (the dir moved from ~/src to
    # ~/data on 2026-10-02), not just a missing one.
    if [[ "$(readlink "$REPO_ROOT/assets" || true)" != "$target" ]]; then
        ln -sfn "$target" "$REPO_ROOT/assets"
    fi
    "$REPO_ROOT/tools/fetch_assets.sh" "$REPO_ROOT/assets/cc0"
    "$REPO_ROOT/tools/render_music.sh" "$REPO_ROOT/assets/music"
}

main() {
    ensure_godot
    ensure_python_tools
    ensure_gut
    ensure_assets
    godot --headless --path "$REPO_ROOT" --import >/dev/null 2>&1 || true
    if [[ -d "$REPO_ROOT/.git" && -z "${CI:-}" ]]; then
        "$REPO_ROOT/scripts/install_hooks.sh"
    fi
    echo "dread-grid: ready. Run ./run.sh"
}

main "$@"
