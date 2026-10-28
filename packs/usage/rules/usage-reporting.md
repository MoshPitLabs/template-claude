# Usage reporting rules

Synced from `template-claude` (`packs/usage/`). Adds Claude Code cost, usage and context-window reports; it fills no domain extension point beyond `Workflows`.

## Domain rules

- The report reads every project's transcripts under `~/.claude/projects/` on this machine, not only this repository. Share it only as the user directs.

## Workflows

`/usage-report [--days N] [--project TEXT]` and `/context-report [--session ID]` (any role; `team-lead` runs them in the main session).
