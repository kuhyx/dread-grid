#!/bin/bash

# ============================================================================
# Run dread-grid (the 5x3 launcher). Extra arguments go to the game, e.g.
#   ./run.sh --game=stalker/fps --seed=7
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT

exec godot --path "$REPO_ROOT" -- "$@"
