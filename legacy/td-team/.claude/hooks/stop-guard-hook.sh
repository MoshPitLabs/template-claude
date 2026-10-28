#!/bin/bash

set -uo pipefail

# Stop-event guard. Blocks session end while live teammates or outstanding
# td work (open/in_progress, minus issues labeled stop-defer) remain, so a
# team-lead can't stop mid-cycle and strand ephemerals or unclosed issues.
#
# SESSION SCOPING: the td dimension runs ONLY when this session has its own
# team config (~/.claude/teams/session-<8-char session_id prefix>/config.json).
# A no-team leaf session (e.g. /brief, ad-hoc Q&A) is never td-blocked,
# regardless of repo-wide outstanding issues -- that session never opted into
# orchestrating a cycle, so the charter above doesn't apply to it. An
# empty/missing session_id narrows the same way: TEAM_CONFIG stays "" and the
# td dimension is skipped entirely.
#
# LIVE-TEAMMATE CHECK: the team config.json member list self-prunes on clean
# shutdown (in-process backend, clean shutdown_request handshake path). The
# residual gap is unverified crash/kill paths, where a teammate process dies
# without completing the handshake.
#
# TEAMMATE-DIMENSION RATE LIMITING: block immediately on roster change
# (spawn/termination stays visible); otherwise suppress until
# STOP_GUARD_TEAMMATE_REBLOCK_SECONDS (default 600, invalid/non-numeric falls
# back to 600) have elapsed since the last block. No session_id => block
# unconditionally (fail-toward-safety; structurally unreachable via the
# member-count resolution below, which is itself gated on session_id -- kept
# as a defensive branch). Coverage for a teammate that dies without completing
# the shutdown handshake is delegated to teammate-idle-hook.sh (registered on
# the harness-driven TeammateIdle event) and deadman-watch Monitor doctrine.
#
# TD-DIMENSION RATE LIMITING: to avoid re-blocking on every single turn-end
# when the outstanding-issue set hasn't changed since the last block this
# session, the td dimension persists a per-session_id signature of the
# outstanding issue ID set under ~/.claude/stop-guard-hook-state/ and only
# re-blocks when that signature changes.
#
# STATE ARTIFACTS under ~/.claude/stop-guard-hook-state/ (SESSION_ID_SAFE
# prefix, sanitized via tr -c 'A-Za-z0-9_-' '_'), all pruned at >7 days on
# write. .td-sig holds a single line, sorted outstanding issue IDs.
# .teammate-sig holds two lines: sorted non-lead member names, then the
# last-block epoch seconds. .gate-log holds the team-session gate decision,
# OVERWRITTEN -- never appended -- on every team-session Stop event, so it
# stays O(1) per session instead of growing unbounded.
#
# Fail-open throughout, matching this hook family's convention: any
# parse/resolution failure (missing jq, missing td, no team config,
# unresolvable repo root) falls through to "no outstanding work" for that
# dimension rather than blocking on an unrelated infrastructure failure.

DEBUG_TOGGLE="${HOME:-}/.claude/stop-guard-hook.debug"
DEBUG_LOG="${HOME:-}/.claude/stop-guard-hook.log"
STATE_DIR="${HOME:-}/.claude/stop-guard-hook-state"

IS_TEAM_SESSION=0
SESSION_ID_SAFE=""

prune_state_dir() {
    find "$STATE_DIR" -type f -mtime +7 -delete 2>/dev/null || true
}

emit_debug() {
    [ -e "$DEBUG_TOGGLE" ] || return 0
    local decision="${1:--}" detail="${2:-}" ts
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || ts="-"
    { printf 'ts=%s decision=%s %s\n' "$ts" "$decision" "$detail" >> "$DEBUG_LOG"; } 2>/dev/null || true
}

# Unconditional (bypasses DEBUG_TOGGLE) team-session gate log. Overwrites
# SESSION_ID_SAFE.gate-log rather than appending, so this stays bounded (O(1)
# per session) instead of growing on every Stop event; see the STATE ARTIFACTS
# header paragraph.
log_team_session_gate() {
    [ "$IS_TEAM_SESSION" -eq 1 ] && [ -n "$SESSION_ID_SAFE" ] || return 0
    local outcome="${1:-}" ts
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || ts="-"
    mkdir -p "$STATE_DIR" 2>/dev/null || return 0
    prune_state_dir
    { printf 'ts=%s team_session=1 outcome=%s\n' "$ts" "$outcome" > "${STATE_DIR}/${SESSION_ID_SAFE}.gate-log"; } 2>/dev/null || true
}

emit_allow() {
    emit_debug "allow" "${1:-}"
    log_team_session_gate "allow"
    printf '{}\n'
    exit 0
}

emit_block() {
    emit_debug "block" "${2:-}"
    log_team_session_gate "block"
    jq -n --arg reason "$1" '{decision: "block", reason: $reason}' 2>/dev/null || printf '{}\n'
    exit 0
}

DATA=$(cat 2>/dev/null) || emit_allow "no-stdin"

if ! command -v jq >/dev/null 2>&1; then
    emit_allow "no-jq"
fi

# stop_hook_active guards against infinite block loops -- when true, Claude
# Code is already continuing as a result of a prior Stop-hook block for this
# same stop attempt, so never re-block.
STOP_HOOK_ACTIVE=$(printf '%s' "$DATA" | jq -r '.stop_hook_active // false' 2>/dev/null) || emit_allow "unparsable-payload"
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    emit_allow "stop-hook-active"
fi

SESSION_ID=$(printf '%s' "$DATA" | jq -r '.session_id // empty' 2>/dev/null) || SESSION_ID=""
CWD=$(printf '%s' "$DATA" | jq -r '.cwd // empty' 2>/dev/null) || CWD=""

if [ -n "$SESSION_ID" ]; then
    SESSION_ID_SAFE=$(printf '%s' "$SESSION_ID" | tr -c 'A-Za-z0-9_-' '_')
fi

# --- Live-teammate check --------------------------------------------------
# Team directories are named session-<first 8 chars of leadSessionId>.
TEAM_CONFIG=""
TEAM_MEMBER_COUNT=0
TEAM_MEMBER_NAMES=""
TEAM_ROSTER_SIGNATURE=""
if [ -n "$SESSION_ID" ]; then
    SESSION_PREFIX="${SESSION_ID:0:8}"
    TEAM_CONFIG="${HOME:-}/.claude/teams/session-${SESSION_PREFIX}/config.json"
    if [ -f "$TEAM_CONFIG" ] && [ -r "$TEAM_CONFIG" ]; then
        TEAM_MEMBER_COUNT=$(jq -r '[.members[]? | select(.agentType != "team-lead")] | length' "$TEAM_CONFIG" 2>/dev/null) || TEAM_MEMBER_COUNT=0
        TEAM_MEMBER_NAMES=$(jq -r '[.members[]? | select(.agentType != "team-lead") | .name] | join(", ")' "$TEAM_CONFIG" 2>/dev/null) || TEAM_MEMBER_NAMES=""
        TEAM_ROSTER_SIGNATURE=$(jq -r '[.members[]? | select(.agentType != "team-lead") | .name] | sort | join(",")' "$TEAM_CONFIG" 2>/dev/null) || TEAM_ROSTER_SIGNATURE=""
    fi
fi
[ -n "$TEAM_MEMBER_COUNT" ] || TEAM_MEMBER_COUNT=0

IS_TEAM_SESSION=0
if [ -n "$TEAM_CONFIG" ] && [ -f "$TEAM_CONFIG" ] && [ -r "$TEAM_CONFIG" ]; then
    IS_TEAM_SESSION=1
fi

# --- Outstanding td work check (session-scoped: only for this session's own
# team config) -------------------------------------------------------------
# Issues labeled "stop-defer" are excluded regardless of status -- this is how
# an operator marks "I've explicitly reviewed and accepted leaving this open"
# so the hook stops re-blocking on it. `td query --output ids` prints one issue
# ID per line; any query/parse failure yields no IDs (fail-open -> allow).
TD_QUERY='(status = open OR status = in_progress) AND NOT labels ~ stop-defer'
TD_OUTSTANDING_COUNT=0
TD_OUTSTANDING_IDS=""
TD_OUTSTANDING_SIGNATURE=""
if [ "$IS_TEAM_SESSION" -eq 1 ] && command -v td >/dev/null 2>&1 && [ -n "$CWD" ] && [ -d "$CWD" ]; then
    REPO_ROOT=$(cd "$CWD" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || REPO_ROOT=""
    if [ -n "$REPO_ROOT" ] && [ -d "$REPO_ROOT/.todos" ]; then
        # `td query --output ids` prints one issue ID per line, but on an empty
        # result it prints the literal "No issues matching query" to stdout —
        # so filter to real IDs (^td-) before counting, or that message would
        # be miscounted as an outstanding issue and falsely block the stop.
        TD_IDS_RAW=$(cd "$REPO_ROOT" 2>/dev/null && td query "$TD_QUERY" --output ids 2>/dev/null | grep '^td-') || TD_IDS_RAW=""
        if [ -n "$TD_IDS_RAW" ]; then
            TD_OUTSTANDING_COUNT=$(printf '%s\n' "$TD_IDS_RAW" | grep -c '^td-' 2>/dev/null) || TD_OUTSTANDING_COUNT=0
            TD_OUTSTANDING_IDS=$(printf '%s\n' "$TD_IDS_RAW" | paste -sd', ' - 2>/dev/null) || TD_OUTSTANDING_IDS=""
            TD_OUTSTANDING_SIGNATURE=$(printf '%s\n' "$TD_IDS_RAW" | sort | paste -sd',' - 2>/dev/null) || TD_OUTSTANDING_SIGNATURE=""
        fi
    fi
fi
[ -n "$TD_OUTSTANDING_COUNT" ] || TD_OUTSTANDING_COUNT=0

# --- td-dimension rate limiting (once per state signature) ----------------
TD_RATE_LIMITED=0
if [ "$TD_OUTSTANDING_COUNT" -gt 0 ] && [ -n "$SESSION_ID_SAFE" ]; then
    STATE_FILE="${STATE_DIR}/${SESSION_ID_SAFE}.td-sig"
    PREV_SIGNATURE=""
    if [ -f "$STATE_FILE" ]; then
        PREV_SIGNATURE=$(cat "$STATE_FILE" 2>/dev/null) || PREV_SIGNATURE=""
    fi
    if [ "$PREV_SIGNATURE" = "$TD_OUTSTANDING_SIGNATURE" ]; then
        TD_RATE_LIMITED=1
    else
        mkdir -p "$STATE_DIR" 2>/dev/null && prune_state_dir && printf '%s' "$TD_OUTSTANDING_SIGNATURE" > "$STATE_FILE" 2>/dev/null || true
    fi
fi

TD_BLOCK=0
if [ "$TD_OUTSTANDING_COUNT" -gt 0 ] && [ "$TD_RATE_LIMITED" -eq 0 ]; then
    TD_BLOCK=1
fi

# --- Teammate-dimension rate limiting -------------------------------------
# Block immediately on roster change (keeps spawn/termination visible);
# otherwise suppress until STOP_GUARD_TEAMMATE_REBLOCK_SECONDS have elapsed
# since the last block.
TEAMMATE_BLOCK=0
TEAMMATE_RATE_LIMITED=0
if [ "$TEAM_MEMBER_COUNT" -gt 0 ]; then
    if [ -n "$SESSION_ID_SAFE" ]; then
        TEAMMATE_STATE_FILE="${STATE_DIR}/${SESSION_ID_SAFE}.teammate-sig"
        PREV_ROSTER_SIGNATURE=""
        PREV_BLOCK_EPOCH=""
        if [ -f "$TEAMMATE_STATE_FILE" ]; then
            PREV_ROSTER_SIGNATURE=$(sed -n '1p' "$TEAMMATE_STATE_FILE" 2>/dev/null) || PREV_ROSTER_SIGNATURE=""
            PREV_BLOCK_EPOCH=$(sed -n '2p' "$TEAMMATE_STATE_FILE" 2>/dev/null) || PREV_BLOCK_EPOCH=""
        fi

        # A corrupt/empty/non-numeric epoch line must never reach bash
        # arithmetic -- treat it the same as a missing/corrupt whole file
        # (changed => block, rewrite).
        EPOCH_VALID=1
        case "$PREV_BLOCK_EPOCH" in
            ''|*[!0-9]*) EPOCH_VALID=0 ;;
        esac

        REBLOCK_INTERVAL="${STOP_GUARD_TEAMMATE_REBLOCK_SECONDS:-600}"
        case "$REBLOCK_INTERVAL" in
            ''|*[!0-9]*) REBLOCK_INTERVAL=600 ;;
        esac

        NOW_EPOCH=$(date +%s 2>/dev/null) || NOW_EPOCH=0

        if [ ! -f "$TEAMMATE_STATE_FILE" ] || [ "$EPOCH_VALID" -eq 0 ] || [ "$PREV_ROSTER_SIGNATURE" != "$TEAM_ROSTER_SIGNATURE" ]; then
            TEAMMATE_BLOCK=1
        elif [ $(( NOW_EPOCH - PREV_BLOCK_EPOCH )) -ge "$REBLOCK_INTERVAL" ]; then
            TEAMMATE_BLOCK=1
        else
            TEAMMATE_RATE_LIMITED=1
        fi

        if [ "$TEAMMATE_BLOCK" -eq 1 ]; then
            mkdir -p "$STATE_DIR" 2>/dev/null && prune_state_dir && printf '%s\n%s\n' "$TEAM_ROSTER_SIGNATURE" "$NOW_EPOCH" > "$TEAMMATE_STATE_FILE" 2>/dev/null || true
        fi
    else
        # Structurally unreachable via this hook's stdin interface today:
        # TEAM_MEMBER_COUNT can only be >0 when SESSION_ID (and therefore
        # SESSION_ID_SAFE) is non-empty, since member-count resolution above is
        # itself gated on session_id. Kept as fail-toward-safety in case that
        # coupling ever changes.
        TEAMMATE_BLOCK=1
    fi
fi

if [ "$TEAMMATE_BLOCK" -eq 1 ] || [ "$TD_BLOCK" -eq 1 ]; then
    REASON="Session stop blocked:"
    if [ "$TEAMMATE_BLOCK" -eq 1 ]; then
        REASON="${REASON} ${TEAM_MEMBER_COUNT} teammate(s) recorded in this session (${TEAM_MEMBER_NAMES}); periodic nudge (at most one per interval): re-check state once, reuse the existing armed wait (Monitor or singleton_wait.sh) — do NOT spawn a new background wait for this nudge."
    fi
    if [ "$TD_BLOCK" -eq 1 ]; then
        REASON="${REASON} ${TD_OUTSTANDING_COUNT} outstanding td issue(s) (${TD_OUTSTANDING_IDS});"
    fi
    REASON="${REASON} resolve or shut down teammates and close/defer issues before stopping."
    emit_block "$REASON" "team_session=${IS_TEAM_SESSION} teammates=${TEAM_MEMBER_COUNT} teammate_rate_limited=${TEAMMATE_RATE_LIMITED} td=${TD_OUTSTANDING_COUNT} td_rate_limited=${TD_RATE_LIMITED}"
fi

emit_allow "clear team_session=${IS_TEAM_SESSION} teammates=${TEAM_MEMBER_COUNT} teammate_rate_limited=${TEAMMATE_RATE_LIMITED} td=${TD_OUTSTANDING_COUNT} td_rate_limited=${TD_RATE_LIMITED}"
