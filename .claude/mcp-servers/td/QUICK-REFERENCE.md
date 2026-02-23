# TD MCP Tools - Quick Reference

Quick lookup for all 33 TD MCP tools.

## Format
```
tool_name(param: type) → description
```

---

## Session Management

```
td_status() → Get current TD status (active task, session info)
td_whoami() → Get session identity
td_usage(newSession?: boolean) → Show usage stats, optionally start new session
```

## Task Execution

```
td_start(task: string) → Start working on a task
td_focus(task: string) → Switch focus to another task
td_log(message: string, logType?: enum) → Add log entry
  logType: "decision" | "blocker" | "hypothesis" | "tried" | "result"
td_link(task: string, files: string[]) → Link files to task
td_unlink(task: string, files: string[]) → Unlink files from task
td_files(task: string) → Show files linked to task
td_comment(task: string, text: string) → Add comment to task
```

## Task Creation

```
td_create(title: string, type?: enum, priority?: enum, ...) → Create task
  type: "bug" | "feature" | "task" | "epic" | "chore"
  priority: "P0" | "P1" | "P2" | "P3" | "P4"
  Optional: labels, description, parent, minor, points, acceptance, dependsOn, blocks

td_epic(title: string, priority?: enum, ...) → Create epic
  priority: "P0" | "P1" | "P2" | "P3" | "P4"
  Optional: labels, description, parent, blocks, dependsOn

td_update(task: string, title?: string, ...) → Update task metadata
  Optional: description, priority, type, labels

td_tree(task: string, childIssue?: string) → Show tree or add child
```

## Dependencies

```
td_dep(task: string, action?: enum, targetIssue?: string) → Manage dependencies
  action: "add" | "list" | "blocking" (default: "list")

td_critical_path() → Show optimal unblocking sequence

td_block(task: string) → Mark task as blocked
td_unblock(task: string) → Unblock task
```

## Work Sessions

```
td_ws(action: enum, ...) → Work session operations
  action: "start" | "tag" | "log" | "current" | "handoff"

  start: name: string
  tag: issueIds: string[], noStart?: boolean
  log: message: string
  current: (no params)
  handoff: done?: string, remaining?: string, decision?: string, uncertain?: string
```

## Queries

```
td_query(query: string) → Execute TDQ query
  Examples:
  - "status = in_progress AND priority <= P1"
  - "type = bug OR type = feature"
  - "labels ~ auth"
  - "rework()"
  - "stale(14)"

td_search(query: string) → Full-text search across tasks

td_next() → Show highest-priority open issue
td_ready() → Show all ready (open) issues by priority
td_blocked() → Show all blocked issues
td_in_review() → Show all issues in review
td_reviewable() → Show issues this session can review
td_context(task: string) → Show full task context (logs, files, deps, AC)
```

## Review

```
td_review(task: string) → Submit task for review
td_approve(task?: string, reason?: string) → Approve task (uses focused if no task)
td_reject(task?: string, reason?: string) → Reject task (uses focused if no task)
td_handoff(task?: string, ...) → Create handoff notes
  Optional: done, remaining, decision, uncertain
```

---

## Common Workflows

### Start Work
```
td_status()
td_start(task: "td-abc123")
td_log(message: "Starting implementation", logType: "decision")
```

### Create & Start Task
```
td_create(title: "Add feature", type: "feature", priority: "P1")
td_start(task: "td-abc123")
```

### Log Structured Entry
```
td_log(message: "Using JWT for auth", logType: "decision")
td_log(message: "API rate limiting unclear", logType: "blocker")
td_log(message: "Tried session-based auth", logType: "tried")
```

### Submit for Review
```
td_review(task: "td-abc123")
td_handoff(task: "td-abc123",
  done: "Implemented auth",
  remaining: "Add tests",
  decision: "JWT over sessions",
  uncertain: "Token expiry duration")
```

### Work Session
```
td_ws(action: "start", name: "sprint-23")
td_ws(action: "tag", issueIds: ["td-aaa", "td-bbb"])
td_ws(action: "log", message: "Both tasks progressing")
td_ws(action: "current")
```

### Dependency Management
```
td_dep(task: "td-later", action: "add", targetIssue: "td-earlier")
td_dep(task: "td-abc", action: "list")
td_critical_path()
```

### Queries
```
td_query(query: "status = in_progress AND priority <= P1")
td_search(query: "authentication")
td_next()
td_ready()
```

---

## Migration from OpenCode

| OpenCode | MCP |
|----------|-----|
| `TD(action: "status")` | `td_status()` |
| `TD(action: "start", task: "x")` | `td_start(task: "x")` |
| `TD(action: "log", message: "...", logType: "decision")` | `td_log(message: "...", logType: "decision")` |
| `TD(action: "ws", wsAction: "start", wsName: "...")` | `td_ws(action: "start", name: "...")` |
| `TD(action: "create", task: "title", ...)` | `td_create(title: "title", ...)` |
| `TD(action: "block-issue", task: "x")` | `td_block(task: "x")` |

---

## Tips

- Use `td_status()` frequently to check active task
- Use `logType` for structured, searchable logs
- Use `td_next()` when unsure what to work on
- Use `td_context(task: "x")` before starting work to see full context
- Use work sessions (`td_ws`) for multi-issue work
- Use `td_critical_path()` to unblock the most work
- Use `td_handoff` with all 4 fields (done, remaining, decision, uncertain)

---

## See Also

- Full documentation: `README.md`
- Setup guide: `SETUP-GUIDE.md`
- Conversion details: `CONVERSION.md`
- TD workflow skill: `.claude/skills/td-workflow/SKILL.md`
