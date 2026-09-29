#!/bin/bash

# ============================================================================
# Fetch the CC0 samples pinned in assets.lock.json into <out_dir>/<name>.ogg.
# Each download is sha256-checked (a changed upstream file fails loudly, it
# is never silently used), cached, unpacked (7z / zip member) and converted
# to Ogg Vorbis so Godot imports one format. Idempotent.
#   tools/fetch_assets.sh [out_dir]
# Requires: curl, jq, 7z, unzip, ffmpeg (installed here if missing).
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
readonly LOCK="$REPO_ROOT/assets.lock.json"
OUT_DIR="${1:-$REPO_ROOT/assets/cc0}"
CACHE_DIR="$(realpath -m "$OUT_DIR/../.download-cache")"
WORK_DIR=""

cleanup() {
    if [[ -n "${WORK_DIR:-}" && -d "$WORK_DIR" ]]; then
        rm -rf "$WORK_DIR"
    fi
}

trap cleanup EXIT

ensure_tools() {
    local missing=()
    local tool
    for tool in curl jq 7z unzip ffmpeg; do
        command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
    done
    [[ ${#missing[@]} -eq 0 ]] && return
    echo "Installing ${missing[*]}..."
    if command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm curl jq 7zip unzip ffmpeg
    else
        sudo apt-get update -qq
        sudo apt-get install -y -qq curl jq p7zip-full unzip ffmpeg
    fi
}

## Download `url` once into the cache and verify its sha256.
fetch() {
    local url="$1" sha="$2"
    local file
    file="$CACHE_DIR/${sha:0:16}-$(basename "$url")"
    if [[ ! -f "$file" ]]; then
        curl -fsSL --retry 3 -o "$file.part" "$url"
        mv "$file.part" "$file"
    fi
    if [[ "$(sha256sum "$file" | cut -d' ' -f1)" != "$sha" ]]; then
        echo "Error: sha256 mismatch for $url (upstream changed?)" >&2
        rm -f "$file"
        exit 1
    fi
    printf '%s\n' "$file"
}

## Extract `member` from an archive (or pass the file through) into WORK_DIR.
unpack() {
    local file="$1" member="$2"
    if [[ -z "$member" ]]; then
        printf '%s\n' "$file"
    elif [[ "$file" == *.zip ]]; then
        unzip -o -q "$file" "$member" -d "$WORK_DIR"
        printf '%s\n' "$WORK_DIR/$member"
    else
        7z x -y -bso0 -bsp0 -o"$WORK_DIR" "$file" "$member"
        printf '%s\n' "$WORK_DIR/$member"
    fi
}

main() {
    ensure_tools
    mkdir -p "$OUT_DIR" "$CACHE_DIR"
    WORK_DIR="$(mktemp -d)"
    local count name url sha member src
    count="$(jq --exit-status '.samples | length' "$LOCK")"
    for ((i = 0; i < count; i++)); do
        name="$(jq -r ".samples[$i].name" "$LOCK")"
        [[ -f "$OUT_DIR/$name.ogg" ]] && continue
        url="$(jq -r ".samples[$i].url" "$LOCK")"
        sha="$(jq -r ".samples[$i].sha256" "$LOCK")"
        member="$(jq -r ".samples[$i].member // \"\"" "$LOCK")"
        src="$(unpack "$(fetch "$url" "$sha")" "$member")"
        ffmpeg -nostdin -loglevel error -y -i "$src" -c:a libvorbis -q:a 5 "$OUT_DIR/$name.ogg"
        echo "sample $name"
    done
    echo "CC0 samples ready in $OUT_DIR ($count pinned)."
}

main "$@"
