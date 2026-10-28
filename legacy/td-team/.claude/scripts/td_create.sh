#!/bin/bash
# Wraps `td create`, captures the new issue ID from the JSON envelope, and
# re-shows the issue so callers get confirmed final state (not just the
# create response). Guards cwd to the repo root.
#
# Usage: td_create.sh <td create flags...>
#   td_create.sh "Add rate limiting" --type feature --priority P1 --label backend
set -euo pipefail

usage() {
    echo "Usage: td_create.sh <td create flags...>" >&2
    echo "  Wraps 'td create --json', extracts the new ID, and re-shows it." >&2
    echo "  Guards cwd to repo root." >&2
    exit 1
}

if [ "$#" -eq 0 ]; then
    usage
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "td_create.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

CREATE_OUTPUT=$(td create --json "$@") || {
    echo "td_create.sh: create failed: ${CREATE_OUTPUT}" >&2
    exit 1
}

# Envelope-tolerant ID extractor: mutations return {"id",...,"issue":{...}}.
ID=$(printf '%s' "$CREATE_OUTPUT" | jq -r '(.id // .issue.id // empty)')

if [ -z "$ID" ] || [ "$ID" = "null" ]; then
    echo "td_create.sh: could not determine created issue ID from output:" >&2
    echo "$CREATE_OUTPUT" >&2
    exit 1
fi

SHOW_OUTPUT=$(td show "$ID" --json) || {
    echo "td_create.sh: created ${ID} but re-show failed: ${SHOW_OUTPUT}" >&2
    exit 1
}

echo "Created ${ID}"
printf '%s\n' "$SHOW_OUTPUT"
