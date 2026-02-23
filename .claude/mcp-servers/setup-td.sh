#!/usr/bin/env bash

# TD MCP Server Setup Script
# This script installs dependencies, builds the TD MCP server,
# and provides instructions for Claude Code configuration.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TD_DIR="$SCRIPT_DIR/td"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🚀 TD MCP Server Setup"
echo "======================"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js is not installed"
    echo "   Install Node.js from: https://nodejs.org/"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ Error: npm is not installed"
    echo "   Install npm with Node.js from: https://nodejs.org/"
    exit 1
fi

echo "✓ Node.js version: $(node --version)"
echo "✓ npm version: $(npm --version)"
echo ""

# Check if TD CLI is installed
if ! command -v td &> /dev/null; then
    echo "⚠️  Warning: TD CLI is not installed"
    echo "   Install from: https://github.com/MoshPitLabs/td"
    echo "   The MCP server will not work without TD CLI"
    echo ""
else
    echo "✓ TD CLI is installed: $(td version 2>&1 | head -1)"
    echo ""
fi

# Install dependencies
cd "$TD_DIR"
echo "📦 Installing dependencies..."
npm install

# Build the server
echo ""
echo "🔨 Building MCP server..."
npm run build

# Check if build succeeded
if [ ! -f "$TD_DIR/dist/index.js" ]; then
    echo ""
    echo "❌ Build failed: dist/index.js not found"
    exit 1
fi

echo ""
echo "✅ TD MCP Server built successfully!"
echo ""

# Configure global settings
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
BACKUP_SETTINGS="$HOME/.claude/settings.json.backup"

echo "📝 Configuring Claude Code Settings"
echo "===================================="
echo ""

if [ -f "$CLAUDE_SETTINGS" ]; then
    echo "✓ Found existing settings at $CLAUDE_SETTINGS"
    echo "  Creating backup at $BACKUP_SETTINGS"
    cp "$CLAUDE_SETTINGS" "$BACKUP_SETTINGS"

    # Use jq to merge if available, otherwise manual merge
    if command -v jq &> /dev/null; then
        echo "  Merging TD MCP server configuration..."
        jq ". + {mcpServers: (.mcpServers // {} | . + {td: {command: \"node\", args: [\"$TD_DIR/dist/index.js\"]}})}" "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp"
        mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
        echo "  ✓ Configuration updated"
    else
        echo ""
        echo "⚠️  jq not found - manual configuration needed"
        echo ""
        echo "Add this to your mcpServers in $CLAUDE_SETTINGS:"
        echo ""
        echo '"td": {'
        echo '  "command": "node",'
        echo '  "args": ["'"$TD_DIR"'/dist/index.js"]'
        echo '}'
    fi
else
    echo "✓ Creating new settings file at $CLAUDE_SETTINGS"
    mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
    cat > "$CLAUDE_SETTINGS" <<EOF
{
  "mcpServers": {
    "td": {
      "command": "node",
      "args": ["$TD_DIR/dist/index.js"]
    }
  }
}
EOF
    echo "  ✓ Configuration created"
fi

echo ""
echo "⚠️  IMPORTANT: Restart Claude Code to load the MCP server"
echo ""
echo "🧪 Testing"
echo "=========="
echo "Once configured, test the server in Claude Code:"
echo ""
echo "1. Start Claude Code"
echo "2. Ask: 'Use the td_status tool'"
echo "3. Verify TD status is returned"
echo ""
echo "For more information, see: $TD_DIR/README.md"
echo ""
