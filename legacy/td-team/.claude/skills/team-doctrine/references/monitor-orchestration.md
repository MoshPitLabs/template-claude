# Monitor for Orchestration — Maintained Master

**LOCAL-copy consumers:** `team-lead.md` only (compact LOCAL copy under its kept `### Monitor
for Orchestration` header). Relocated from `.claude/agents/team-lead.md` lines
305-312 (td-44, per the accepted Design-Complete Gate doctrine (`references/design-gate.md`)); the `### Monitor for Orchestration`
header itself stays inline in team-lead.md (step 12's `§Monitor for Orchestration`
cross-reference must resolve). Deployed at
`.claude/skills/team-doctrine/references/monitor-orchestration.md` — repo:
`.claude/skills/team-doctrine/references/monitor-orchestration.md`. Read on demand
only — never `Skill(team-doctrine)`.

---

`Monitor` is the canonical mechanism for keeping turns short while teammates work. Default to Monitor instead of polling whenever you'd otherwise block on a long wait (>30s) or repeat a probe more than twice. Each pattern below is one event-stream per occurrence — your turn stays cheap and you react when something actually happens.

- **Phase completion (any phase >5min expected):** td has no watch flag, so arm a keyed background wait — `singleton_wait.sh phase-<epic> 30 'td query "status = closed" --output ids | grep -q <child-id>'` (`.claude/scripts/singleton_wait.sh`) — or hand Monitor a poll-and-diff loop over `td query "status = closed" --output ids`. One event per issue closing; no manual sleep loops.
- **Stall / zombie sweep (continuous during steps 11–16):** `Monitor("deadman_watch.sh <stall-threshold-minutes>", filter: none needed — every stdout line is already a STALL-CANDIDATE event)`. `deadman_watch.sh` (`.claude/scripts/deadman_watch.sh`) polls `roster_sweep.sh`'s `{role: [in-progress issue ids]}` plus `td query --output json`'s per-issue `updated_at` on a fixed interval (default 30s) and diffs `updated_at` itself, emitting `STALL-CANDIDATE: <role> <issue> unchanged <N>min` per stall. It alerts once per stall (re-arming only after the issue progresses and stalls again) so the event stream doesn't flood. Replaces manual every-turn probing in step 13's shutdown sweep — emit `shutdown_request` only when the watch surfaces a candidate. This single watch already covers every role `roster_sweep.sh` tracks (senior-engineer, sdet, staff-engineer, distinguished-engineer, project-manager, security-engineer, ux-designer) — no need for one watch per role.

  **Why not a live-refresh view for this:** `td monitor` (and any hand-rolled re-query loop) only reflects a row when its fields CHANGE between refreshes — it is a change-detector, not a silence-detector. An issue that has genuinely stalled (no status/updated_at delta at all — the exact zombie case this sweep exists to catch) produces no such change, so a stall recipe built on live-refresh structurally cannot fire. `deadman_watch.sh` exists specifically to close this gap: it polls on a timer and treats an *unchanged* `updated_at` past the threshold as the signal, rather than waiting for a change event that will never come. Do not reintroduce a live-refresh recipe here for this reason.
- **CI / PR checks (when work touches a PR):** `Monitor("gh pr checks <num> --watch", filter: terminal states succeeded/failed/cancelled)`.
- **Inbound Discovered comments (mid-phase scope deltas):** compare the sorted comment-ID set from `--json` output — the same cost as a raw comment count, but also discriminates a delete+add netting to an equal count if the CLI ever grows deletion, and immune to relative-timestamp drift because it contains no rendered text:

  ```bash
  # Shape-tolerant: td show --json may carry log entries under .logs/.activity/.issue.logs.
  logs='(.issue.logs // .logs // .activity // .data // [])'
  prev=$(td show <ID> --json | jq -r "[${logs}[] | (.id // .timestamp)] | sort | join(\",\")")
  while true; do
    cur=$(td show <ID> --json 2>/dev/null \
          | jq -r "[${logs}[] | (.id // .timestamp)] | sort | join(\",\")") || cur="$prev"
    if [ "$cur" != "$prev" ]; then
      td show <ID> --json \
        | jq -r "${logs}[] | \"\(.id // .timestamp)\t\(.message // .body // .text)\"" \
        | awk -F'\t' -v prev=",$prev," 'index(prev, ","$1",")==0 {print $2}' \
        | grep --line-buffered "Discovered:" || true
      prev="$cur"
    fi
    sleep 30
  done
  ```

  **Why never hash or text-diff rendered CLI output for this:** rendered td output embeds relative timestamps that drift on every poll — a comment authored "25 minutes ago" reads as changed text on the very next refresh even though nothing changed, which is the false-positive polling loop from the 2026-07-16 td-345 incident. Compare `--json` IDs, counts, or absolute timestamps instead; never hash or text-diff rendered output for change detection. Absolute `created_at` timestamps are available in the same payload but add nothing over sorted IDs here.

  **td query failure caveat:** `|| cur="$prev"` treats a failed `td` call as "no change," sound for a transient blip but silently blind forever if the failure is persistent (DB corruption, permissions) — the loop compares `$prev` to itself indefinitely. Escalate after a bounded run of consecutive failures rather than retrying unboundedly.

Filter must be selective (no raw log dumps) and cover failure signatures alongside the happy path (per Monitor tool's coverage rule). td has **no** `--watch` flag (that was a docket feature) — every change-detection recipe here is poll-and-diff on `--json`/`--output ids` output on its own timer, never a hash or text-diff of rendered, timestamp-bearing output (compare sorted IDs, counts, or absolute timestamps instead). The CI/PR recipe is the exception that uses a native watch (`gh pr checks --watch`). The stall sweep additionally must detect the *absence* of a change, which no watch primitive can express (`deadman_watch.sh`). Use `Bash(run_in_background=true)` for one-shot "wait until X is done" cases; use Monitor for "tell me each time X happens." Combine with TaskUpdate at every state transition so the operator sees progress.

**One wait per condition.** Arm a hand-rolled `Bash(run_in_background=true)` background wait through `singleton_wait.sh <key> <interval-seconds> <condition-command>` (`.claude/scripts/singleton_wait.sh`), keyed to the condition it polls, rather than spawning a bare loop directly. The lock makes re-arming an already-covered key idempotent instead of cumulative — impossible when armed through the `singleton_wait.sh` helper; a hand-rolled loop that bypasses the helper entirely is not caught by the lock, since this is a doctrine convention plus opt-in helper, not a mechanical guarantee across every invocation path. A stop-guard nudge is never license on its own to arm a second wait for a condition an existing poller already covers — check for an `already-armed key=<key> pid=<pid>` response (or an existing armed key) before spawning another.
