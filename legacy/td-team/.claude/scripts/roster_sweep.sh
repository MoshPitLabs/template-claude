#!/bin/bash
# Emits {role: [in-progress issue ids]} for every role team-lead tracks, in a
# single invocation, replacing the hand-enumerated per-role queries in
# team-lead.md's shutdown sweep and Liveness-Confirmation Gate pre-respawn
# check.
#
# td has no assignee field, so role attribution rides on a label convention:
# each teammate labels its in-progress issue with its role name (e.g.
# `td create ... --label senior-engineer`). This sweep resolves per-role work
# via `td query "status = in_progress AND labels ~ <role>" --output ids`.
set -euo pipefail

usage() {
    echo "Usage: roster_sweep.sh" >&2
    echo "  Emits {role: [in-progress issue ids]} across all roles team-lead" >&2
    echo "  tracks (senior-engineer, sdet, staff-engineer, distinguished-engineer," >&2
    echo "  project-manager, security-engineer, ux-designer)." >&2
    exit 1
}

if [ "$#" -ne 0 ]; then
    usage
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "roster_sweep.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

# Roles sourced from team-lead.md's Per-Role Dispatch Table (all roles that
# hold assigned issues; team-lead itself is not assignable).
ROLES=(
    senior-engineer
    sdet
    staff-engineer
    distinguished-engineer
    project-manager
    security-engineer
    ux-designer
)

RESULT="{}"
for ROLE in "${ROLES[@]}"; do
    OUT=$(td query "status = in_progress AND labels ~ ${ROLE}" --output ids 2>/dev/null) || {
        echo "roster_sweep.sh: failed to query in-progress issues for ${ROLE}" >&2
        exit 1
    }
    # --output ids prints one id per line, or the literal "No issues matching
    # query" when empty — keep only real IDs (^td-), then fold into a JSON array.
    # `grep` exits 1 on no match (empty role); tolerate it under `set -e`.
    IDS=$(printf '%s\n' "$OUT" | { grep '^td-' || true; } | jq -R . | jq -s .)
    [ -n "$IDS" ] || IDS='[]'
    RESULT=$(printf '%s' "$RESULT" | jq --arg role "$ROLE" --argjson ids "$IDS" '. + {($role): $ids}')
done

printf '%s\n' "$RESULT" | jq -c .
