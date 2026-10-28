# Usage reporting rules

Synced from `template-claude` (`packs/usage/`). Adds a Claude Code cost and usage report; it fills no domain extension point beyond `Workflows`.

## Domain rules

- The report reads every project's transcripts under `~/.claude/projects/` on this machine, not only this repository. Share it only as the user directs.

## Workflows

`/usage-report [--days N] [--project TEXT]` (any role; `team-lead` runs it in the main session).
