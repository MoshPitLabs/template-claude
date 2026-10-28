#!/usr/bin/env bash
# Run by sync-claude-config.sh after syncing this pack into a repository: prints follow-up warnings.
# Usage: sync-check.sh <repo-path>
repo=$1
name=$(basename "$repo")
if [[ ! -f "$repo/.claude/local/linear.md" ]]; then
  echo "$name has no .claude/local/linear.md; team-lead creates it on first Linear use (template: .claude/skills/linear-tracking/references/local-linear-template.md)"
fi
