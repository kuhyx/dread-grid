#!/bin/bash

# ============================================================================
# The whole local gate in one exit code: lint, tests, all 15 autodrive runs,
# and the four shared gates (file length, markdown naming, no binaries,
# dependency freshness).
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT

main() {
    cd "$REPO_ROOT"   # the shared gates resolve the repo from cwd
    scripts/lint.sh
    scripts/test.sh
    scripts/autodrive_all.sh
    scripts/check_file_length.sh --all
    scripts/check_md_naming.sh --all
    git ls-files -z | xargs -0 scripts/check_no_binaries.sh
    scripts/check_dependency_freshness.sh --all
    echo "check: all green"
}

main "$@"
