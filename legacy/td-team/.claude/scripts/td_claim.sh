#!/bin/bash
# Claims a td issue for the current session: starts work (-> in_progress) and,
# if a role is given, records who took it via a log entry. Guards cwd to the
# repo root and verifies the issue actually reached in_progress.
#
# Usage: td_claim.sh <id> [role]
#   td_claim.sh td-a1b2 senior-engineer
set -euo pipefail

usage() {
    echo "Usage: td_claim.sh <id> [role]" >&2
    echo "  Claims <id>: 'td start <id>' and (if role given) logs 'claimed by @<role>'." >&2
    echo "  Guards cwd to repo root and verifies status advanced to in_progress." >&2
    exit 1
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
fi

ID="$1"
ROLE="${2:-}"
ROLE="${ROLE#@}"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "td_claim.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

# Envelope-tolerant status extractor: td mutations return
# {"id","status","action","issue":{...}}; reads may nest under .issue.
issue_status() {
    printf '%s' "$1" | jq -r '(.issue.status // .status // empty)'
}

START_OUTPUT=$(td start "$ID" --json) || {
    echo "td_claim.sh: 'td start ${ID}' failed: ${START_OUTPUT}" >&2
    exit 1
}

STATUS=$(issue_status "$START_OUTPUT")
if [ -n "$STATUS" ] && [ "$STATUS" != "in_progress" ]; then
    echo "td_claim.sh: ${ID} did not reach in_progress (status: ${STATUS:-unknown})." >&2
    echo "$START_OUTPUT" >&2
    exit 1
fi

if [ -n "$ROLE" ]; then
    # Add the role as a label so team-lead's roster probe
    # (`td query "labels ~ <role>"`) can attribute in-progress work. `td update
    # --labels` REPLACES the set, so read the current labels and append.
    CURRENT=$(td show "$ID" --json 2>/dev/null | jq -r '(.labels // []) | join(",")') || CURRENT=""
    case ",${CURRENT}," in
        *",${ROLE},"*) NEWLABELS="$CURRENT" ;;                 # already present
        *)             NEWLABELS="${CURRENT:+$CURRENT,}$ROLE" ;;
    esac
    td update "$ID" --labels "$NEWLABELS" >/dev/null 2>&1 || \
        echo "td_claim.sh: warning: could not add role label @${ROLE}" >&2
    td log "claimed by @${ROLE}" >/dev/null 2>&1 || true
fi

echo "Claimed ${ID}${ROLE:+ for @$ROLE} (status: ${STATUS:-in_progress})"
