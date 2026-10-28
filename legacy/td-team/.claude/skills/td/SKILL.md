---
name: td
description: >
  Comprehensive reference for the td CLI (`td`), a local-first, SQLite-backed
  issue tracker built for AI coding sessions. Use this skill whenever the user
  asks to create, start, log, hand off, review, approve, reject, close, list,
  show, or query issues; link files or dependencies; find the next actionable
  task or the critical path; organize a board, epic, or work session; capture a
  session handoff; or any request to "use td", "track this in td", "create a td
  issue", "check td status", "run td next / td usage", "show the td board", etc.
---

# td CLI Skill

td (`td`) is a local-first, SQLite-backed issue tracker driven entirely
through a single CLI binary. There is no server and no network call for basic
use — all state lives in a `.todos/issues.db` SQLite file at the project root
(td walks up from the cwd to find it, or the git root that contains it). This
skill teaches an agent to drive `td` end to end: issue lifecycle, logging and
handoffs, the independent-review model, file/dependency tracking, planning,
boards, epics, and work sessions.

Most commands accept a **`--json`** flag for machine-readable output, and the
**`td query`** accepts **`--output table|json|ids|count`**; **`td list`** and
other reads accept **`--json`** (list also has `--format short|long|json`).
**Agents should prefer `--json` / `--output json`|`ids`|`count`** for parsing.
Note the shapes: `td show --json` returns the issue **flat** (`.status`,
`.description`, `.labels`, and `.logs` once logs exist) — it does **not** embed
files or dependencies; fetch those with `td files <id> --json` (objects keyed
`file_path`) and `td dep <id> --json` (`.dependencies` = an array of issue-id
strings).

## Quick Start

```bash
td init                                  # create .todos/issues.db in the cwd
td usage --new-session                   # what to work on; run once at session start
td create "Fix login bug" --type bug     # create an issue, get its ID back
td list --status open --json      # list open issues
td show td-a1b2                           # full detail incl. logs, deps, files
td next                                   # highest-priority actionable issue
```

Run `td usage --new-session` at the start of a session (or after `/clear`), and
`td usage -q` for a compact refresh thereafter. Sessions are created
automatically from the terminal/agent context; you rarely manage them by hand.

Issue IDs are short strings formatted `td-XXXX` (e.g. `td-a1b2`). Commands
accept the full ID.

## Issue Lifecycle

```
open → in_progress → in_review → closed
             |
             v
          blocked
```

| Status | Meaning |
|---|---|
| `open` | created, not started |
| `in_progress` | actively being worked |
| `blocked` | stuck on something |
| `in_review` | work done, awaiting an independent review |
| `closed` | reviewed and approved |

**Enums.** Type: `task`, `bug`, `feature`, `chore`, `epic`. Priority: `P0`
(critical) … `P4` (none), default `P2`.

## Workflow: Create & Start

```bash
td create "Add rate limiting to API" --type feature --priority P1 -l backend
td create "Impl X" -d "what and why" -l backend --parent td-epic --depends-on td-9f2
td add "Fix typo in README" --minor            # quick add; bypasses review for trivial work
td create "Title" --description-file specs/desc.md --acceptance-file specs/ac.md
```

`create` flags (verified against td 0.51): `-d`/`--description` (inline) or
`--description-file` (`-` for stdin), `--acceptance`/`--acceptance-file`,
`-l`/`--labels` (repeatable/comma-separated), `--parent`/`--epic` (parent ID),
`--depends-on`, `--blocks`, `--minor`, `--due`, `--defer`. `td create` returns
the new issue (add `--json` to capture the ID — the envelope is
`{"id","action","issue":{...},"status"}`; use `.id`). Use `--minor` only for
genuinely low-risk changes (docs, typos).

Begin work — this snapshots git state and moves the issue to `in_progress`:

```bash
td start td-a1b2
td unstart td-a1b2      # revert back to open
```

## Workflow: Log Progress & Handoffs

Logs attach timestamped notes to the issue you're actively working
(session-scoped). Capture reasoning as you go:

```bash
td log "endpoint returning correct data"          # appends to your FOCUSED issue (set by `td start`)
td log --decision "using Redis for caching — lower latency than re-query"
td log --blocker "upstream rate limit undocumented; emailed vendor"
td comment td-a1b2 "reviewed — root cause is a stale cache key"   # targets a SPECIFIC issue
td update td-a1b2 --priority P0 --labels backend,urgent            # edit fields (labels REPLACE)
```

`td log` writes to the current/focused issue (`td start <id>` or `td focus <id>`
sets it); to note a *specific* issue you aren't focused on, use `td comment <id>
"text"`. `td update <id>` edits fields (`--priority`, `--description`, `-l`/`--labels`
which **replace** the whole set, etc.).

Before a session ends or context runs out, record a structured handoff so the
next session resumes from accurate state instead of guessing:

```bash
td handoff td-a1b2 \
  --done "OAuth flow, token storage" \
  --remaining "Refresh-token rotation" \
  --decision "JWT for stateless auth" \
  --uncertain "Should tokens expire on password change?"
```

## Workflow: Review & Close (independent-review model)

td enforces that **you cannot review your own implementation**, but the final
close can be delegated once an independent review is recorded. This prevents an
agent from silently approving its own output.

```bash
td review td-a1b2                                   # submit for review (in_review)
td approve td-a1b2 --record-only --reason "..."     # reviewer records approval, no close
td approve td-a1b2 --reason "Closing after recorded approval"   # any session closes
td reject td-a1b2 --reason "Missing error handling"  # send back to in_progress
```

Prefer delegating the review to an independent sub-agent / separate session.
When delegation is impractical in `trusted` mode (the default), acknowledge a
self-review instead of faking a reviewer session:

```bash
td approve td-a1b2 --self-review --reason "Reviewed the diff myself, tests pass"
```

`--self-review` requires `--reason` and stamps the review row for audit. Review
policy is set with `td feature set review_policy_mode <trusted|delegated|balanced|strict>`.

## Workflow: Files & Dependencies

```bash
td link td-a1b2 src/auth/*.go        # SHA-track files against the issue
td files td-a1b2                      # show [modified]/[unchanged]/[new]/[deleted]

td dep add td-abc td-xyz              # td-abc depends on (is blocked by) td-xyz
td dep rm  td-abc td-xyz
td dep td-abc                         # what blocks td-abc
td dep td-abc --blocking              # what td-abc blocks
td blocked-by td-xyz                  # all issues blocked by td-xyz
td critical-path                      # topological order weighted by unblock impact
```

Use `td dep` / `td critical-path` before touching a shared interface to assess
blast radius and pick the highest-leverage work first.

## Workflow: List, Query, Search

```bash
td list --status open --json
td query "status = in_progress AND priority <= P1" --output ids
td query "type = bug AND labels ~ auth"
td query "priority <= P1 AND NOT labels ~ frontend" --output count
td query "rework()"          # issues that were reviewed and sent back
td query "stale(14)"         # untouched for 14 days
td search "keyword"          # title/description text search
td next                      # highest-priority actionable (no incomplete blockers)
```

`--output ids` prints one issue ID per line; `--output count` prints a number —
both are ideal for scripting. Query supports field filters (`status`, `type`,
`priority`, `labels`), boolean operators (`AND`/`OR`/`NOT`), comparisons
(`<=`), a `~` label-contains match, and functions like `rework()` / `stale(n)`.

## Workflow: Boards, Epics, Work Sessions

```bash
# Boards are saved, query-defined views (they filter, they don't contain)
td board create "Sprint 1" --query "priority <= P1"
td board list
td board show "Sprint 1"
td board move "Sprint 1" td-a1b2 3
td board edit "Sprint 1" --query "priority <= P0"
td board delete "Sprint 1"

# Epics are issues with type=epic; children are created WITH --parent/--epic
td epic create "Multi-user support" --priority P0     # or: td create "…" --type epic
td epic list
td create "Sub-task" --parent td-epic                 # sets parent_id (there is no `tree add-child`)
td tree td-epic                                        # view the hierarchy (nested .children in --json)
td list --parent td-epic --json                        # enumerate direct children

# Work sessions group related issues under one context
td ws start "Auth implementation"
td ws tag td-1 td-2            # associate issues (--no-start to not auto-start)
td ws log "shared token storage decision"   # fans out to all tagged issues
td ws handoff                  # capture handoff state for all tagged issues
```

## Workflow: State, Monitoring, Undo

```bash
td usage                # current focus, pending reviews, open issues, recent decisions
td usage -q             # compact
td usage --new-session  # start-of-session read (labels a fresh session)
td session "name"       # label the current session
td session --new        # force a new session in the same context
td monitor              # live TUI dashboard (b=board, /=search, c=toggle closed, s=stats)
td stats analytics      # command usage
td stats security       # workflow-exception audit log
td stats errors         # failed attempts
td undo                 # undo the last action
td version
```

## Output Contract & Errors

- `--json` on a mutating command returns `{"id","status","action","issue":{...}}`.
- `td query` takes `--output table|json|ids|count`; `td list`/`td show`/`td files`/`td dep` take `--json`.
- Errors return `{"error":{"code","message"}}` on stderr with a non-zero exit
  code. In agent/non-interactive contexts, always pass required flags
  explicitly rather than relying on interactive prompts.

## What td does NOT have (and what to use instead)

td is a focused, local task tracker — not an enterprise platform. Two docket
habits have **no td equivalent**; use the project convention instead:

- **Consensus voting.** There is no `td vote`. Multi-reviewer consensus is a
  hand-rolled convention on top of td issues + logs — see the **[[vote]]** skill.
- **A document store.** There is no `td doc`. Specs (PRD/ADR/TDD/UX) live as
  markdown files under `specs/` at the project root and are attached to their
  issue with `td link <id> specs/<file>` and referenced in `td log`. See the
  **[[prd]]**, **[[adr]]**, **[[tdd]]**, **[[ux-spec]]**, and **[[init-specs]]**
  skills.

## Command Map (from the docket-era workflow)

If you know the old docket verbs, this is the td equivalent:

| Intent | td |
|---|---|
| init | `td init` |
| create issue | `td create "T" --type … --priority Pn --label …` |
| quick/minor add | `td add "T" --minor` |
| list / filter | `td list --status …` / `td query "…"` |
| show detail | `td show <id>` |
| start work | `td start <id>` (revert: `td unstart <id>`) |
| submit for review | `td review <id>` |
| approve / close | `td approve <id> [--record-only\|--self-review] --reason "…"` |
| reject | `td reject <id> --reason "…"` |
| comment / note | `td log "…"` (on the active issue) / `td handoff <id> …` |
| attach files | `td link <id> <files…>` (`td files <id>` to inspect) |
| block/depend | `td dep add <issue> <depends-on>` |
| dependency graph | `td dep <id>` / `td blocked-by <id>` / `td critical-path` |
| plan / ordering | `td critical-path` / a query-backed `td board` |
| next work | `td next` |
| stats / board | `td stats …` / `td board …` / `td monitor` |
| session state | `td usage [-q\|--new-session]` |
