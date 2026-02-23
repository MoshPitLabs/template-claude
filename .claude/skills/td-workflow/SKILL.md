---
name: td-workflow
description: Enforce a consistent TD lifecycle across planning, implementation, validation, and review
license: MIT
compatibility: claude-code
metadata:
  audience: engineering
  workflow: td
  requires: TD MCP Server
---
## What I do
- Standardize TD lifecycle usage across all role agents.
- Prefer the TD MCP tools (e.g., `td_status`, `td_start`, `td_create`) over raw shell commands.
- Keep logs and handoffs high-signal for context continuity.

## Tool-first policy

Use the TD MCP tools first. CLI fallback is allowed only if the MCP server is unavailable.

Tool action map (8 categories):

| Category | Actions |
|----------|---------|
| Session/bootstrap | `usage`, `status`, `whoami` |
| Planning | `create`, `epic`, `tree`, `update` |
| Execution | `start`, `focus`, `log`, `comment`, `files`, `update` |
| Dependencies | `dep`, `critical-path`, `block-issue`, `unblock-issue` |
| Work sessions | `ws` (start/tag/log/current/handoff) |
| Queries | `query`, `search` |
| Introspection | `next`, `ready`, `blocked`, `in-review`, `reviewable`, `context` |
| Closeout | `review`, `handoff`, `approve`, `reject` |

## Standard sequence

### Single-issue path
1. Start context: `td_usage(newSession: true)`
2. Confirm status: `td_status()`
3. Start work: `td_start(task: "TASK-ID")`
4. Log progress: `td_log(message: "...", logType: "decision"|"blocker"|...)`
5. Submit for review: `td_review(task: "TASK-ID")`
6. End session: `td_handoff(task: "TASK-ID", done: "...", remaining: "...", decision: "...", uncertain: "...")`

### Multi-issue path (work sessions)
1. Start context: `td_usage(newSession: true)`
2. Start work session: `td_ws(action: "start", name: "phase2-alignment")`
3. Tag issues: `td_ws(action: "tag", issueIds: ["td-aaa", "td-bbb", "td-ccc"])`
4. Fan-out log: `td_ws(action: "log", message: "Implementation in progress")`
5. Submit each for review: `td_review(task: "td-aaa")` (per issue)
6. Grouped handoff: `td_ws(action: "handoff", done: "...", remaining: "...", decision: "...", uncertain: "...")`

## Epic Lifecycle

```text
# 1. Create epic
td_epic(title: "Multi-user support", priority: "P1")

# 2. Create children
td_create(title: "User registration", type: "task", parent: "td-epic-id", points: 3, acceptance: "...")

# 3. Verify tree structure
td_tree(task: "td-epic-id")

# 4. Attach existing issue as child
td_tree(task: "td-parent-id", childIssue: "td-existing-id")

# 5. Scope queries to epic
td_query(query: "parent = td-epic-id AND status = open")

# 6. View full epic context
td_context(task: "td-epic-id")
```

## Dependency Management

```text
# Add dependency (td-later depends on td-earlier)
td_dep(task: "td-later", action: "add", targetIssue: "td-earlier")

# View what an issue depends on
td_dep(task: "td-xxx", action: "list")

# View what an issue is blocking
td_dep(task: "td-xxx", action: "blocking")

# Find optimal unblocking sequence
td_critical_path()

# Manual block/unblock
td_block(task: "td-xxx")
td_unblock(task: "td-xxx")
```

**Auto-unblocking:** When a blocking issue is approved, TD automatically transitions dependents from `blocked` → `open` (when all their dependencies are resolved). No manual action needed.

## Work Sessions

**Session vs work session:**
- **TD session** = identity (automatic per terminal/agent context; enforces review isolation)
- **Work session** = optional grouping container (`td ws`) for multi-issue work

```text
# Start named work session
td_ws(action: "start", name: "phase2-alignment")

# Tag issues (auto-starts them)
td_ws(action: "tag", issueIds: ["td-aaa", "td-bbb"])

# Tag without starting
td_ws(action: "tag", issueIds: ["td-ccc"], noStart: true)

# Fan-out log to all tagged issues
td_ws(action: "log", message: "Shared progress update")

# View current session state
td_ws(action: "current")

# Grouped handoff (ends session)
td_ws(action: "handoff", done: "...", remaining: "...", decision: "...", uncertain: "...")
```

## Structured Logging

Use typed log entries for searchable, high-signal task history:

| Log type | `logType` value | When to use |
|----------|------|-------------|
| Plain | (none) | General progress updates |
| Decision | `logType: "decision"` | Architectural or implementation choices |
| Blocker | `logType: "blocker"` | Something preventing progress |
| Hypothesis | `logType: "hypothesis"` | Theory being tested |
| Tried | `logType: "tried"` | Approach attempted (succeeded or failed) |
| Result | `logType: "result"` | Outcome of experiment or investigation |

```text
td_log(message: "Using JWT for stateless auth", logType: "decision")
td_log(message: "Refresh token rotation unclear", logType: "blocker")
td_log(message: "Session-based approach too complex", logType: "tried")
```

## TDQ Queries

```text
# Filter by status and priority
td_query(query: "status = in_progress AND priority <= P1")

# Filter by type
td_query(query: "type = bug OR type = feature")

# Label contains
td_query(query: "labels ~ auth")

# Issues needing rework (rejected)
td_query(query: "rework()")

# Stale issues (not updated in N days)
td_query(query: "stale(14)")

# Date-relative
td_query(query: "created >= -7d")

# Full-text search
td_search(query: "authentication")
```

## Introspection Commands

| Tool | Purpose |
|------|---------|
| `td_next()` | Highest-priority open issue to work on |
| `td_ready()` | All open issues by priority |
| `td_blocked()` | All currently blocked issues |
| `td_in_review()` | All issues awaiting review |
| `td_reviewable()` | Issues this session can review (not self-implemented) |
| `td_context(task: "td-xxx")` | Full context: logs, files, deps, acceptance criteria |
| `td_critical_path()` | Optimal sequence to unblock the most work |

## Role-specific usage

- **Team-lead**: `usage`, `status`, `ws` (start/tag/log/handoff), `critical-path`, `blocked`, `dep` for orchestration and dependency-gate decisions.
- **Product-manager**: `create`, `epic`, `tree`, `dep`, `critical-path`, `query`, `context` for decomposition and plan validation.
- **Staff-engineer**: `start`, `focus`, `next`, `context`, `log` (with logType), `ws log`, `comment`, `files`, `handoff`, `review`.
- **Validator**: `context`, `files`, `query`, `dep` for loading full task context and verifying file/dependency state.
- **Code-reviewer**: `reviewable`, `in-review`, `context`, `files`, `comment` for review queue awareness and inline feedback.

## Failure handling

- No active task: create/start task before edits.
- Wrong task focused: switch with `td_focus` before proceeding.
- Review blocked: log blocker details and recommended next action.
- Dependency conflict: issue depends on a blocked issue → run `td_critical_path()` to find unblocking sequence; use `td_dep(task: "td-xxx", action: "list")` to inspect the dependency chain.
- Work session stale: ws has tagged issues but no recent logs → run `td_ws(action: "current")` to check state; re-tag or handoff as appropriate.
- Blocked issue not auto-unblocking: verify blocking issue was *approved* (not just completed) → check with `td_dep(task: "td-xxx", action: "list")`; auto-unblock only triggers on `approve`, not `review`.

## Handoff quality bar
- `done`: concrete completed outcomes.
- `remaining`: clear next tasks.
- `decision`: key technical or product decisions.
- `uncertain`: unresolved questions or risks.
