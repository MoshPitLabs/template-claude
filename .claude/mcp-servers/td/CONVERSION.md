# OpenCode td.ts → Claude Code MCP Server Conversion

This document describes the conversion of the OpenCode `td.ts` tool to a Claude Code MCP server.

## Overview

**Source**: `.opencode/tools/td.ts` (OpenCode TypeScript tool)
**Target**: `.claude/mcp-servers/td/` (MCP Server)
**Date**: 2026-02-23

## Architecture Changes

### OpenCode Tool Pattern

```typescript
// Single tool with action-based dispatch
export default tool({
  description: "Operate TD task workflow...",
  args: {
    action: enum(["status", "start", "focus", ...]),
    task: optional(string),
    files: optional(array(string)),
    // ... other parameters
  },
  async execute(input, context) {
    const action = input.action;
    switch (action) {
      case "status": /* ... */
      case "start": /* ... */
      // ...
    }
  }
})
```

**Usage in OpenCode**:
```
TD(action: "start", task: "td-abc123")
```

### MCP Server Pattern

```typescript
// Multiple tools, one per action
const tools: Tool[] = [
  {
    name: "td_status",
    description: "Get TD status...",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "td_start",
    description: "Start working on a task",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task key/id" }
      },
      required: ["task"]
    }
  },
  // ... 31 more tools
];
```

**Usage in Claude Code**:
```
td_start(task: "td-abc123")
```

## Key Differences

| Aspect | OpenCode | MCP Server |
|--------|----------|------------|
| **Tool Count** | 1 tool with 33 actions | 33 separate tools |
| **Naming** | Single `TD` tool | Tools prefixed with `td_` |
| **Parameters** | `action` + action-specific params | Direct parameters per tool |
| **Discovery** | Single tool, actions in description | Individual tools with descriptions |
| **Type Safety** | All params optional + runtime validation | Schema-enforced per tool |
| **Context** | OpenCode `context` object (worktree) | No context (uses CWD) |

## Tool Mapping

| OpenCode Action | MCP Tool | Notes |
|----------------|----------|-------|
| `action: "status"` | `td_status()` | No parameters |
| `action: "start", task: "x"` | `td_start(task: "x")` | Direct parameter |
| `action: "log", message: "...", logType: "decision"` | `td_log(message: "...", logType: "decision")` | Optional `logType` |
| `action: "ws", wsAction: "start", wsName: "..."` | `td_ws(action: "start", name: "...")` | Nested action preserved |
| `action: "create", task: "title", ...` | `td_create(title: "title", ...)` | `task` → `title` for clarity |
| `action: "epic", task: "title", ...` | `td_epic(title: "title", ...)` | `task` → `title` for clarity |
| `action: "block-issue", task: "x"` | `td_block(task: "x")` | Simplified name |
| `action: "unblock-issue", task: "x"` | `td_unblock(task: "x")` | Simplified name |

## Parameter Mapping

### Special Cases

1. **`task` parameter reuse**
   - OpenCode: Used for both task ID and task title (in `create`/`epic`)
   - MCP: Split to `task` (ID) and `title` (for create/epic)

2. **Work session actions**
   - OpenCode: `wsAction` parameter
   - MCP: `action` parameter (consistent with other tools)

3. **Dependency actions**
   - OpenCode: `depAction` parameter
   - MCP: `action` parameter

4. **File path handling**
   - OpenCode: Converted absolute paths to relative using `context.worktree`
   - MCP: No context object; relies on TD CLI's CWD handling

## Implementation Details

### Command Execution

**OpenCode** (using Bun):
```typescript
const cmd = Bun.$`td ${args}`.nothrow().quiet()
const result = await cmd
```

**MCP** (using Node.js):
```typescript
import { execSync } from "child_process"

const stdout = execSync(`td ${args.join(" ")}`, {
  encoding: "utf-8",
  stdio: ["pipe", "pipe", "pipe"],
})
```

### Error Handling

Both implementations handle errors gracefully:
- Non-zero exit codes return stderr
- Missing TD CLI returns installation instructions
- Invalid parameters return error messages

### Output Format

- OpenCode: Returns stdout string or error message
- MCP: Returns MCP-formatted response with `content` array

## Migration Impact

### For Users

- **Breaking Change**: Tool invocation syntax changes
- **Benefit**: Better discoverability (33 tools vs 1)
- **Benefit**: Better type checking (schema per tool)
- **Benefit**: Claude Code native integration (no custom SDK)

### For Skills

The `td-workflow` skill has been updated to use the new MCP tool syntax:

**Before**:
```
TD(action: "start", task: "td-abc123")
TD(action: "log", message: "...", logType: "decision")
```

**After**:
```
td_start(task: "td-abc123")
td_log(message: "...", logType: "decision")
```

### For Agents

Agent prompts that referenced the OpenCode `TD` tool must be updated to use the new `td_*` tools.

## Benefits of MCP Approach

1. **Better Discoverability**: 33 tools show up in tool listings with individual descriptions
2. **Type Safety**: Schema validation per tool ensures correct parameters
3. **Standard Protocol**: Uses MCP instead of custom OpenCode SDK
4. **Composability**: Can be used alongside other MCP servers
5. **Maintainability**: Each tool has isolated schema and logic
6. **IDE Support**: MCP tools work with standard IDE integrations

## Drawbacks

1. **More Verbose**: 33 tool definitions vs 1 with switch statement
2. **Duplication**: Some shared logic (e.g., error handling) is repeated
3. **Discovery Overhead**: More tools to load and index
4. **Context Loss**: No `context.worktree` for path conversion (relies on TD CLI's CWD)

## Testing

### Manual Testing

1. **Status check**:
   ```
   td_status()
   ```

2. **Task execution**:
   ```
   td_start(task: "td-abc123")
   td_log(message: "Starting implementation", logType: "decision")
   ```

3. **Task creation**:
   ```
   td_create(title: "Test task", type: "task", priority: "P2")
   ```

4. **Work session**:
   ```
   td_ws(action: "start", name: "test-session")
   td_ws(action: "current")
   ```

### Automated Testing

The MCP server can be tested using the MCP SDK test utilities:

```typescript
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
// Test connection, tool listing, tool invocation
```

## Future Enhancements

1. **Path Resolution**: Add worktree/CWD awareness for file operations
2. **Streaming**: Support streaming for long-running commands
3. **Resources**: Expose TD state as MCP resources (not just tools)
4. **Prompts**: Add MCP prompts for common TD workflows
5. **Caching**: Cache TD status to reduce CLI invocations
6. **Validation**: Add input validation beyond schema (e.g., task ID format)

## References

- MCP Specification: https://spec.modelcontextprotocol.io/
- MCP SDK: https://github.com/modelcontextprotocol/sdk
- OpenCode Tools: https://docs.opencode.ai/tools
- TD CLI: https://github.com/MoshPitLabs/td

## License

MIT - Same as parent project
