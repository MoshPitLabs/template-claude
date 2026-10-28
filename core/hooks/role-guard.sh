#!/usr/bin/env bash
# PreToolUse hook for Edit|Write|MultiEdit|NotebookEdit|Bash: enforces the edit paths and
# read-only shell of the non-implementing roles. agent_type is set inside a subagent and for
# the main session when it runs as an agent (settings "agent": "team-lead").
# senior-engineer, sdet, distinguished-engineer and plain sessions without an agent are not
# restricted here (their limits are in their agent files).
#
# Domain packs extend the limits in .claude/config/role-guard.<pack>.conf, one entry per line:
#   path <role> <regex prefix of a project-relative path the role may edit>
#   readonly <regex of an extra read-only command, matched at the start of a shell segment>
set -euo pipefail

input=$(cat)
command -v jq >/dev/null || exit 0

agent=$(jq -r '.agent_type // empty' <<<"$input")
tool=$(jq -r '.tool_name // empty' <<<"$input")

case "$agent" in
  team-lead)          paths='' ;;
  staff-engineer)     paths='docs/adr/|docs/tdd/|specs/' ;;
  security-engineer)  paths='docs/adr/|docs/tdd/|specs/' ;;
  ux-designer)        paths='docs/ux/|specs/ux/' ;;
  project-manager)    paths='' ;;
  scout)              paths='' ;;
  *) exit 0 ;;
esac

project_dir=${CLAUDE_PROJECT_DIR:-$(jq -r '.cwd // "."' <<<"$input")}

readonly_cmds='git (status|diff|log|show|branch|rev-parse|ls-files|blame)|ls|cat|head|tail|wc|grep|rg|find|stat|file|pwd|jq'
for conf in "$project_dir"/.claude/config/role-guard.*.conf; do
  [ -f "$conf" ] || continue
  while read -r kind a b; do
    case "$kind" in
      path) [ "$a" = "$agent" ] && paths="${paths:+$paths|}$b" ;;
      readonly) readonly_cmds="$readonly_cmds|$a" ;;
    esac
  done < <(grep -vE '^[[:space:]]*(#|$)' "$conf")
done
allowed_paths="^(${paths:-\$^})"

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

case "$tool" in
  Edit|Write|MultiEdit|NotebookEdit)
    path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")
    rel=${path#"$project_dir"/}
    if [[ "$rel" = /* || "$rel" == *..* ]] || ! [[ "$rel" =~ $allowed_paths ]]; then
      deny "$agent may not edit $path. Project files are changed by senior-engineer through a handoff brief (.claude/rules/team.md)."
    fi
    ;;
  Bash)
    cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
    # Discarding or merging stderr is harmless; drop it before looking for output redirection.
    cmd=$(sed -E 's/[[:space:]]*2>[[:space:]]*\/dev\/null//g; s/[[:space:]]*2>&1//g' <<<"$cmd")
    # No redirection, substitution, or background jobs; every segment must start with a read-only command.
    # $( and backticks run inside double quotes too, so that check sees the original command.
    if [[ "$cmd" =~ (\$\(|\`) ]]; then
      deny "$agent runs read-only shell commands only (no redirection or substitution): $cmd"
    fi
    # Operators inside quoted strings are data: blank '...' and "..." before the remaining checks.
    unquoted=$(sed -E "s/'[^']*'|\"([^\"\\\\]|\\\\.)*\"/\"\"/g" <<<"$cmd")
    # && and || are separators, so a lone & afterwards is a background job.
    unquoted=$(sed -E 's/(\|\||&&)/;/g' <<<"$unquoted")
    if [[ "$unquoted" =~ (\>|\&) ]]; then
      deny "$agent runs read-only shell commands only (no redirection or substitution): $cmd"
    fi
    readonly_re="^($readonly_cmds)( |\$)"
    while IFS= read -r seg; do
      seg=$(sed -E 's/^[[:space:]]+|[[:space:]]+$//g' <<<"$seg")
      [ -z "$seg" ] && continue
      if ! [[ "$seg" =~ $readonly_re ]] || [[ "$seg" =~ (--output|-exec|-delete|git diff.*--ext-diff) ]]; then
        deny "$agent runs read-only shell commands only (git status/diff/log/show, ls, grep, find, and any the domain adds): $seg"
      fi
    done < <(sed -E 's/(;|\|)/\n/g' <<<"$unquoted")
    ;;
esac
exit 0
