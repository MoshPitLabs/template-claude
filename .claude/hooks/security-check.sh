#!/usr/bin/env bash
#
# Security Check Hook for Claude Code
# Blocks access to sensitive files and dangerous commands
#
# Usage: This script is called by Claude Code hooks on tool execution
# Environment variables:
#   TOOL_NAME - Name of the tool being executed
#   TOOL_ARGS - JSON string of tool arguments
#   FILE_PATH - File path being accessed (if applicable)

set -euo pipefail

# Secret path patterns
SECRET_PATTERNS=(
  '\.env(\.[^/]*)?$'
  'secrets?(/|$)'
  '\.pem$'
  '\.key$'
  'credentials[^/]*\.json$'
  'id_rsa(\.pub)?$'
  'id_ed25519(\.pub)?$'
  '\.p12$'
  '\.pfx$'
  '\.jks$'
  '\.keystore$'
)

# Allowed env files
ALLOWED_ENV_PATTERNS=(
  '\.env\.example$'
  '\.env\.sample$'
  '\.env\.template$'
)

# Dangerous command patterns
DANGEROUS_PATTERNS=(
  'rm\s+(-[a-z]*r[a-z]*f|-[a-z]*f[a-z]*r)'
  'rm\s+--recursive.*--force'
  'rm\s+--force.*--recursive'
  'rm\s+-rf\s+/'
  'rm\s+-rf\s+\.'
  'rm\s+-rf\s+\*'
)

log_security_block() {
  local reason="$1"
  local details="$2"
  local log_dir="${HOME}/.claude/logs/security"
  mkdir -p "$log_dir"

  local entry
  entry=$(jq -n \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg event "security_block" \
    --arg reason "$reason" \
    --arg details "$details" \
    '{timestamp: $timestamp, event: $event, reason: $reason, details: $details}')

  echo "$entry" >> "$log_dir/security.jsonl"
}

is_secret_path() {
  local path="$1"

  # Check if it's an allowed env file first
  for pattern in "${ALLOWED_ENV_PATTERNS[@]}"; do
    if echo "$path" | grep -qE "$pattern"; then
      return 1  # Not a secret (allowed)
    fi
  done

  # Check against secret patterns
  for pattern in "${SECRET_PATTERNS[@]}"; do
    if echo "$path" | grep -qE "$pattern"; then
      return 0  # Is a secret
    fi
  done

  return 1  # Not a secret
}

is_dangerous_command() {
  local command="$1"

  for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if echo "$command" | grep -qE "$pattern"; then
      return 0  # Is dangerous
    fi
  done

  return 1  # Not dangerous
}

# Main security check logic
main() {
  local tool_name="${TOOL_NAME:-}"
  local file_path="${FILE_PATH:-}"

  # Check Bash commands for dangerous patterns
  if [[ "$tool_name" == "Bash" || "$tool_name" == "bash" ]]; then
    local command="${BASH_COMMAND:-$*}"

    if is_dangerous_command "$command"; then
      log_security_block "dangerous_rm_command" "$command"
      echo "ERROR: Blocked dangerous rm command" >&2
      exit 1
    fi

    # Check if command touches secret files
    if echo "$command" | grep -qE '\b(cat|less|more|head|tail|grep|rg|sed|awk|cp|mv|tee|vi|vim|nano|code)\b'; then
      # Extract file paths from command
      for token in $command; do
        # Remove quotes
        token="${token#\"}"
        token="${token#\'}"
        token="${token%\"}"
        token="${token%\'}"

        if is_secret_path "$token"; then
          log_security_block "bash_secret_file_access" "$command"
          echo "ERROR: Blocked secret file access from bash: $token" >&2
          exit 1
        fi
      done
    fi
  fi

  # Check Read/Write/Edit tools for secret paths
  if [[ "$tool_name" =~ ^(Read|Write|Edit|Glob|Grep)$ ]]; then
    if [[ -n "$file_path" ]] && is_secret_path "$file_path"; then
      log_security_block "secret_file_access" "$tool_name: $file_path"
      echo "ERROR: Blocked access to sensitive file path: $file_path" >&2
      exit 1
    fi
  fi

  # All checks passed
  exit 0
}

# If called with arguments, check them
if [[ $# -gt 0 ]]; then
  main "$@"
else
  main
fi
