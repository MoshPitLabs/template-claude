#!/usr/bin/env bash
# Run by sync-claude-config.sh after syncing this pack into a repository: prints follow-up warnings.
# Usage: sync-check.sh <repo-path>
repo=$1
name=$(basename "$repo")
if [[ ! -f "$repo/.claude/local/hytale.toml" ]]; then
  echo "$name has no .claude/local/hytale.toml; record the server pin there (template: .claude/skills/hytale-api-lookups/references/local-hytale-template.toml)"
fi
if [[ ! -f "$repo/scripts/verify.py" ]]; then
  echo "$name has no scripts/verify.py; provide it before claiming a verified implementation"
fi
if [[ -d "$repo/.team" || -f "$repo/.codex/config.toml" ]]; then
  echo "$name still has .team/ or .codex/ from the Codex template; move .team/hytale.toml to .claude/local/hytale.toml and remove the rest by hand once the Claude setup is in use"
fi
