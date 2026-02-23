---
name: td-workflow
description: Enforce a consistent TD lifecycle across planning, implementation, validation, and review
license: MIT
compatibility: opencode
metadata:
  audience: engineering
  workflow: td
---
## What I do
- Standardize TD lifecycle usage across all role agents.
- Prefer the OpenCode `td` custom tool over raw shell commands.
- Keep logs and handoffs high-signal for context continuity.

## Tool-first policy

Use the `td` custom tool first. CLI fallback is allowed only if the tool is unavailable.

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
1. Start context: `TD(action: "usage", newSession: true)`
2. Confirm status: `TD(action: "status")`
3. Start work: `TD(action: "start", task: "TASK-ID")`
4. Log progress: `TD(action: "log", message: "...", logType: "decision"|"blocker"|...)`
5. Submit for review: `TD(action: "review", task: "TASK-ID")`
6. End session: `TD(action: "handoff", task: "TASK-ID", done: "...", remaining: "...", decision: "...", uncertain: "...")`

### Multi-issue path (work sessions)
1. Start context: `TD(action: "usage", newSession: true)`
2. Start work session: `TD(action: "ws", wsAction: "start", wsName: "phase2-alignment")`
3. Tag issues: `TD(action: "ws", wsAction: "tag", issueIds: ["td-aaa", "td-bbb", "td-ccc"])`
4. Fan-out log: `TD(action: "ws", wsAction: "log", message: "Implementation in progress")`
5. Submit each for review: `TD(action: "review", task: "td-aaa")` (per issue)
6. Grouped handoff: `TD(action: "ws", wsAction: "handoff", done: "...", remaining: "...", decision: "...", uncertain: "...")`

## Epic Lifecycle

```text
# 1. Create epic
TD(action: "epic", task: "Multi-user support", priority: "P1")

# 2. Create children
TD(action: "create", task: "User registration", type: "task", parent: "td-epic-id", points: 3, acceptance: "...")

# 3. Verify tree structure
TD(action: "tree", task: "td-epic-id")

# 4. Attach existing issue as child
TD(action: "tree", task: "td-parent-id", childIssue: "td-existing-id")

# 5. Scope queries to epic
TD(action: "query", query: "parent = td-epic-id AND status = open")

# 6. View full epic context
TD(action: "context", task: "td-epic-id")
```

## Dependency Management

```text
# Add dependency (td-later depends on td-earlier)
TD(action: "dep", depAction: "add", task: "td-later", targetIssue: "td-earlier")

# View what an issue depends on
TD(action: "dep", depAction: "list", task: "td-xxx")

# View what an issue is blocking
TD(action: "dep", depAction: "blocking", task: "td-xxx")

# Find optimal unblocking sequence
TD(action: "critical-path")

# Manual block/unblock
TD(action: "block-issue", task: "td-xxx")
TD(action: "unblock-issue", task: "td-xxx")
```

**Auto-unblocking:** When a blocking issue is approved, TD automatically transitions dependents from `blocked` → `open` (when all their dependencies are resolved). No manual action needed.

## Work Sessions

**Session vs work session:**
- **TD session** = identity (automatic per terminal/agent context; enforces review isolation)
- **Work session** = optional grouping container (`td ws`) for multi-issue work

```text
# Start named work session
TD(action: "ws", wsAction: "start", wsName: "phase2-alignment")

# Tag issues (auto-starts them)
TD(action: "ws", wsAction: "tag", issueIds: ["td-aaa", "td-bbb"])

# Tag without starting
TD(action: "ws", wsAction: "tag", issueIds: ["td-ccc"], noStart: true)

# Fan-out log to all tagged issues
TD(action: "ws", wsAction: "log", message: "Shared progress update")

# View current session state
TD(action: "ws", wsAction: "current")

# Grouped handoff (ends session)
TD(action: "ws", wsAction: "handoff", done: "...", remaining: "...", decision: "...", uncertain: "...")
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
TD(action: "log", message: "Using JWT for stateless auth", logType: "decision")
TD(action: "log", message: "Refresh token rotation unclear", logType: "blocker")
TD(action: "log", message: "Session-based approach too complex", logType: "tried")
```

## TDQ Queries

```text
# Filter by status and priority
TD(action: "query", query: "status = in_progress AND priority <= P1")

# Filter by type
TD(action: "query", query: "type = bug OR type = feature")

# Label contains
TD(action: "query", query: "labels ~ auth")

# Issues needing rework (rejected)
TD(action: "query", query: "rework()")

# Stale issues (not updated in N days)
TD(action: "query", query: "stale(14)")

# Date-relative
TD(action: "query", query: "created >= -7d")

# Full-text search
TD(action: "search", query: "authentication")
```

## Introspection Commands

| Action | Purpose |
|--------|---------|
| `TD(action: "next")` | Highest-priority open issue to work on |
| `TD(action: "ready")` | All open issues by priority |
| `TD(action: "blocked")` | All currently blocked issues |
| `TD(action: "in-review")` | All issues awaiting review |
| `TD(action: "reviewable")` | Issues this session can review (not self-implemented) |
| `TD(action: "context", task: "td-xxx")` | Full context: logs, files, deps, acceptance criteria |
| `TD(action: "critical-path")` | Optimal sequence to unblock the most work |

## Role-specific usage

- **Team-lead**: `usage`, `status`, `ws` (start/tag/log/handoff), `critical-path`, `blocked`, `dep` for orchestration and dependency-gate decisions.
- **Product-manager**: `create`, `epic`, `tree`, `dep`, `critical-path`, `query`, `context` for decomposition and plan validation.
- **Staff-engineer**: `start`, `focus`, `next`, `context`, `log` (with logType), `ws log`, `comment`, `files`, `handoff`, `review`.
- **Validator**: `context`, `files`, `query`, `dep` for loading full task context and verifying file/dependency state.
- **Code-reviewer**: `reviewable`, `in-review`, `context`, `files`, `comment` for review queue awareness and inline feedback.

## Failure handling

- No active task: create/start task before edits.
- Wrong task focused: switch with `focus` before proceeding.
- Review blocked: log blocker details and recommended next action.
- Dependency conflict: issue depends on a blocked issue → run `TD(action: "critical-path")` to find unblocking sequence; use `TD(action: "dep", depAction: "list", task: "td-xxx")` to inspect the dependency chain.
- Work session stale: ws has tagged issues but no recent logs → run `TD(action: "ws", wsAction: "current")` to check state; re-tag or handoff as appropriate.
- Blocked issue not auto-unblocking: verify blocking issue was *approved* (not just completed) → check with `TD(action: "dep", depAction: "list", task: "td-xxx")`; auto-unblock only triggers on `approve`, not `review`.

## Handoff quality bar
- `done`: concrete completed outcomes.
- `remaining`: clear next tasks.
- `decision`: key technical or product decisions.
- `uncertain`: unresolved questions or risks.
