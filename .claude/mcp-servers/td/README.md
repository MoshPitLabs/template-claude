# TD MCP Server

MCP (Model Context Protocol) server for Task-Driven (TD) CLI integration with Claude Code.

## Overview

This MCP server exposes the TD CLI as structured tools that Claude Code can use directly. It provides 33 tools covering the full TD workflow lifecycle:

- **Session/bootstrap**: `td_status`, `td_whoami`, `td_usage`
- **Planning**: `td_create`, `td_epic`, `td_tree`, `td_update`
- **Execution**: `td_start`, `td_focus`, `td_log`, `td_comment`, `td_files`
- **Dependencies**: `td_dep`, `td_critical_path`, `td_block`, `td_unblock`
- **Work sessions**: `td_ws` (start/tag/log/current/handoff)
- **Queries**: `td_query`, `td_search`
- **Introspection**: `td_next`, `td_ready`, `td_blocked`, `td_in_review`, `td_reviewable`, `td_context`
- **Closeout**: `td_review`, `td_handoff`, `td_approve`, `td_reject`

## Installation

### 1. Install Dependencies

```bash
cd .claude/mcp-servers/td
npm install
```

### 2. Build the Server

```bash
npm run build
```

This compiles TypeScript to JavaScript in the `dist/` directory.

### 3. Configure Claude Code

Add the TD MCP server to your Claude Code settings file (`~/.claude/settings.json`):

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

**Important**: Replace `/absolute/path/to/template-claude/` with the actual absolute path to this project.

### 4. Restart Claude Code

After updating settings, restart Claude Code for the MCP server to be loaded.

## Usage

Once configured, Claude Code can use TD tools directly. The tools are prefixed with `td_`:

### Examples

**Check status:**
```
Use the td_status tool
```

**Start a task:**
```
Use td_start with task "td-abc123"
```

**Create a new task:**
```
Use td_create with title "Add user authentication", type "feature", priority "P1"
```

**Add structured log:**
```
Use td_log with message "Choosing JWT for stateless auth", logType "decision"
```

**Work session:**
```
Use td_ws with action "start", name "sprint-23"
```

## Tool Reference

### Session Management

| Tool | Description | Parameters |
|------|-------------|------------|
| `td_status` | Get TD status | - |
| `td_whoami` | Get session identity | - |
| `td_usage` | Show usage stats | `newSession?: boolean` |

### Task Execution

| Tool | Description | Parameters |
|------|-------------|------------|
| `td_start` | Start a task | `task: string` |
| `td_focus` | Focus on a task | `task: string` |
| `td_link` | Link files to task | `task: string, files: string[]` |
| `td_unlink` | Unlink files | `task: string, files: string[]` |
| `td_log` | Add log entry | `message: string, logType?: "decision"\|"blocker"\|"hypothesis"\|"tried"\|"result"` |
| `td_comment` | Add comment | `task: string, text: string` |
| `td_files` | Show linked files | `task: string` |

### Task Creation

| Tool | Description | Parameters |
|------|-------------|------------|
| `td_create` | Create task | `title: string, type?: "bug"\|"feature"\|"task"\|"epic"\|"chore", priority?: "P0"-"P4", labels?: string, description?: string, parent?: string, minor?: boolean, points?: number, acceptance?: string, dependsOn?: string, blocks?: string` |
| `td_epic` | Create epic | `title: string, priority?: "P0"-"P4", labels?: string, description?: string, parent?: string, blocks?: string, dependsOn?: string` |
| `td_update` | Update task | `task: string, title?: string, description?: string, priority?: string, type?: string, labels?: string` |
| `td_tree` | Show/modify tree | `task: string, childIssue?: string` |

### Dependencies

| Tool | Description | Parameters |
|------|-------------|------------|
| `td_dep` | Manage deps | `task: string, action?: "add"\|"list"\|"blocking", targetIssue?: string` |
| `td_critical_path` | Show critical path | - |
| `td_block` | Block task | `task: string` |
| `td_unblock` | Unblock task | `task: string` |

### Work Sessions

| Tool | Description | Parameters |
|------|-------------|------------|
| `td_ws` | Work session ops | `action: "start"\|"tag"\|"log"\|"current"\|"handoff", name?: string, issueIds?: string[], noStart?: boolean, message?: string, done?: string, remaining?: string, decision?: string, uncertain?: string` |

### Queries

| Tool | Description | Parameters |
|------|-------------|------------|
| `td_query` | Execute TDQ | `query: string` |
| `td_search` | Full-text search | `query: string` |
| `td_next` | Next priority item | - |
| `td_ready` | Ready items | - |
| `td_blocked` | Blocked items | - |
| `td_in_review` | In-review items | - |
| `td_reviewable` | Reviewable items | - |
| `td_context` | Full task context | `task: string` |

### Review

| Tool | Description | Parameters |
|------|-------------|------------|
| `td_review` | Submit for review | `task: string` |
| `td_approve` | Approve task | `task?: string, reason?: string` |
| `td_reject` | Reject task | `task?: string, reason?: string` |
| `td_handoff` | Create handoff | `task?: string, done?: string, remaining?: string, decision?: string, uncertain?: string` |

## Development

### Watch Mode

For development with auto-rebuild:

```bash
npm run dev
```

### Testing

Test the MCP server directly:

```bash
node dist/index.js
```

The server communicates via stdio, so you'll need an MCP client to interact with it properly.

## Migration from OpenCode

This MCP server replaces the `.opencode/tools/td.ts` OpenCode tool. The functionality is identical, but the interface follows MCP conventions:

- **OpenCode**: Single `td` tool with `action` parameter
- **Claude Code MCP**: Separate tool per action (e.g., `td_status`, `td_start`)

See `.claude/MIGRATION.md` for full migration details.

## Prerequisites

- **TD CLI** must be installed and available in PATH
- Install from: https://github.com/MoshPitLabs/td
- Initialize in project: `td init`

## Troubleshooting

### Server not loading

1. Check that the path in `~/.claude/settings.json` is absolute
2. Verify the server built successfully: `ls .claude/mcp-servers/td/dist/index.js`
3. Check Claude Code logs for MCP errors

### TD commands failing

1. Verify TD CLI is installed: `td version`
2. Check that TD is initialized in the project: `td status`
3. Review TD CLI documentation for command-specific issues

### Tools not appearing

1. Restart Claude Code after configuration changes
2. Verify MCP server configuration in settings
3. Check that the server process can start: `node dist/index.js` (should not error immediately)

## License

MIT - Same as parent project
