#!/usr/bin/env bash
# Run by sync-claude-config.sh after syncing this pack into a repository: prints follow-up warnings.
# Usage: sync-check.sh <repo-path>
repo=$1
name=$(basename "$repo")
if [[ ! -f "$repo/.claude/local/wow.toml" ]]; then
  echo "$name has no .claude/local/wow.toml; record the flavors, Interface numbers and Blizzard UI source there (template: .claude/skills/wow-api-lookups/references/local-wow-template.toml)"
fi
if ! compgen -G "$repo/*.toc" >/dev/null && ! compgen -G "$repo/*/*.toc" >/dev/null; then
  echo "$name has no .toc file at the top level or one folder down; is it a WoW addon repository?"
fi
if [[ ! -f "$repo/.luacheckrc" ]]; then
  echo "$name has no .luacheckrc; luacheck will flag every WoW API global until one declares std lua51 and the globals the addon reads"
fi
