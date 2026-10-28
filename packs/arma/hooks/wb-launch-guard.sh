#!/usr/bin/env bash
# PreToolUse hook for mcp__enfusion-mcp__wb_*: every wb_* tool except the ones below
# launches Workbench when it is not running, bypassing the wb_launch approval.
# Deny those calls while the Workbench NET API does not answer.
set -euo pipefail

input=$(cat)
command -v jq >/dev/null || exit 0
tool=$(jq -r '.tool_name // empty' <<<"$input")

case "$tool" in
  # Never launch Workbench: probes, offline knowledge, and the headless validator
  # (it starts and exits its own Workbench), plus wb_launch itself (asks for approval).
  mcp__enfusion-mcp__wb_connect|mcp__enfusion-mcp__wb_diagnose|mcp__enfusion-mcp__wb_knowledge|\
  mcp__enfusion-mcp__wb_validate_scripts|mcp__enfusion-mcp__wb_launch|mcp__enfusion-mcp__wb_cli_run|\
  mcp__enfusion-mcp__wb_build_data)
    exit 0 ;;
esac

project_dir=${CLAUDE_PROJECT_DIR:-$(jq -r '.cwd // "."' <<<"$input")}
mcp_json="$project_dir/.mcp.json"

host=""; port=""
if [ -f "$mcp_json" ]; then
  host=$(jq -r '.mcpServers["enfusion-mcp"].env.ENFUSION_WORKBENCH_HOST // empty' "$mcp_json")
  port=$(jq -r '.mcpServers["enfusion-mcp"].env.ENFUSION_WORKBENCH_PORT // empty' "$mcp_json")
fi
port=${port:-5775}
if [ -z "$host" ]; then
  # Same rule as enfusion-mcp: WSL in NAT mode reaches Windows through the default gateway,
  # mirrored mode (and native Linux/Windows) through localhost.
  host=127.0.0.1
  if grep -qi microsoft /proc/version 2>/dev/null; then
    mode=$(wslinfo --networking-mode 2>/dev/null || true)
    if [ "$mode" != "mirrored" ]; then
      gw=$(ip route show default 2>/dev/null | awk '/default/ {print $3; exit}')
      [ -n "$gw" ] && host=$gw
    fi
  fi
fi

if timeout 2 bash -c "exec 3<>/dev/tcp/$host/$port" 2>/dev/null; then
  exit 0
fi

jq -n --arg t "$tool" --arg h "$host:$port" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: ("Workbench does not answer on " + $h + ", and " + $t + " would launch it as a side effect. Use wb_validate_scripts and the file/log tools, skip the reload and smoke run (report them as skipped: Workbench down), or ask the user to start Workbench.")
  }
}'
exit 0
