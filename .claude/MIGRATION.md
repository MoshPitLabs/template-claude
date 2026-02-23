# OpenCode → Claude Code Migration

This document describes the migration from OpenCode plugins to Claude Code hooks.

## Migration Date
2026-02-23

## Summary

This project was originally configured for **OpenCode** with 5 TypeScript plugins. It has been migrated to **Claude Code** with shell-based hooks.

### What Changed

| OpenCode Component | Claude Code Equivalent | Status |
|-------------------|------------------------|--------|
| `.opencode/plugins/security.ts` | `.claude/hooks/security-check.sh` | ✅ Migrated |
| `.opencode/plugins/td-enforcer.ts` | `.claude/hooks/td-enforcer.sh` | ✅ Migrated |
| `.opencode/tools/td.ts` | `.claude/mcp-servers/td/` | ✅ Migrated |
| `.opencode/plugins/logging.ts` | *(Claude Code native logging)* | ⚠️ Not migrated (not needed) |
| `.opencode/plugins/notifications.ts` | *(Claude Code native notifications)* | ⚠️ Not migrated (not needed) |
| `.opencode/plugins/post-stop-detector.ts` | *(No equivalent)* | ❌ Not migrated (too complex) |

## Migrated Features

### ✅ Security Enforcement
**OpenCode plugin**: `security.ts`
**Claude Code hook**: `security-check.sh`

- Blocks `.env` files (except examples/templates)
- Blocks key material (`.pem`, `.key`, SSH keys, certificates)
- Blocks credential files
- Blocks dangerous `rm -rf` patterns
- Logs violations to `~/.claude/logs/security/security.jsonl`

### ✅ TD Task Enforcement
**OpenCode plugin**: `td-enforcer.ts`
**Claude Code hook**: `td-enforcer.sh`

- Requires active TD task before Write/Edit operations
- Auto-links modified files to active task
- Auto-logs file edits to TD
- Logs events to `~/.claude/logs/td/td_enforcer.jsonl`
- Gracefully handles TD not installed

### ✅ TD CLI Tool Integration
**OpenCode tool**: `td.ts`
**Claude Code MCP server**: `.claude/mcp-servers/td/`

- Exposes 33 TD CLI operations as structured MCP tools
- Replaces single `td` tool with action parameter with individual tools per action
- Tools prefixed with `td_` (e.g., `td_status`, `td_start`, `td_create`)
- Full coverage: session management, task execution, dependencies, work sessions, queries, reviews
- See `.claude/mcp-servers/td/README.md` for setup and usage

## Not Migrated

### ⚠️ Event Logging
**OpenCode plugin**: `logging.ts`

**Reason**: Claude Code has built-in logging. Custom JSONL event tracking is redundant.

**What was lost**:
- Comprehensive tool execution tracking
- Session lifecycle event logs
- Message flow logging

**Mitigation**: Use Claude Code's native logging and the individual hook logs (security, TD enforcer).

### ⚠️ Session Notifications
**OpenCode plugin**: `notifications.ts`

**Reason**: Claude Code likely has built-in session notifications. Shell-based toast notifications are limited.

**What was lost**:
- Session start/end toasts with metrics
- Session error notifications
- Duration, tool count, file count, token usage metrics

**Mitigation**: Check Claude Code's native notification system.

### ❌ Orphaned File Detection
**OpenCode plugin**: `post-stop-detector.ts`

**Reason**: Requires complex state management (file system watching, snapshots, delayed execution) not suitable for shell hooks.

**What was lost**:
- Automatic detection of files created/modified after session idle
- 30-second post-session monitoring
- Orphaned change reports

**Mitigation**: Manually run `git status` and `git diff` after sessions to check for uncommitted changes.

## Configuration Required

To enable the migrated hooks, configure Claude Code hooks. See `.claude/hooks/README.md` for detailed configuration instructions.

**Quick setup** (user-level):

Edit `~/.claude/settings.json`:
```json
{
  "hooks": {
    "tool-call-before": [
      {
        "tool": "Bash",
        "command": "<project-path>/.claude/hooks/security-check.sh"
      },
      {
        "tool": "Write",
        "command": "<project-path>/.claude/hooks/security-check.sh"
      },
      {
        "tool": "Write",
        "command": "<project-path>/.claude/hooks/td-enforcer.sh"
      },
      {
        "tool": "Edit",
        "command": "<project-path>/.claude/hooks/security-check.sh"
      },
      {
        "tool": "Edit",
        "command": "<project-path>/.claude/hooks/td-enforcer.sh"
      }
    ]
  }
}
```

Replace `<project-path>` with the full path to this project.

## Testing the Migration

1. **Test security hook**:
   ```bash
   cd .claude/hooks
   TOOL_NAME=Read FILE_PATH=".env" ./security-check.sh
   # Should exit 1 (blocked)
   ```

2. **Test TD enforcer**:
   ```bash
   # Without active task
   td status  # Should show no active task
   TOOL_NAME=Write FILE_PATH="test.ts" ./td-enforcer.sh
   # Should exit 1 (blocked)

   # With active task
   td start <task-id>
   TOOL_NAME=Write FILE_PATH="test.ts" ./td-enforcer.sh
   # Should exit 0 (allowed)
   ```

3. **Test in Claude Code**:
   - Try to read `.env` file → should be blocked
   - Try to edit a file without active TD task → should be blocked
   - Start a TD task, then edit a file → should succeed and auto-link

## Reverting the Migration

If you need to revert to OpenCode:

1. Restore the OpenCode plugins from git history:
   ```bash
   git checkout <commit-before-migration> -- .opencode/plugins/
   ```

2. Remove Claude Code hooks:
   ```bash
   rm -rf .claude/
   ```

3. Update `opencode.json` to re-enable plugins

## Architecture Notes

### OpenCode Plugin System
- **Language**: TypeScript
- **Execution**: Async, within OpenCode process
- **API Access**: Full OpenCode client API (TUI, logging, events, file system)
- **State**: Can maintain in-memory state, watch file system
- **Performance**: Native, minimal overhead

### Claude Code Hook System
- **Language**: Shell scripts (Bash)
- **Execution**: Synchronous, subprocess invocation
- **API Access**: Limited to environment variables and exit codes
- **State**: Stateless (each invocation is independent)
- **Performance**: Slight subprocess overhead

### Key Differences

| Feature | OpenCode Plugins | Claude Code Hooks |
|---------|-----------------|-------------------|
| Language | TypeScript | Shell (Bash) |
| State | Stateful | Stateless |
| API | Rich (client methods) | Limited (env vars) |
| Async | Yes | No (blocking) |
| Complexity | High | Low |
| Flexibility | Very flexible | More constrained |

## Next Steps

1. Configure hooks in Claude Code settings (see above)
2. Test hooks with real workflow
3. Adjust hook scripts as needed for your use case
4. Remove this project's OpenCode configuration if fully migrated

## Questions or Issues?

- For hook configuration: See `.claude/hooks/README.md`
- For TD CLI usage: See TD documentation
- For Claude Code hooks: Consult Claude Code documentation

## License

MIT - Same as parent project
