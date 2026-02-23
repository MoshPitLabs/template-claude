# Claude Code Hooks

This directory contains Claude Code hooks that replace the OpenCode plugins.

## Migrated Hooks

### 1. security-check.sh
**Purpose**: Blocks access to sensitive files and dangerous commands
**Replaces**: `.opencode/plugins/security.ts`

**Features**:
- Blocks access to `.env` files (except `.env.example`, `.env.sample`, `.env.template`)
- Blocks access to key material (`.pem`, `.key`, SSH keys, certificates)
- Blocks access to credential files
- Blocks dangerous `rm -rf` command patterns
- Logs security blocks to `~/.claude/logs/security/security.jsonl`

**Blocked patterns**:
- File paths: `.env`, `secrets/`, `*.pem`, `*.key`, `credentials*.json`, `id_rsa`, `*.p12`, `*.pfx`, `*.jks`, `*.keystore`
- Commands: `rm -rf`, `rm -fr`, `rm --recursive --force`

### 2. td-enforcer.sh
**Purpose**: Requires active TD task before file edits, auto-links files
**Replaces**: `.opencode/plugins/td-enforcer.ts`

**Features**:
- Blocks Write/Edit operations when no active TD task exists
- Auto-links modified files to the active TD task
- Auto-logs file edits to TD task
- Logs enforcement events to `~/.claude/logs/td/td_enforcer.jsonl`
- Gracefully handles TD not being installed (allows normal operation)

**File tracking**:
- Tracks: `.ts`, `.tsx`, `.js`, `.jsx`, `.go`, `.py`, `.java`, `.kt`, `.rs`, `.c`, `.cpp`, `.rb`, `.php`, `.swift`, `.vue`, `.svelte`, `.md`, `.sql`, `.css`, `.html`, `.yaml`, `.json`, `.sh`
- Excludes: `node_modules/`, `dist/`, `build/`, `.git/`, `target/`, `vendor/`, `.next/`, coverage directories

## Configuration

### Project-level hooks (configured)

✅ Hooks are configured in `.claude/config.json` for this project.

The configuration uses relative paths so the hooks work automatically when you're in the project directory.

### User-level hooks (optional, for global enforcement)

If you want these hooks to apply to all projects, edit `~/.claude/settings.json`:

```json
{
  "hooks": {
    "tool-call-before": [
      {
        "tool": "Bash",
        "command": "/home/moshpitcodes/Development/MoshPitLabs/template-claude/.claude/hooks/security-check.sh"
      },
      {
        "tool": "Read",
        "command": "/home/moshpitcodes/Development/MoshPitLabs/template-claude/.claude/hooks/security-check.sh"
      },
      {
        "tool": "Write",
        "command": "/home/moshpitcodes/Development/MoshPitLabs/template-claude/.claude/hooks/security-check.sh"
      },
      {
        "tool": "Write",
        "command": "/home/moshpitcodes/Development/MoshPitLabs/template-claude/.claude/hooks/td-enforcer.sh"
      },
      {
        "tool": "Edit",
        "command": "/home/moshpitcodes/Development/MoshPitLabs/template-claude/.claude/hooks/security-check.sh"
      },
      {
        "tool": "Edit",
        "command": "/home/moshpitcodes/Development/MoshPitLabs/template-claude/.claude/hooks/td-enforcer.sh"
      },
      {
        "tool": "Glob",
        "command": "/home/moshpitcodes/Development/MoshPitLabs/template-claude/.claude/hooks/security-check.sh"
      },
      {
        "tool": "Grep",
        "command": "/home/moshpitcodes/Development/MoshPitLabs/template-claude/.claude/hooks/security-check.sh"
      }
    ]
  }
}
```

### Environment Variables

The hooks expect these environment variables to be set by Claude Code:
- `TOOL_NAME` - Name of the tool being executed
- `FILE_PATH` - File path being accessed/modified
- `BASH_COMMAND` - Full bash command (for Bash tool)

## Testing

Test the hooks manually:

```bash
# Test security check
TOOL_NAME=Read FILE_PATH=".env" ./.claude/hooks/security-check.sh
# Should exit 1 (blocked)

TOOL_NAME=Read FILE_PATH=".env.example" ./.claude/hooks/security-check.sh
# Should exit 0 (allowed)

# Test TD enforcer (requires td CLI)
TOOL_NAME=Write FILE_PATH="src/test.ts" ./.claude/hooks/td-enforcer.sh
# Should exit 1 if no active task, 0 if task is active
```

## Migration Notes

### Not Migrated

The following OpenCode plugin features were **not migrated** to Claude Code hooks due to architectural limitations:

1. **logging.ts** - Comprehensive event tracking
   - **Reason**: Claude Code has its own logging system; custom JSONL logging is less critical
   - **Partial replacement**: Security and TD hooks log their own events

2. **notifications.ts** - Session lifecycle toast notifications
   - **Reason**: Claude Code likely has built-in notification system; shell-based toasts are limited
   - **Alternative**: Check Claude Code's native notification features

3. **post-stop-detector.ts** - Orphaned file detection after session idle
   - **Reason**: Requires complex state management and file system watching not suitable for shell hooks
   - **Alternative**: Manual git diff checks after sessions

### Differences from OpenCode Plugins

- **Execution model**: Hooks are synchronous shell scripts, not async TypeScript
- **API access**: No direct access to OpenCode client API (TUI, logging, events)
- **Performance**: Shell hooks have slight overhead vs. native plugins
- **Error handling**: Simpler error handling compared to TypeScript

## Logs

Hook execution logs are written to:
- Security: `~/.claude/logs/security/security.jsonl`
- TD Enforcer: `~/.claude/logs/td/td_enforcer.jsonl`

View logs:
```bash
# View recent security blocks
tail -f ~/.claude/logs/security/security.jsonl | jq

# View TD enforcement events
tail -f ~/.claude/logs/td/td_enforcer.jsonl | jq
```

## Troubleshooting

### Hooks not executing
- Verify hooks are executable: `ls -la .claude/hooks/`
- Check Claude Code settings for correct hook configuration
- Ensure environment variables are being passed by Claude Code

### TD enforcer not working
- Verify TD CLI is installed: `which td`
- Check TD status: `td status --json`
- Ensure you're in a TD-initialized directory

### Security check too strict
- Review and adjust patterns in `security-check.sh`
- Add custom allowed patterns if needed

## License

MIT License - Same as the parent project
