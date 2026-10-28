#!/bin/bash
# Runs an arbitrary td write command and verifies it actually changed the
# target issue, by comparing a re-show of <id> before and after. Guards cwd to
# the repo root. Use for the write verbs that mutate a specific issue
# (review, reject, approve, link, dep add, handoff, ...).
#
# Usage: td_write.sh <id> <td args...>
#   td_write.sh td-a1b2 review td-a1b2
#   td_write.sh td-a1b2 link td-a1b2 src/auth/router.go
#   td_write.sh td-a1b2 handoff td-a1b2 --done "x" --remaining "y"
set -euo pipefail

usage() {
    echo "Usage: td_write.sh <id> <td args...>" >&2
    echo "  Runs 'td <args...>', then verifies <id> changed via a before/after re-show." >&2
    echo "  Guards cwd to repo root and verifies the write took effect." >&2
    exit 1
}

if [ "$#" -lt 2 ]; then
    usage
fi

ID="$1"
shift

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "td_write.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

# Compare on the issue body with volatile timestamps stripped, so a genuine
# no-op is caught even though td refreshes updated_at on every touch.
issue_fingerprint() {
    td show "$ID" --json 2>/dev/null \
        | jq -S 'del(.. | .updated_at?, .accessed_at?)' 2>/dev/null \
        || printf 'unavailable'
}

BEFORE=$(issue_fingerprint)

td "$@"

AFTER=$(issue_fingerprint)

if [ "$AFTER" = "unavailable" ]; then
    echo "td_write.sh: ran 'td $*' but could not re-show ${ID} to verify." >&2
    exit 1
fi

if [ "$AFTER" = "$BEFORE" ]; then
    echo "td_write.sh: write did not change ${ID} — issue body unchanged. Check cwd/td state." >&2
    exit 1
fi

echo "Wrote ${ID} via 'td $*'"
