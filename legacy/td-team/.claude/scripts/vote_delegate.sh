#!/bin/bash
# Opens a consensus "vote" as a plain td issue (td has no native vote command),
# following the hand-rolled convention in ~/.claude/skills/vote/SKILL.md: the
# proposal is a `--label vote` issue whose description records the criticality,
# the doctrine-correct approval threshold (mapped from criticality), and the
# required voter count. Then prints the text-prefixed delegation payload ready
# to paste into a SendMessage to team-lead, per the vote skill's Delegation
# Protocol. Voters record verdicts as `td log` lines on this issue; the
# coordinator tallies and closes it (approve/reject).
set -euo pipefail

usage() {
    echo "Usage: vote_delegate.sh <role> <criticality> <desc> <voters> [artifact]" >&2
    echo "  role:        e.g. @senior-engineer (leading @ optional)" >&2
    echo "  criticality: low|medium|high|critical" >&2
    echo "  desc:        proposal description" >&2
    echo "  voters:      required number of voters (integer)" >&2
    echo "  artifact:    optional artifact path included in the payload" >&2
    exit 1
}

if [ "$#" -eq 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
    usage
fi

if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]; then
    usage
fi

ROLE="@${1#@}"
CRITICALITY="$2"
DESC="$3"
VOTERS="$4"
ARTIFACT="${5:-}"

# Threshold + priority mapped from criticality, per the vote skill's
# Criticality Classification table.
case "$CRITICALITY" in
    low)      THRESHOLD=0.50; PRIORITY=P3 ;;
    medium)   THRESHOLD=0.60; PRIORITY=P2 ;;
    high)     THRESHOLD=0.75; PRIORITY=P1 ;;
    critical) THRESHOLD=0.90; PRIORITY=P0 ;;
    *)
        echo "vote_delegate.sh: unknown criticality '${CRITICALITY}' (want low|medium|high|critical)" >&2
        exit 1
        ;;
esac

case "$VOTERS" in
    ''|*[!0-9]*)
        echo "vote_delegate.sh: voters must be an integer, got '${VOTERS}'" >&2
        exit 1
        ;;
esac

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "vote_delegate.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

DESC_FILE=$(mktemp)
trap 'rm -f "$DESC_FILE"' EXIT
{
    printf '%s\n\n' "$DESC"
    printf '**Vote metadata**\n'
    printf -- '- criticality: %s\n' "$CRITICALITY"
    printf -- '- threshold: %s (fraction of weighted approvals required)\n' "$THRESHOLD"
    printf -- '- required voters: %s\n' "$VOTERS"
    printf -- '- created by: %s\n\n' "$ROLE"
    printf 'Voters record verdicts as `td log` lines on this issue:\n'
    printf '`VOTE <voter>: <approve|approve-with-concerns|reject> confidence=<0..1> — <findings>`\n'
} > "$DESC_FILE"

CREATE_OUTPUT=$(td create "VOTE: ${DESC}" --type task --label vote --priority "$PRIORITY" --description-file "$DESC_FILE" --json) || {
    echo "vote_delegate.sh: 'td create' for the vote issue failed" >&2
    echo "$CREATE_OUTPUT" >&2
    exit 1
}

VOTE_ID=$(printf '%s' "$CREATE_OUTPUT" | jq -r '(.id // .issue.id // empty)')

if [ -z "$VOTE_ID" ] || [ "$VOTE_ID" = "null" ]; then
    echo "vote_delegate.sh: could not extract vote issue id from td output" >&2
    echo "$CREATE_OUTPUT" >&2
    exit 1
fi

if command -v uuidgen >/dev/null 2>&1; then
    REQUEST_ID=$(uuidgen)
elif command -v python3 >/dev/null 2>&1; then
    REQUEST_ID=$(python3 -c "import uuid; print(uuid.uuid4())")
else
    echo "vote_delegate.sh: neither uuidgen nor python3 available to generate request_id" >&2
    exit 1
fi
REQUEST_ID=$(printf '%s' "$REQUEST_ID" | tr '[:upper:]' '[:lower:]')

PAYLOAD_JSON=$(jq -nc \
    --arg vote_id "$VOTE_ID" \
    --arg from "$ROLE" \
    --arg summary "$DESC" \
    --arg request_id "$REQUEST_ID" \
    --arg artifact "$ARTIFACT" \
    '{type: "delegation_request", protocol_version: "1", skill: "vote", request_id: $request_id, vote_id: $vote_id, from: $from, summary: $summary}
     + (if $artifact != "" then {artifact: $artifact} else {} end)')

echo "Threshold: ${THRESHOLD}"
echo "Vote issue: ${VOTE_ID}"
echo "delegation_request (vote) JSON: ${PAYLOAD_JSON}"
