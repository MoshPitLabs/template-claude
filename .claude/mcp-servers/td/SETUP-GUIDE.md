# TD MCP Server - Quick Setup Guide

This guide will get the TD MCP server running with Claude Code in 5 minutes.

## Prerequisites

✅ **Node.js** (v18+) and **npm** installed
✅ **TD CLI** installed and in PATH (`td version` works)
✅ **Claude Code** installed

## Step 1: Build the Server

Run the setup script from the project root:

```bash
.claude/mcp-servers/setup-td.sh
```

This will:
- Install npm dependencies
- Compile TypeScript to JavaScript
- Generate configuration instructions

## Step 2: Configure Claude Code

Edit your Claude Code settings file:

```bash
# Open settings file
nano ~/.claude/settings.json
# or
code ~/.claude/settings.json
```

Add the TD MCP server configuration:

```json
{
  "mcpServers": {
    "td": {
      "command": "node",
      "args": ["/absolute/path/to/template-claude/.claude/mcp-servers/td/dist/index.js"]
    }
  }
}
```

**Important**: Replace `/absolute/path/to/template-claude/` with your actual project path.

### If you already have mcpServers

Merge the `td` entry into your existing `mcpServers` object:

```json
{
  "mcpServers": {
    "existing-server": {
      "command": "...",
      "args": ["..."]
    },
    "td": {
      "command": "node",
      "args": ["/absolute/path/to/template-claude/.claude/mcp-servers/td/dist/index.js"]
    }
  }
}
```

## Step 3: Restart Claude Code

Close and reopen Claude Code for the MCP server to load.

## Step 4: Test It

In Claude Code, try these commands:

### Basic Status Check
```
Use the td_status tool to check TD status
```

Expected output: Current TD status (active task, session info)

### Start a Task
```
Use td_start to start task "td-abc123"
```

Expected output: Confirmation that the task started

### Create a New Task
```
Use td_create to create a new task with title "Test TD MCP integration" and type "task"
```

Expected output: New task ID (e.g., `td-a1b2c3d4`)

## Available Tools

Once configured, Claude Code has access to 33 TD tools:

### Session Management
- `td_status` - Get current TD status
- `td_whoami` - Get session identity
- `td_usage` - Show usage statistics

### Task Execution
- `td_start` - Start a task
- `td_focus` - Switch focus to another task
- `td_log` - Add log entry (with optional `logType`: decision, blocker, hypothesis, tried, result)
- `td_link` - Link files to task
- `td_unlink` - Unlink files from task
- `td_files` - Show linked files
- `td_comment` - Add comment to task

### Task Creation
- `td_create` - Create a new task/issue
- `td_epic` - Create an epic
- `td_update` - Update task metadata
- `td_tree` - Show/modify task hierarchy

### Dependencies
- `td_dep` - Manage dependencies
- `td_critical_path` - Show optimal unblocking sequence
- `td_block` - Block a task
- `td_unblock` - Unblock a task

### Work Sessions
- `td_ws` - Work session operations (start, tag, log, current, handoff)

### Queries
- `td_query` - Execute TDQ query
- `td_search` - Full-text search
- `td_next` - Next priority item
- `td_ready` - Ready items
- `td_blocked` - Blocked items
- `td_in_review` - In-review items
- `td_reviewable` - Reviewable items
- `td_context` - Full task context

### Review
- `td_review` - Submit task for review
- `td_approve` - Approve task
- `td_reject` - Reject task
- `td_handoff` - Create handoff notes

## Troubleshooting

### "TD CLI is not available"

**Problem**: MCP server can't find the `td` command

**Solution**:
1. Verify TD CLI is installed: `td version`
2. Ensure TD is in PATH: `which td`
3. If using nvm or similar, ensure Node process inherits correct PATH

### "Tools not appearing in Claude Code"

**Problem**: TD tools don't show up in Claude Code

**Solution**:
1. Check settings file has correct absolute path
2. Verify build succeeded: `ls .claude/mcp-servers/td/dist/index.js`
3. Restart Claude Code completely
4. Check Claude Code logs for MCP errors

### "Build failed"

**Problem**: TypeScript compilation errors

**Solution**:
1. Ensure Node.js 18+ is installed: `node --version`
2. Delete `node_modules` and rebuild:
   ```bash
   cd .claude/mcp-servers/td
   rm -rf node_modules package-lock.json
   npm install
   npm run build
   ```

### "Command execution fails"

**Problem**: Tools load but commands fail

**Solution**:
1. Test TD CLI directly: `td status`
2. Initialize TD in project: `td init`
3. Check TD configuration: `cat .td/config.json`

## Usage Examples

### Basic Workflow

```
1. Start a new session:
   "Use td_usage with newSession set to true"

2. Check status:
   "Use td_status"

3. Start a task:
   "Use td_start with task 'td-abc123'"

4. Log progress:
   "Use td_log with message 'Implemented authentication' and logType 'decision'"

5. Submit for review:
   "Use td_review with task 'td-abc123'"
```

### Creating Tasks

```
"Use td_create with:
- title: 'Add user authentication'
- type: 'feature'
- priority: 'P1'
- acceptance: 'Users can log in with email/password'
"
```

### Work Sessions

```
1. Start session:
   "Use td_ws with action 'start' and name 'sprint-23'"

2. Tag issues:
   "Use td_ws with action 'tag' and issueIds ['td-aaa', 'td-bbb']"

3. Log to all tagged:
   "Use td_ws with action 'log' and message 'Making progress on both tasks'"
```

## Skills Integration

The `td-workflow` skill has been updated to use these MCP tools. Invoke it with:

```
/td-workflow
```

This will load the TD workflow skill which uses the MCP tools internally.

## Next Steps

1. ✅ Set up TD MCP server (you just did this!)
2. 📚 Read the full TD CLI documentation: https://github.com/MoshPitLabs/td
3. 🎯 Review the td-workflow skill: `.claude/skills/td-workflow/SKILL.md`
4. 🔧 Configure TD hooks: `.claude/hooks/td-enforcer.sh`
5. 📖 Read the migration guide: `.claude/MIGRATION.md`

## Resources

- **TD MCP Server README**: `.claude/mcp-servers/td/README.md`
- **Conversion Details**: `.claude/mcp-servers/td/CONVERSION.md`
- **MCP Specification**: https://spec.modelcontextprotocol.io/
- **TD CLI**: https://github.com/MoshPitLabs/td

## Support

If you encounter issues:

1. Check this guide's troubleshooting section
2. Review the main README: `.claude/mcp-servers/td/README.md`
3. Check TD CLI documentation
4. Review Claude Code MCP documentation

## License

MIT - Same as parent project
