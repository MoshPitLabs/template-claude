# MCP Servers

This directory contains Model Context Protocol (MCP) servers that provide custom tools to Claude Code.

## What are MCP Servers?

MCP (Model Context Protocol) servers are standalone processes that expose tools, resources, and prompts to Claude Code. They communicate via stdio and allow extending Claude Code's capabilities with custom functionality.

## Available Servers

### TD Server (`./td/`)

Provides full Task-Driven (TD) CLI integration as structured tools.

**Setup:**
```bash
cd td
npm install
npm run build
```

**Configuration** (add to `~/.claude/settings.json`):
```json
{
  "mcpServers": {
    "td": {
      "command": "node",
      "args": ["/absolute/path/to/.claude/mcp-servers/td/dist/index.js"]
    }
  }
}
```

See `td/README.md` for complete documentation.

## Creating New MCP Servers

To add a new MCP server:

1. Create a new directory: `.claude/mcp-servers/your-server/`
2. Implement the MCP server (TypeScript/JavaScript or Python)
3. Use the `@modelcontextprotocol/sdk` package (Node.js) or `mcp` package (Python)
4. Add to Claude Code settings
5. Document in this README

### Example Structure

```
.claude/mcp-servers/
├── README.md           # This file
├── your-server/
│   ├── package.json    # Node.js dependencies
│   ├── tsconfig.json   # TypeScript config
│   ├── src/
│   │   └── index.ts    # Server implementation
│   ├── dist/           # Built output
│   └── README.md       # Server documentation
```

## Resources

- MCP SDK (Node.js): https://github.com/modelcontextprotocol/sdk
- MCP Specification: https://spec.modelcontextprotocol.io/
- Claude Code Documentation: https://docs.anthropic.com/claude-code

## License

MIT - Same as parent project
