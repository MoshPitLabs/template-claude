#!/usr/bin/env bash
#
# TD Task Enforcer Hook for Claude Code
# Requires active TD task before allowing file edits
# Auto-links modified files to active TD task
#
# Usage: Called by Claude Code hooks on Write/Edit tool execution
# Environment variables:
#   TOOL_NAME - Name of the tool being executed
#   FILE_PATH - File path being modified

set -euo pipefail

WRITE_TOOLS=("Write" "Edit" "write" "edit")
LOG_DIR="${HOME}/.claude/logs/td"
mkdir -p "$LOG_DIR"

log_event() {
  local event="$1"
  shift
  local -a jq_args=(
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    --arg event "$event"
  )
  local filter='{timestamp: $timestamp, event: $event'

  while [[ $# -ge 3 && "$1" == "--arg" ]]; do
    jq_args+=(--arg "$2" "$3")
    filter+=", $2: \$$2"
    shift 3
  done
  filter+='}'

  local entry
  entry=$(jq -n "${jq_args[@]}" "$filter")
  echo "$entry" >> "$LOG_DIR/td_enforcer.jsonl"
}

check_td_installed() {
  if ! command -v td &> /dev/null; then
    log_event "td_not_available"
    return 1
  fi
  return 0
}

get_td_status() {
  if ! check_td_installed; then
    return 1
  fi

  if ! td status --json 2>/dev/null; then
    return 1
  fi

  return 0
}

has_active_task() {
  local status
  if ! status=$(get_td_status); then
    return 1
  fi

  # Check for focus/focused task
  if echo "$status" | jq -e '.focus.key // .focus.id // .focused.issue.key // .focused.issue.id' &>/dev/null; then
    return 0
  fi

  # Check for in_progress tasks
  if echo "$status" | jq -e '(.inProgress // .in_progress) | if type == "array" then length > 0 else false end' &>/dev/null; then
    return 0
  fi

  return 1
}

get_active_task() {
  local status
  if ! status=$(get_td_status); then
    return 1
  fi

  # Try to extract task identifier
  echo "$status" | jq -r '.focus.key // .focus.id // .focused.issue.key // .focused.issue.id // (.inProgress // .in_progress)[0].key // (.inProgress // .in_progress)[0].id // empty' 2>/dev/null
}

should_track_file() {
  local file_path="$1"

  # Track only source code and config files
  local ext="${file_path##*.}"
  local tracked_extensions=(
    "ts" "tsx" "js" "jsx" "go" "py" "java" "kt" "rs" "c" "cpp" "h" "hpp"
    "rb" "php" "swift" "vue" "svelte" "md" "sql" "graphql" "proto"
    "css" "scss" "html" "yaml" "yml" "toml" "json" "sh"
  )

  # Check if extension is tracked
  for tracked_ext in "${tracked_extensions[@]}"; do
    if [[ "$ext" == "$tracked_ext" ]]; then
      # Exclude certain directories
      if [[ "$file_path" =~ (node_modules|dist|build|\.git|target|vendor|\.next|\.nuxt|\.svelte-kit|out|coverage|__pycache__|\.claude/logs) ]]; then
        return 1
      fi
      return 0
    fi
  done

  return 1
}

link_file_to_task() {
  local task="$1"
  local file_path="$2"

  if ! check_td_installed; then
    return 1
  fi

  # Link file to task
  if td link "$task" "$file_path" &>/dev/null; then
    log_event "auto_linked" --arg task "$task" --arg file "$file_path"
  fi

  # Log the edit
  if td log "${TOOL_NAME}: ${file_path}" &>/dev/null; then
    log_event "auto_logged" --arg task "$task" --arg file "$file_path"
  fi
}

# Main enforcement logic
main() {
  local tool_name="${TOOL_NAME:-}"
  local file_path="${FILE_PATH:-}"

  # Only enforce on write operations
  local is_write_tool=false
  for write_tool in "${WRITE_TOOLS[@]}"; do
    if [[ "$tool_name" == "$write_tool" ]]; then
      is_write_tool=true
      break
    fi
  done

  if [[ "$is_write_tool" == "false" ]]; then
    exit 0  # Not a write tool, allow
  fi

  # Check if TD is available and has active task
  if ! check_td_installed; then
    log_event "td_not_available"
    # Don't block if TD is not installed - allow normal operation
    exit 0
  fi

  if ! has_active_task; then
    log_event "edit_blocked_no_task" --arg tool "$tool_name" --arg file "$file_path"
    echo "ERROR: No active TD task. Start one with 'td start <TASK-ID>' before editing files." >&2
    exit 1
  fi

  # Has active task - link file if trackable
  if [[ -n "$file_path" ]] && should_track_file "$file_path"; then
    local task
    if task=$(get_active_task); then
      # Link in background to avoid blocking
      link_file_to_task "$task" "$file_path" &
    fi
  fi

  exit 0
}

# Run main logic
main "$@"
