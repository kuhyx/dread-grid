#!/bin/bash

# ============================================================================
# Export the browser build (preset "Web": single-threaded, so itch.io needs
# no SharedArrayBuffer / cross-origin isolation) into <out_dir>, default
# ../dread-grid_binaries/web. Installs the Godot export templates if missing.
#   scripts/export_web.sh [out_dir]
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
readonly GODOT_VERSION="4.7.2"
readonly TEMPLATES_DIR="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"

ensure_templates() {
    [[ -f "$TEMPLATES_DIR/web_nothreads_release.zip" ]] && return
    echo "Installing Godot ${GODOT_VERSION} export templates..."
    local tpz unpacked
    tpz="$(mktemp --suffix=.tpz)"
    unpacked="$(mktemp -d)"
    curl -fsSL -o "$tpz" \
        "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
    unzip -q "$tpz" -d "$unpacked"    # a .tpz is a zip with a templates/ root
    mkdir -p "$TEMPLATES_DIR"
    mv "$unpacked"/templates/* "$TEMPLATES_DIR"/
    rm -rf "$tpz" "$unpacked"
}

main() {
    local out
    out="$(realpath -m "${1:-$REPO_ROOT/../dread-grid_binaries/web}")"
    ensure_templates
    rm -rf "$out"
    mkdir -p "$out"
    godot --headless --path "$REPO_ROOT" --import >/dev/null 2>&1 || true
    godot --headless --path "$REPO_ROOT" --export-release Web "$out/index.html" 2>&1 \
        | grep -E 'ERROR|error' || true
    [[ -s "$out/index.html" && -s "$out/index.pck" ]]
    du -sh "$out"
    ls "$out"
}

main "$@"
