#!/usr/bin/env bash
# Stop / SubagentStop hook: refuse to finish while a file a domain names was changed after the
# last call to that domain's verification tool in this transcript.
# Blocks once per stop attempt chain (stop_hook_active), so an agent that cannot run the
# verification (tool unavailable, timeout) can still finish after saying so in its report.
#
# Rules come from .claude/config/verify-gate.<pack>.conf, one per line, tab-separated:
#   <changed-file regex>  <regex of other tools that change such files, or ->  <verifier tool name>  <block message>
set -euo pipefail

input=$(cat)
command -v jq >/dev/null || exit 0

[ "$(jq -r '.stop_hook_active // false' <<<"$input")" = "true" ] && exit 0

# A subagent's own tool calls live in agent_transcript_path; the main session's in transcript_path.
transcript=$(jq -r '.agent_transcript_path // .transcript_path // empty' <<<"$input")
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

project_dir=${CLAUDE_PROJECT_DIR:-$(jq -r '.cwd // "."' <<<"$input")}

for conf in "$project_dir"/.claude/config/verify-gate.*.conf; do
  [ -f "$conf" ] || continue
  while IFS=$'\t' read -r file_re tool_re verifier message; do
    [ -n "$verifier" ] || continue
    [ "$tool_re" = "-" ] && tool_re='^$'
    # Calls whose result is an error (denied by a hook or permission, failed) changed nothing.
    verdict=$(jq -rs --arg file_re "$file_re" --arg tool_re "$tool_re" --arg verifier "$verifier" '
      ([ .[] | select(.type == "user") | .message.content[]? | objects
         | select(.type == "tool_result" and .is_error == true) | .tool_use_id ]) as $failed
      | [ .[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")
          | select(.id as $id | $failed | index($id) | not) ]
      | to_entries
      | (map(select(
            ((.value.name | test("^(Edit|Write|MultiEdit)$")) and ((.value.input.file_path // "") | test($file_re)))
            or (.value.name | test($tool_re))
          )) | last | .key // -1) as $edit
      | (map(select(.value.name == $verifier)) | last | .key // -1) as $verified
      | if $edit > $verified then "block" else "ok" end
    ' "$transcript" 2>/dev/null || echo ok)
    if [ "$verdict" = "block" ]; then
      jq -n --arg r "$message" '{decision: "block", reason: $r}'
      exit 0
    fi
  done < <(grep -vE '^[[:space:]]*(#|$)' "$conf")
done
exit 0
