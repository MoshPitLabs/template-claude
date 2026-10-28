#!/usr/bin/env bash
# Run by sync-claude-config.sh after syncing this pack into a repository: prints follow-up warnings.
# Usage: sync-check.sh <repo-path>
repo=$1
name=$(basename "$repo")
if [[ ! -f "$repo/.claude/local/workbench.md" ]]; then
  echo "$name has no .claude/local/workbench.md; it is created on the first test run (template: .claude/skills/arma-workbench-workflow/references/local-workbench-template.md)"
fi
if [[ -d "$repo/.opencode" || -f "$repo/opencode.jsonc" ]]; then
  echo "$name still has .opencode/ or opencode.jsonc; remove them by hand once the Claude setup is in use"
fi
