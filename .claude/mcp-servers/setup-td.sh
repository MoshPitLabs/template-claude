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
echo "📝 Configuration Instructions"
echo "=============================="
echo ""
echo "Add the following to your Claude Code settings file:"
echo ""
echo "Location: ~/.claude/settings.json"
echo ""
echo '{
  "mcpServers": {
    "td": {
      "command": "node",
      "args": ["'"$TD_DIR"'/dist/index.js"]
    }
  }
}'
echo ""
echo "If you already have mcpServers configured, add the 'td' entry to the existing object."
echo ""
echo "After updating settings, restart Claude Code to load the MCP server."
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
