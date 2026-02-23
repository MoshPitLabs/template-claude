# Claude Code Status Lines

Custom status line implementations for Claude Code that display context window usage and session information.

## Overview

Status lines are Python scripts that receive JSON data via stdin and output formatted ANSI text to be displayed in the Claude Code status bar.

## Available Status Lines

All status lines use the `uv` tool runner for dependency management. Each script has inline dependencies specified using PEP 723 script metadata.

### status_line.py (v1)
**Display**: Basic status line
**Features**: Model name, basic context window info

### status_line_v2.py
**Display**: Enhanced with progress indicators
**Features**:
- Model name with color coding
- Visual progress bar
- Token usage metrics

### status_line_v3.py
**Display**: Compact format with symbols
**Features**:
- Symbolic indicators
- Condensed display
- Session tracking

### status_line_v4.py
**Display**: Detailed metrics view
**Features**:
- Extended token statistics
- Usage percentage
- Time-based indicators

### status_line_v5.py
**Display**: Minimal clean design
**Features**:
- Simple, distraction-free display
- Essential info only
- High readability

### status_line_v6.py ✨ (Active)
**Display**: `[Model] # [###---] | 42.5% used | ~115k left | session_id`
**Features**:
- Visual progress bar with color coding
- Percentage and remaining tokens
- Session ID tracking
- Color-coded usage warnings:
  - 🟢 Green: < 50% used
  - 🟡 Yellow: 50-75% used
  - 🔴 Red: 75-90% used
  - 🔥 Bright Red: > 90% used

### status_line_v7.py
**Display**: Graph-style visualization
**Features**:
- ASCII graph representation
- Historical usage tracking
- Trend indicators

### status_line_v8.py
**Display**: Emoji-rich format
**Features**:
- Emoji indicators for quick scanning
- Fun, expressive design
- Status symbols

### status_line_v9.py
**Display**: Developer-focused layout
**Features**:
- Git branch integration
- Active task display
- Developer metrics

## Configuration

The active status line is configured in `.claude/config.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "uv run $CLAUDE_PROJECT_DIR/.claude/status_lines/status_line_v6.py",
    "padding": 0
  }
}
```

### Switching Status Lines

To switch to a different status line, change the `command` value:

```json
"command": "uv run $CLAUDE_PROJECT_DIR/.claude/status_lines/status_line_v9.py"
```

### Padding

The `padding` value controls left/right padding around the status line:
- `0`: No padding (default)
- `1`: 1 space padding
- `2`: 2 spaces padding, etc.

## Input Data Format

Status line scripts receive JSON via stdin with this structure:

```json
{
  "model": {
    "display_name": "Claude Sonnet 4.5",
    "id": "claude-sonnet-4-5-20250929"
  },
  "session_id": "abc123de",
  "context_window": {
    "used_percentage": 42.5,
    "context_window_size": 200000,
    "tokens_used": 85000,
    "tokens_remaining": 115000
  }
}
```

## Dependencies

All status lines use `uv` for Python script execution with inline dependencies.

**Required**:
- `uv` - Universal Python tool runner (install: `curl -LsSf https://astral.sh/uv/install.sh | sh`)

**Optional**:
- `python-dotenv` - Load environment variables (auto-installed by uv)

## Creating Custom Status Lines

To create a custom status line:

1. Create a new file: `.claude/status_lines/status_line_custom.py`

2. Add the shebang and metadata:
   ```python
   #!/usr/bin/env -S uv run --script
   # /// script
   # requires-python = ">=3.11"
   # dependencies = [
   #     "python-dotenv",
   # ]
   # ///
   ```

3. Implement the status line generator:
   ```python
   import json
   import sys

   def generate_status_line(input_data):
       # Your custom logic here
       model_name = input_data.get("model", {}).get("display_name", "Claude")
       return f"[{model_name}] Your custom format"

   if __name__ == "__main__":
       input_data = json.loads(sys.stdin.read())
       print(generate_status_line(input_data))
   ```

4. Make it executable: `chmod +x .claude/status_lines/status_line_custom.py`

5. Update `.claude/config.json` to use your custom status line

## ANSI Color Codes

Common ANSI codes used in status lines:

```python
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
BLUE = "\033[34m"
MAGENTA = "\033[35m"
BRIGHT_WHITE = "\033[97m"
DIM = "\033[90m"
RESET = "\033[0m"
```

## Testing

Test a status line manually:

```bash
# Create test input
echo '{
  "model": {"display_name": "Claude Sonnet 4.5"},
  "session_id": "test1234",
  "context_window": {
    "used_percentage": 65.5,
    "context_window_size": 200000
  }
}' | uv run ./.claude/status_lines/status_line_v6.py
```

Expected output:
```
[Claude Sonnet 4.5] # [#########------] | 65.5% used | ~69.0k left | test1234
```

## Troubleshooting

### Status line not displaying
- Verify `uv` is installed: `uv --version`
- Check file permissions: `ls -la .claude/status_lines/`
- Test the script manually (see Testing section)

### ANSI colors not showing
- Ensure terminal supports ANSI color codes
- Check `TERM` environment variable: `echo $TERM`
- Try a different terminal emulator

### Python errors
- Verify Python version: `python --version` (requires 3.11+)
- Check uv can find Python: `uv python list`
- Review script syntax and dependencies

## Performance

Status lines are executed on every UI update, so performance matters:
- **Good**: Simple calculations, direct JSON parsing
- **Avoid**: Heavy computation, external API calls, large file I/O

All included status lines are optimized for sub-10ms execution time.

## License

MIT - Same as parent project
