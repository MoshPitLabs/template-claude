#!/bin/bash
# Closes a td issue and verifies the transition before reporting success.
# Closing requires an independent review to have been recorded (td's review
# model); this wrapper acknowledges a self-review when the closer implemented
# the work. Never reports success unless status actually reached closed.
#
# Usage: td_close.sh <id> <msg> [--self-review]
#   td_close.sh td-a1b2 "shipped rate limiter"
#   td_close.sh td-a1b2 "shipped rate limiter" --self-review
set -euo pipefail

usage() {
    echo "Usage: td_close.sh <id> <msg> [--self-review]" >&2
    echo "  Closes <id> via 'td approve <id> --reason \"Completed: <msg>\"'," >&2
    echo "  verifies status == closed via a re-show, then logs completion." >&2
    echo "  Add --self-review when you implemented the work and reviewed it yourself." >&2
    echo "  Guards cwd to repo root; exits non-zero without logging if the close fails." >&2
    exit 1
}

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    usage
fi

ID="$1"
MSG="$2"
SELF_REVIEW=""
if [ "${3:-}" = "--self-review" ]; then
    SELF_REVIEW="--self-review"
elif [ -n "${3:-}" ]; then
    usage
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "td_close.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

# td requires an issue to be in_review before it can be approved/closed.
# Submit it (best-effort: harmless/no-op if it is already in_review).
td review "$ID" >/dev/null 2>&1 || true

# shellcheck disable=SC2086
td approve "$ID" $SELF_REVIEW --reason "Completed: ${MSG}" || {
    echo "td_close.sh: 'td approve ${ID}' failed. An independent review must be recorded first" >&2
    echo "  (td review <id> then a reviewer 'td approve <id> --record-only --reason ...')," >&2
    echo "  or pass --self-review if you implemented and reviewed it yourself." >&2
    exit 1
}

SHOW_OUTPUT=$(td show "$ID" --json) || {
    echo "td_close.sh: failed to re-show ${ID}: ${SHOW_OUTPUT}" >&2
    exit 1
}
STATUS=$(printf '%s' "$SHOW_OUTPUT" | jq -r '(.issue.status // .status // empty)')

if [ "$STATUS" != "closed" ]; then
    echo "td_close.sh: ${ID} status is \"${STATUS:-unknown}\", not \"closed\"." >&2
    echo "$SHOW_OUTPUT" >&2
    exit 1
fi

echo "Closed ${ID} (status: closed): ${MSG}"
